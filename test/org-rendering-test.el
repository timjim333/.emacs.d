;;; org-rendering-test.el --- Item 5 round 2 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-27

;;; Commentary:

;; How Org buffers render: sub/superscripts, hidden emphasis markers,
;; and LaTeX previews.  Needs a GUI frame, so run it with
;; `test/gui-ert test/org-rendering-test.el'.

;;; Code:

(require 'ert)
(require 'org)

(defmacro tim/test-with-org (text &rest body)
  "Show TEXT in a fontified Org buffer in the selected window, run BODY."
  (declare (indent 1))
  `(let ((buffer (generate-new-buffer "*org-test*")))
     (unwind-protect
         (progn
           (switch-to-buffer buffer)
           (insert ,text)
           (org-mode)
           (font-lock-ensure)
           (goto-char (point-min))
           ,@body)
       (kill-buffer buffer))))

(defun tim/test-pos (string &optional offset)
  "Return the position of STRING in the buffer, plus OFFSET."
  (save-excursion
    (goto-char (point-min))
    (+ (search-forward string) (- (length string)) (or offset 0))))

(defun tim/test-raised-p (pos)
  "Non-nil if the character at POS is displayed raised or lowered.
Org sets a list of display specs, such as ((raise -0.3) (height 0.7))."
  (let ((display (get-text-property pos 'display)))
    (and (consp display) (assq 'raise display))))

(defun tim/test-move-to (pos)
  "Move point to POS and run the post-command hooks, as a key press would."
  (goto-char pos)
  (run-hooks 'post-command-hook))

(defun tim/test-latex-overlay ()
  "Return the first LaTeX preview overlay in the buffer, or nil."
  (seq-find (lambda (ov) (eq (overlay-get ov 'org-overlay-type)
                             'org-latex-overlay))
            (overlays-in (point-min) (point-max))))

;; Test 1
(ert-deftest tim/org-subscript-only-with-braces ()
  "x_{i} renders as a subscript; snake_case and ~code_here~ stay plain."
  (tim/test-with-org "x_{i} and snake_case and ~code_here~ and e^{2}\n"
    (should (tim/test-raised-p (tim/test-pos "x_{i}" 3)))
    (should (tim/test-raised-p (tim/test-pos "e^{2}" 3)))
    (should-not (tim/test-raised-p (tim/test-pos "snake_case" 6)))
    (should-not (tim/test-raised-p (tim/test-pos "code_here" 5)))))

;; Test 9
(ert-deftest tim/org-emphasis-markers-appear-inside ()
  "*bold* hides its asterisks until the cursor is inside it."
  (tim/test-with-org "Some *bold* text\n"
    (let ((marker (tim/test-pos "*bold*")))
      (tim/test-move-to (point-max))
      (should (invisible-p marker))
      (tim/test-move-to (tim/test-pos "bold" 2))
      (should-not (invisible-p marker))
      (tim/test-move-to (point-max))
      (should (invisible-p marker)))))

;; Test 2
(ert-deftest tim/org-latex-preview-toggles ()
  "$E=mc^2$ shows a preview outside it and its source inside it.
Opening the file renders it, and no ltximg/ folder lands beside it."
  (let* ((dir (make-temp-file "org-test-" t))
         (file (expand-file-name "note.org" dir)))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert "Intro line\n\nEnergy $E=mc^2$ here\n"))
          (find-file file)
          (should (tim/test-latex-overlay))
          (tim/test-move-to (tim/test-pos "E=mc" 1))
          (should-not (tim/test-latex-overlay))
          (tim/test-move-to (point-min))
          (should (tim/test-latex-overlay))
          (should-not (file-exists-p (expand-file-name "ltximg" dir))))
      (when (get-file-buffer file)
        (kill-buffer (get-file-buffer file)))
      (delete-directory dir t))))

(ert-deftest tim/org-buffer-modes ()
  "Org buffers get the writing modes."
  (tim/test-with-org "* Heading\n"
    (dolist (mode '(org-modern-mode mixed-pitch-mode olivetti-mode
                    visual-wrap-prefix-mode org-appear-mode
                    org-fragtog-mode))
      (should (and (boundp mode) (symbol-value mode))))))

(ert-deftest tim/org-directory-is-notes-folder ()
  "Org looks for notes in ~/org/."
  (should (equal (file-name-as-directory (expand-file-name org-directory))
                 (expand-file-name "~/org/"))))

;;; org-rendering-test.el ends here
