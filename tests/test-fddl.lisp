;;;; -*- Mode: LISP; Syntax: ANSI-Common-Lisp; Base: 10 -*-
;;;; ======================================================================
;;;; File:     test-fddl.lisp
;;;; Authors:  Marcus Pearce <m.t.pearce@city.ac.uk> and Kevin Rosenberg
;;;; Created:  30/03/2004
;;;; Updated:  $Id$
;;;;
;;;; Tests for the CLSQL Functional Data Definition Language
;;;; (FDDL).
;;;;
;;;; This file is part of CLSQL.
;;;;
;;;; CLSQL users are granted the rights to distribute and use this software
;;;; as governed by the terms of the Lisp Lesser GNU Public License
;;;; (http://opensource.franz.com/preamble.html), also known as the LLGPL.
;;;; ======================================================================

(in-package #:clsql-tests)

#.(clsql:locally-enable-sql-reader-syntax)

(setq *rt-fddl*
      '(
	
;; list current tables 
(deftest :fddl/table/1
    (apply #'values 
           (sort (mapcar #'string-downcase
                         (clsql:list-tables :owner *test-database-user*))
                 #'string<))
  "company" "employee" "type_table")

;; create a table, test for its existence, drop it and test again 
(deftest :fddl/table/2
    (progn (clsql:create-table  [foo]
                               '(([id] integer)
                                 ([height] float)
                                 ([name] (string 24))
                                 ([comments] longchar)))
           (values
            (clsql:table-exists-p [foo] :owner *test-database-user*)
            (progn
              (clsql:drop-table [foo] :if-does-not-exist :ignore)
              (clsql:table-exists-p [foo] :owner *test-database-user*))))
  t nil)

;; create a table, list its attributes and drop it 
(deftest :fddl/table/3
    (apply #'values 
           (progn (clsql:create-table  [foo]
                                      '(([id] integer)
                                        ([height] float)
                                        ([name] (char 255))
                                        ([comments] longchar)))
                  (prog1
                      (sort (mapcar #'string-downcase
                                    (clsql:list-attributes [foo]))
                            #'string<)
                    (clsql:drop-table [foo] :if-does-not-exist :ignore))))
  "comments" "height" "id" "name")

(deftest :fddl/attributes/1
    (apply #'values
           (sort 
            (mapcar #'string-downcase
                    (clsql:list-attributes [employee]
                                          :owner *test-database-user*))
            #'string<))
  "birthday" "companyid" "email" "emplid" "first_name" "groupid" "height"
  "last_name" "managerid" "married")

(deftest :fddl/attributes/2
    (apply #'values 
           (sort 
            (mapcar #'(lambda (a) (string-downcase (car a)))
                    (clsql:list-attribute-types [employee]
                                               :owner *test-database-user*))
            #'string<))
  "birthday" "companyid" "email" "emplid" "first_name" "groupid" "height"
  "last_name" "managerid" "married")

;; create a view, test for existence, drop it and test again
(deftest :fddl/view/1
    (progn (clsql:create-view [lenins-group]
			      :as [select [first-name] [last-name] [email]
					  :from [employee]
					  :where [= [managerid] 1]])
	   (values  
	    (clsql:view-exists-p [lenins-group] :owner *test-database-user*)
	    (progn
	      (clsql:drop-view [lenins-group] :if-does-not-exist :ignore)
	      (clsql:view-exists-p [lenins-group] :owner *test-database-user*))))
  t nil)
  
  ;; create a view, list its attributes and drop it 
(when (clsql-base-sys:db-type-has-views? *test-database-underlying-type*)
  (deftest :fddl/view/2
      (progn (clsql:create-view [lenins-group]
				:as [select [first-name] [last-name] [email]
					    :from [employee]
					    :where [= [managerid] 1]])
	     (prog1
		 (sort (mapcar #'string-downcase
			       (clsql:list-attributes [lenins-group]))
		       #'string<)
	       (clsql:drop-view [lenins-group] :if-does-not-exist :ignore)))
    ("email" "first_name" "last_name")))
  
  ;; create a view, select stuff from it and drop it 
(deftest :fddl/view/3
    (progn (clsql:create-view [lenins-group]
			      :as [select [first-name] [last-name] [email]
					  :from [employee]
					  :where [= [managerid] 1]])
	   (let ((result 
		  (list 
		   ;; Shouldn't exist 
		   (clsql:select [first-name] [last-name] [email]
				 :from [lenins-group]
				 :where [= [last-name] "Lenin"])
		   ;; Should exist 
		   (car (clsql:select [first-name] [last-name] [email]
				      :from [lenins-group]
				      :where [= [last-name] "Stalin"])))))
	     (clsql:drop-view [lenins-group] :if-does-not-exist :ignore)
	     (apply #'values result)))
  nil ("Josef" "Stalin" "stalin@soviet.org"))
  
(deftest :fddl/view/4
    (progn (clsql:create-view [lenins-group]
			      :column-list '([forename] [surname] [email])
			      :as [select [first-name] [last-name] [email]
					  :from [employee]
					  :where [= [managerid] 1]])
	   (let ((result 
		  (list
		   ;; Shouldn't exist 
		   (clsql:select [forename] [surname] [email]
				 :from [lenins-group]
				 :where [= [surname] "Lenin"])
		   ;; Should exist 
		   (car (clsql:select [forename] [surname] [email]
				      :from [lenins-group]
				      :where [= [surname] "Stalin"])))))
	     (clsql:drop-view [lenins-group] :if-does-not-exist :ignore)
	     (apply #'values result)))
  nil ("Josef" "Stalin" "stalin@soviet.org"))

;; create an index, test for existence, drop it and test again 
(deftest :fddl/index/1
    (progn (clsql:create-index [bar] :on [employee] :attributes
                              '([first-name] [last-name] [email]) :unique t)
           (values
            (clsql:index-exists-p [bar] :owner *test-database-user*)
            (progn
	      (clsql:drop-index [bar] :on [employee]
				:if-does-not-exist :ignore)
              (clsql:index-exists-p [bar] :owner *test-database-user*))))
  t nil)

;; create indexes with names as strings, symbols and in square brackets 
(deftest :fddl/index/2
    (let ((names '("foo" foo [foo]))
          (result '()))
      (dolist (name names)
        (clsql:create-index name :on [employee] :attributes '([emplid]))
        (push (clsql:index-exists-p name :owner *test-database-user*) result)
	(clsql:drop-index name :on [employee] :if-does-not-exist :ignore))
      (apply #'values result))
  t t t)

;; test list-table-indexes
(deftest :fddl/index/3
    (progn
      (clsql:execute-command "CREATE TABLE I3TEST (a char(10), b integer)")
      (clsql:create-index [bar] :on [i3test] :attributes
			  '([a]) :unique t)
      (clsql:create-index [foo] :on [i3test] :attributes
			  '([b]) :unique nil)
      (values
       
       (sort 
	(mapcar 
	 #'string-downcase
	 (clsql:list-table-indexes [i3test] :owner *test-database-user*))
	    #'string-lessp)
       (sort (clsql:list-table-indexes [company] :owner *test-database-user*)
	     #'string-lessp)
       (progn
	 (clsql:drop-index [bar] :on [i3test])
	 (clsql:drop-index [foo] :on [i3test])
	 (clsql:execute-command "DROP TABLE I3TEST")
	 t)))
  ("bar" "foo") nil t)

;; create an sequence, test for existence, drop it and test again 
(deftest :fddl/sequence/1
    (progn (clsql:create-sequence [foo])
           (values
            (clsql:sequence-exists-p [foo] :owner *test-database-user*)
            (progn
              (clsql:drop-sequence [foo] :if-does-not-exist :ignore)
              (clsql:sequence-exists-p [foo] :owner *test-database-user*))))
  t nil)

;; create and increment a sequence
(deftest :fddl/sequence/2
    (let ((val1 nil))
      (clsql:create-sequence [foo])
      (setf val1 (clsql:sequence-next [foo]))
      (prog1
          (< val1 (clsql:sequence-next [foo]))
        (clsql:drop-sequence [foo] :if-does-not-exist :ignore)))
  t)

;; explicitly set the value of a sequence
(deftest :fddl/sequence/3
    (progn
      (clsql:create-sequence [foo])
      (clsql:set-sequence-position [foo] 5)
      (prog1
          (clsql:sequence-next [foo])
        (clsql:drop-sequence [foo] :if-does-not-exist :ignore)))
  6)

))

#.(clsql:restore-sql-reader-syntax-state)
