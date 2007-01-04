(load-file "./elk-test.el")
(load-file "./bashdb.el")

(defun regexp-test (location-str file-str)
  "Test to see that location-str matches gud-bashdb-marker-regexp"
  (assert-equal 0 (string-match gud-bashdb-marker-regexp location-str))
  (assert-equal file-str
		(substring location-str
			   (match-beginning gud-bashdb-marker-regexp-file-group) 
			   (match-end gud-bashdb-marker-regexp-file-group)))
)
(deftest "bashdb-marker-regexp-test"

  (regexp-test 
   "(e:\\sources\\capfilterscanner\\capanalyzer.sh:3):
"
   "e:\\sources\\capfilterscanner\\capanalyzer.sh"
   )
  (regexp-test 
   "(/etc/init.d/network:39):
"
   "/etc/init.d/network"
   )
)

(build-suite "bashdb-suite" "bashdb-marker-regexp-test")
(run-elk-test "bashdb-marker-regexp-test"
              "test regular expression used in tracking lines")  

