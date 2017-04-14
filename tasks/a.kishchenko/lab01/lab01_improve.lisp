;;;;
;;;; lab 01 for Advanced Algo course
;;;; second iteration -- more efficient algo
;;;; made by Andrew Kishchenko
;;;;

(defconstant +dfile+ "lab01_dict")

(defconstant +maxwordlen+ 24)

;;; key -> word, value -> freq
(defparameter *ngram* (make-hash-table :size 1000000 :test 'equal))
;;; key -> word word, value -> freq
(defparameter *ngram2* (make-hash-table :size 1000000 :test 'equal))
;;; our broken text without whitespaces (getting from STDIN)
(defparameter *text* nil)
;;; tree path
(defparameter *tree* (make-hash-table))

;;; Debug snippets
(defun pr (a) (format t "~a~%" a))
(defun pr2 (a b) (format t "~a~a~%" a b))
(defun prt (a) (format t "type is ~a, value is ~a~%" (type-of a) a))

;;; check if first char A or a
(defun is-char-valid (word)
  (cond ((char-equal (char word 0) #\a) t)
        ((char-equal (char word 0) #\A) t)
        ((char-equal (char word 0) #\I) t)))

;;; add parsed ngram to hashtable
(defun add-ngram (word freq ht del)
  (when del
    (setf freq (floor freq 100000))) 
  (cond ((> (length word) 1) (setf (gethash word ht) freq))
        ((and (= (length word) 1) (is-char-valid word)) (setf (gethash word ht) freq))))

;;; parse ngram, format: word[tab]frequency
(defun parse-ngram (line ht del)
  (dotimes (i (length line))
    (when (char-equal (char line i) #\Tab)
      (add-ngram (subseq line 0 i)(parse-integer (subseq line i (length line))) ht del))))

;;; read file with ngrams
(defun fill-ngram(fname ht del)
  (let ((in (open fname :if-does-not-exist nil)))
    (when in
      (loop for line = (read-line in nil)
            while line do (parse-ngram line ht del)))
    (close in))
  (pr " read -> parse finish"))

;;;
;;; Hashtable helpers
;;;
(defun print-dict-kvp (key value)
  (format t "~a -> ~a~%" key value))

(defun print-ht-debug(ht)
  (with-hash-table-iterator (i ht)
    (loop (multiple-value-bind (entry-p key value) (i)
        (if entry-p
            (print-dict-kvp key value)
          (return))))))

;;; read text from stdin
;;; assume than in input "ourtextwithoutspaces" and double quotes surrounding
(defun read-text ()
  (setf *text* (read)))

(defun parse-text()
  (get-words *tree* *text* 0 nil 1 0 0)
  (get-all-path *tree* 0 0 (make-array 32767))
  (print-fixed-text 0 0 *text* *path* *depth*))

(defun freqp (seq)
  (let ((freq (gethash (string-downcase seq) *ngram*)))
    (if (not freq) 0 freq)))

(defun concat2 (seq prevSeq)
  (concatenate 'string prevSeq " " seq))

(defun freqp2 (seq prevSeq)
  (let ((freq (gethash (concat2 seq prevSeq) *ngram2*)))
    (if (not freq) 1 freq)))

(defun wordp (seq prevSeq)
  (if (> (freqp seq) 0) t nil))

(defun valid-len (txt i)
  (if (< i (length txt)) t nil))

(defun max-bounds (st txt)
  (min (length txt) (+ st +maxwordlen+)))

(defun get-words (ht txt start prevSeq memcost wordcost depth)
  (let ((st (+ start 1)))
    (when (valid-len txt start)
      (let ((end (max-bounds st txt)))
        (loop for i from st to end
              do (collect-word ht prevSeq (subseq txt start i) i txt memcost wordcost depth))))))

(defun collect-word (ht prevSeq seq index txt memcost wordcost depth)
  (let ((cost (freqp2 seq prevSeq)))
    (when (wordp seq prevSeq)
      (setf wordcost (+ wordcost (freqp seq)))
      (setf memcost (+ memcost cost))
      (when (and ( > depth 12) (< memcost 10000))
        ;; (format t "bad path d = ~a mem = ~a~%" depth memcost)
        (return-from collect-word))
      (when (and (= cost 1) (> memcost 10000))
        (setf memcost (floor memcost 10)))
      ;; (format t "~a ~a -> cost: ~a memcost: ~a wordcost: ~a ~%" prevSeq seq cost memcost wordcost)

      (setf (gethash index ht) (cons (+ memcost wordcost) (make-hash-table)))
      (get-words (cdr (gethash index ht)) txt index seq memcost wordcost (+ depth 1))))
    )

(defun get-prev-cost (arr n)
  (if (> n 0) (cdr (aref arr (- n 1))) 0))

;;; print fixed text
;;; array - (cons index . cost)
(defun print-fixed-text (pos spacepos text arr n)
  (when (< pos (length text))
    (when (eql pos (car (aref arr spacepos)))
      (format t " ")
      (when (< spacepos n)
        (setf spacepos (+ 1 spacepos))))
    (format t "~a" (char text pos))
    (print-fixed-text (+ pos 1) spacepos text arr n)))

;;; TODO: refactoring
(defparameter *path* (make-array 32767))
(defparameter *bestcost* 0)
(defparameter *depth* 0)
(defun check-path (arr d)
  (let ((cost (get-prev-cost arr d)))
    (when (> cost *bestcost*)
      (setf *bestcost* cost)
      (setf *depth* d)
      (copy-path arr d))))

(defun copy-path (arr d)
  (dotimes (i d)
    (setf (aref *path* i) (aref arr i))))

;;; array - (cons index . cost)
(defun get-all-path(ht key d arr)
  (if (> (hash-table-count ht) 0)
    (with-hash-table-iterator (iter ht)
      (loop (multiple-value-bind (entry-p key value) (iter)
        (if entry-p
          (progn (setf (aref arr d) (cons key (car (gethash key ht)))) (get-all-path (cdr (gethash key ht)) key (+ d 1) arr))
          (return)))))
    (check-path arr d)))

;;;
;;; Asserts
;;;
(defun assert-ngram()
  (pr2 "hash b = " (gethash "b" *ngram*))
  (pr2 "hash A = " (gethash "b" *ngram*))
  (pr2 "hash Hello = " (gethash (string-downcase "Hello") *ngram*))
  (pr2 "hash hello = " (gethash "hello" *ngram*))
  (pr2 "hash a = " (gethash "a" *ngram*)))

(defun assert-cost()
  (pr2 "cost hello world = " (freqp2 "world" "hello"))
  (pr2 "cost low or = " (freqp2 "or" "low"))
  (pr2 "cost with a = " (freqp2 "a" "with"))
  (pr2 "cost super inefficient = " (freqp2 "inefficient" "super"))
  (pr2 "cost 2nd century = " (freqp2 "century" "2nd")))

(defun all-asserts()
  (assert-ngram)
  (assert-cost))

;;;
;;; main
;;;
(defun my-main()
  (fill-ngram "count_1w.txt" *ngram* t)
  (fill-ngram "count_2w.txt" *ngram2* nil)
  ;; (all-asserts)
  (read-text)
  (parse-text))


(my-main)


