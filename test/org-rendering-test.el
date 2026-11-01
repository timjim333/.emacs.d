;;; org-rendering-test.el --- Item 5 round 2 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-11-01

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
Opening the file renders it into the cache, and no ltximg/ folder
lands beside it."
  (let* ((dir (make-temp-file "org-test-" t))
         (file (expand-file-name "note.org" dir)))
    (unwind-protect
        (progn
          (with-temp-file file
            (insert "Intro line\n\nEnergy $E=mc^2$ here\n"))
          (find-file file)
          (should (tim/test-latex-overlay))
          (should (file-in-directory-p
                   (plist-get (cdr (overlay-get (tim/test-latex-overlay)
                                                'display))
                              :file)
                   org-preview-latex-image-directory))
          (tim/test-move-to (tim/test-pos "E=mc" 1))
          (should-not (tim/test-latex-overlay))
          (tim/test-move-to (point-min))
          (should (tim/test-latex-overlay))
          (should-not (file-exists-p (expand-file-name "ltximg" dir))))
      (when (get-file-buffer file)
        (kill-buffer (get-file-buffer file)))
      (delete-directory dir t))))

(defun tim/test-latex-image-file ()
  "Return the image file of the buffer's first LaTeX preview."
  (plist-get (cdr (overlay-get (tim/test-latex-overlay) 'display)) :file))

(ert-deftest tim/org-latex-preview-follows-theme ()
  "Switching theme redraws previews in the new theme's colours.
The colours are part of the image's cache name, so the file changes."
  (let ((theme (car custom-enabled-themes))
        (dir (make-temp-file "org-test-" t)))
    (unwind-protect
        (let ((file (expand-file-name "note.org" dir)))
          (with-temp-file file (insert "Energy $E=mc^2$ here\n"))
          (find-file file)
          (let ((before (tim/test-latex-image-file)))
            (should before)
            (load-theme (if (eq theme 'doom-nord-light) 'doom-nord
                          'doom-nord-light)
                        t)
            (should (tim/test-latex-image-file))
            (should-not (equal (tim/test-latex-image-file) before)))
          (kill-buffer))
      (load-theme theme t)
      (delete-directory dir t))))

(defun tim/test-latex-image-files ()
  "Return the image files of every LaTeX preview in the buffer."
  (save-restriction
    (widen)
    (delq nil (mapcar (lambda (ov)
                        (and (eq (overlay-get ov 'org-overlay-type)
                                 'org-latex-overlay)
                             (plist-get (cdr (overlay-get ov 'display)) :file)))
                      (overlays-in (point-min) (point-max))))))

(ert-deftest tim/org-latex-preview-follows-theme-when-narrowed ()
  "A theme switch redraws previews outside the narrowed region too."
  (let ((theme (car custom-enabled-themes))
        (dir (make-temp-file "org-test-" t)))
    (unwind-protect
        (let ((file (expand-file-name "note.org" dir)))
          (with-temp-file file (insert "One $E=mc^2$\n\nTwo $a^2+b^2$\n"))
          (find-file file)
          (let ((before (tim/test-latex-image-files)))
            (should (= (length before) 2))
            (narrow-to-region (point-min) (line-end-position))
            (load-theme (if (eq theme 'doom-nord-light) 'doom-nord
                          'doom-nord-light)
                        t)
            (widen)
            (let ((after (tim/test-latex-image-files)))
              (should (= (length after) 2))
              (should-not (seq-intersection after before))))
          (kill-buffer))
      (load-theme theme t)
      (delete-directory dir t))))

(ert-deftest tim/org-preview-size-follows-text ()
  "Previews use the text's 96 dpi, not the monitor's, at scale 1.2.
Fails if Org renames the internal function the pin overrides."
  (should (= (org--get-display-dpi) 96))
  (should (= (plist-get org-format-latex-options :scale) 1.2)))

(ert-deftest tim/org-buffer-modes ()
  "Org buffers get the writing modes."
  (tim/test-with-org "* Heading\n"
    (dolist (mode '(org-modern-mode mixed-pitch-mode olivetti-mode
                    visual-wrap-prefix-mode org-appear-mode
                    org-fragtog-mode))
      (should (and (boundp mode) (symbol-value mode))))))

(ert-deftest tim/olivetti-toggle-key ()
  "C-c o turns olivetti off and on in an Org buffer."
  (tim/test-with-org "* Heading\n"
    (should (eq (key-binding (kbd "C-c o")) 'olivetti-mode))
    (call-interactively (key-binding (kbd "C-c o")))
    (should-not olivetti-mode)
    (call-interactively (key-binding (kbd "C-c o")))
    (should olivetti-mode)))

(ert-deftest tim/org-download-handles-drops-from-start ()
  "Opening an Org file is enough for a dropped file to reach the
config's handler, ahead of Org's own drop handler.  This file doesn't load
org-download itself, so the config must."
  (tim/test-with-org "* Heading\n"
    (dolist (uri '("file:///tmp/x.png" "file:/tmp/x.png"))
      (should (eq (cdr (seq-find (lambda (entry)
                                   (string-match-p (car entry) uri))
                                 dnd-protocol-alist))
                  'tim/org-download-dnd)))))

(ert-deftest tim/org-directory-is-notes-folder ()
  "Org looks for notes in ~/org/."
  (should (equal (file-name-as-directory (expand-file-name org-directory))
                 (expand-file-name "~/org/"))))

;;; org-rendering-test.el ends here
