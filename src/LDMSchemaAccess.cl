;***********************************************************************
; Copyright (C) 1989, G. E. Weddell.
;
; This file is part of RDM.
;
; RDM is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; RDM is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with RDM.  If not, see <http://www.gnu.org/licenses/>.
;
;***********************************************************************

;*************************** SCHEMA ACCESS *****************************

(defvar DefaultQueryFreqEst)
(defvar DefaultTransFreqEst)

;***********************************************************************
; The routines in this file non-destructively access schema information.
;***********************************************************************

 
(defun Valof (Constant) (read-from-string (cadr Constant)))

(defun ClassOf (PName) (PropType PName))

(defun SupClasses (CName) (get CName 'SupClasses))

(defun SupUserClasses (CName) (get CName 'SupUserClasses))

(defun SupClasses* (CName) (get CName 'SupClasses*))

(defun SupClasses+ (CName) (remove CName (SupClasses* CName)))

(defun SubClasses (CName) (get CName 'SubClasses))

(defun SubClasses+ (CName) (get CName 'SubClasses+))

(defun SubClasses* (CName) (cons CName (get CName 'SubClasses+)))

(defun Class? (CName) (get CName 'Class?))

(defun UserClass? (CName) (get CName 'UserClass?))

(defun ClassProps (CName) (get CName 'ClassProps))

(defun ClassUserProps (CName) (get CName 'ClassUserProps))

(defun ClassProps* (CName)
   (prog (PropList)
      (do ((ClassList (SupClasses* CName) (cdr ClassList)))
            ((null ClassList))
         (setq PropList (SetUnion (ClassProps (car ClassList)) PropList)))
      (return PropList)))

(defun ClassConstraints (CName) (get  CName 'ClassConstraints))

(defun ClassCovers (CName)
   (mapcan
      #'(lambda (E)
	 (if (eq (car E) 'Cover) (list (cadr E)) nil))
      (ClassConstraints CName)))

(defun ClassPfds (CName)
   (mapcan
      #'(lambda (E)
	 (if (eq (car E) 'Pfd) (list (cdr E)) nil))
      (ClassConstraints CName)))

(defun ClassMscVal (CName) (get CName 'ClassMscVal))

(defun ClassMscSumVal (CName) (get CName 'ClassMscSumVal))

(defun ClassReference (CName) (get CName 'ClassReference))

(defun ClassExtension (CName) (get CName 'ClassExtension))

(defun ClassIndices (CName) (get CName 'ClassIndices))

(defun ClassDistIndices (CName) (get CName 'ClassDistIndices))

(defun ClassStore (CName) (get CName 'ClassStore))

(defun Prop? (PName) (get PName 'Prop?))

(defun UserProp? (PName) (get PName 'UserProp?))

(defun Updated? (PF)
   (if (null PF) t (if (get (car PF) 'Updated?) (Updated? (cdr PF)) nil)))

(defun PropType (PName) (get PName 'PropType))

(defun PropConstraint (PName) (get PName 'PropConstraint))

(defun Query? (Q) (get Q 'Query?))

(defun QueryBody (Q) (get Q 'QueryBody))

(defun Trans? (S) (get S 'Trans?))

(defun TransBody (S) (get S 'TransBody))

(defun Index? (I) (get I 'Index?)) 

(defun IndexType (I) (get I 'IndexType)) 

(defun IndexSearchConds (I) (get I 'IndexSearchConds)) 

(defun Distributed? (I) (get I 'Distributed?))

(defun DistPF (I) (get I 'DistPF))

(defun StaticIndex? (I) (get I 'StaticIndex?))

(defun IndexSize (I) (get I 'IndexSize))

(defun IndexClass (I) (get I 'IndexClass))

(defun Store? (S) (get S 'StoreDesc))

(defun StoreClasses (S) (get S 'StoreClasses))

(defun StoreType (S) (get S 'StoreType))

(defun StoreSize (S) (get S 'StoreSize))

(defun RCntEst (C)
   (let ((Covers? (ClassCovers C)) (RCnt (get C 'RCntEst)))
      (if Covers?
         0
         (if RCnt RCnt DefaultRCntEst))))

(defun QueryFreqEst (Q)
   (let ((Freq (get Q 'QueryFreqEst)))
      (if (null Freq) DefaultQueryFreqEst Freq)))

(defun TransFreqEst (S)
   (let ((Freq (get S 'TransFreqEst)))
      (if (null Freq) DefaultTransFreqEst Freq)))


;***********************************************************************
; Additional schema access routines for computing various index name
; lists.
;***********************************************************************

(defun SupIndices* (CName)
   (mapcan
      #'(lambda (CName) (copy-tree (ClassIndices CName)))
      (SupClasses* CName)))


;(defun SupIndicesOnP* (CName PName)
;   (mapcan
;      #'(lambda (IName)
;         (if (Match `(* (PFCond (,PName *) ?) *) (IndexSearchConds IName))
;            (list IName)
;            nil))
;      (SupIndices* CName)))


(defun SubSupClasses* (CName &aux CList)
   (setq CList (SupClasses* CName))
   (do ((SubCList (SubClasses+ CName) (cdr SubCList))) ((null SubCList))
      (setq CList (SetUnion CList (SupClasses* (car SubCList)))))
   CList)


(defun SubSupIndices* (CName)
   (mapcan
      #'(lambda (CName) (copy-tree (ClassIndices CName)))
      (SubSupClasses* CName)))


(defun SubSupIndicesOnP* (CName PName)
   (mapcan
      #'(lambda (IName)
         (if (Match `(* (PFCond (,PName *) ?) *) (IndexSearchConds IName))
            (list IName)
            nil))
      (SubSupIndices* CName)))


(defun SupDistIndices* (CName)
   (mapcan
      #'(lambda (CName) (copy-tree (ClassDistIndices CName)))
      (SupClasses* CName)))


(defun SubSupDistIndices* (CName)
   (mapcan
      #'(lambda (CName) (copy-tree (ClassDistIndices CName)))
      (SubSupClasses* CName)))


(defun SubStore* (CName &aux SList)
   (setq SList nil)
   (do ((CList (SubClasses* CName) (cdr CList))) ((null CList))
      (if (not (member (ClassStore (car CList)) SList))
         (setq SList (cons (ClassStore (car CList)) SList))))
   SList)
