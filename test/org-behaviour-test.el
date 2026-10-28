;;; org-behaviour-test.el --- Item 5 round 3 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-28

;;; Commentary:

;; How Org behaves: Babel, LOGBOOK, tags, auto-revert, and spelling.
;; Run it with `test/gui-ert test/org-behaviour-test.el', like the
;; rendering tests, so it sees the full config.

;;; Code:

(require 'ert)
(require 'org)

(defmacro tim/test-with-org-text (text &rest body)
  "Run BODY in a temporary Org buffer holding TEXT, point at the start."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,text)
     (org-mode)
     (goto-char (point-min))
     ,@body))

(defun tim/test-run-block (text)
  "Execute the first source block in TEXT and return the buffer text."
  (tim/test-with-org-text text
    (search-forward "#+begin_src")
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-execute-src-block))
    (buffer-string)))

;; Test 5
(ert-deftest tim/org-babel-python ()
  "A Python block prints its output under #+RESULTS:."
  (should (string-match-p
           "#\\+RESULTS:\n: 2"
           (tim/test-run-block
            "#+begin_src python :results output\nprint(1 + 1)\n#+end_src\n"))))

(ert-deftest tim/org-babel-shell ()
  "A shell block prints its output under #+RESULTS:."
  (should (string-match-p
           "#\\+RESULTS:\n: hi"
           (tim/test-run-block "#+begin_src shell\necho hi\n#+end_src\n"))))

;; Test 6
(ert-deftest tim/org-state-change-into-logbook ()
  "A logged state change goes into a :LOGBOOK: drawer.
The file's own #+TODO line asks for the log, because the keyword set
is item 8's to choose."
  (tim/test-with-org-text "#+TODO: TODO(t!) | DONE(d!)\n* TODO Task\n"
    (search-forward "* TODO")
    (org-todo "DONE")
    ;; Org writes the note from `post-command-hook', after the command.
    (run-hooks 'post-command-hook)
    (should (string-match-p
             ":LOGBOOK:\n *- State \"DONE\" +from \"TODO\""
             (buffer-string)))))

;; Tags
(ert-deftest tim/org-tags-from-table ()
  "Every tag in the table is offered, each on its own key."
  (let ((keys (mapcar #'cdr org-tag-persistent-alist)))
    (should (equal (assoc "aviation" org-tag-persistent-alist)
                   '("aviation" . ?a)))
    (should (equal (assoc "@phone" org-tag-persistent-alist)
                   '("@phone" . ?o)))
    (should (= (length org-tag-persistent-alist) 10))
    (should (equal keys (seq-uniq keys)))))

(ert-deftest tim/org-kind-tags-not-inherited ()
  "Kind tags stay on their heading; subject tags pass to children."
  (tim/test-with-org-text "* Parent :paper:travel:\n** Child\n"
    (search-forward "** Child")
    (let ((tags (org-get-tags)))
      (should (member "travel" tags))
      (should-not (member "paper" tags)))))

;; Test 7
(ert-deftest tim/auto-revert-picks-up-appends ()
  "Appending to an open, unmodified file shows up within about 5 s."
  (let* ((dir (make-temp-file "org-test-" t))
         (file (expand-file-name "note.org" dir)))
    (unwind-protect
        (progn
          (with-temp-file file (insert "* first\n"))
          (with-current-buffer (find-file-noselect file)
            (call-process "sh" nil nil nil "-c"
                          (format "echo '* test' >> %s"
                                  (shell-quote-argument file)))
            (let ((deadline (+ (float-time) 6)))
              (while (and (< (float-time) deadline)
                          (not (string-search "* test" (buffer-string))))
                (sit-for 0.2)))
            (should (string-search "* test" (buffer-string)))))
      (when (get-file-buffer file)
        (kill-buffer (get-file-buffer file)))
      (delete-directory dir t))))

;; Test 8
(ert-deftest tim/jinx-british-spelling ()
  "jinx accepts British spelling and flags American."
  (tim/test-with-org-text "colour color\n"
    (jinx-mode 1)
    (should (equal jinx-languages "en_GB"))
    (should (jinx--word-valid-p "colour"))
    (should-not (jinx--word-valid-p "color"))))

;;; org-behaviour-test.el ends here
