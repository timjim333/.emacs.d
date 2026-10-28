;;; org-images-test.el --- Item 5 round 4 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-28

;;; Commentary:

;; Images in notes: where org-download saves them, the links it
;; writes, and HEIC to WebP.  Uses the real Wayland clipboard and
;; ImageMagick.  Run it with `test/gui-ert test/org-images-test.el'.

;;; Code:

(require 'ert)
(require 'org)

(defmacro tim/test-with-notes (bindings &rest body)
  "Run BODY with `org-directory' bound to a fresh temp folder.
BINDINGS names variables bound to files in it, as (VAR RELATIVE-PATH)."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "notes-" t)))
          (org-directory root)
          ,@(mapcar (lambda (b) `(,(car b) (expand-file-name ,(cadr b) root)))
                    bindings))
     (unwind-protect
         (progn ,@body)
       (dolist (buffer (buffer-list))
         (when (string-prefix-p root (or (buffer-file-name buffer) ""))
           (with-current-buffer buffer (set-buffer-modified-p nil))
           (kill-buffer buffer)))
       (delete-directory root t))))

(defun tim/test-open-note (file)
  "Create FILE with one heading, visit it, and put point at the end."
  (make-directory (file-name-directory file) t)
  (with-temp-file file (insert "* Heading\n"))
  (find-file file)
  (goto-char (point-max)))

(defun tim/test-make-image (file)
  "Write a small red image to FILE, in the format its extension names."
  (call-process "magick" nil nil nil "-size" "64x48" "xc:red" file))

(defun tim/test-image-overlay-p ()
  "Non-nil if an inline image is shown in the buffer."
  (seq-find (lambda (ov) (overlay-get ov 'org-image-overlay))
            (overlays-in (point-min) (point-max))))

(ert-deftest tim/org-attachment-dir-mirrors-note-path ()
  "A note's images go in attachments/ under the notes root, by path.
Outside the notes root, they go in attachments/ beside the file."
  (tim/test-with-notes ((note "topics/aviation.org"))
    (tim/test-open-note note)
    (should (equal (file-name-as-directory org-download-image-dir)
                   (expand-file-name "attachments/topics/aviation/" root))))
  (let* ((dir (file-name-as-directory (make-temp-file "elsewhere-" t)))
         (file (expand-file-name "readme.org" dir)))
    (unwind-protect
        (progn
          (tim/test-open-note file)
          (should (equal (file-name-as-directory org-download-image-dir)
                         (expand-file-name "attachments/readme/" dir))))
      (kill-buffer (get-file-buffer file))
      (delete-directory dir t))))

;; Test 3
(ert-deftest tim/org-paste-image-from-clipboard ()
  "Pasting saves the image under attachments/<note>/, links it
relatively, and shows it inline, with no :ID: or #+DOWNLOADED: line."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (call-process "sh" nil nil nil "-c"
                  (format "wl-copy --type image/png < %s"
                          (shell-quote-argument png)))
    (tim/test-open-note note)
    (call-interactively (key-binding (kbd "C-c i")))
    (let ((saved (directory-files
                  (expand-file-name "attachments/topics/aviation" root)
                  nil "\\.png\\'")))
      (should (= (length saved) 1))
      (should (string-search
               (concat "[[file:../attachments/topics/aviation/" (car saved) "]]")
               (buffer-string))))
    (should-not (string-search ":ID:" (buffer-string)))
    (should-not (string-search "#+DOWNLOADED:" (buffer-string)))
    (should (tim/test-image-overlay-p))))

;; Test 4
(ert-deftest tim/org-heic-becomes-webp ()
  "Adding a .heic saves a .webp and links that; the source is kept."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (heic "phone/photo.heic"))
    (make-directory (file-name-directory heic) t)
    (tim/test-make-image heic)
    (tim/test-open-note note)
    (org-download-image heic)
    (let ((dir (expand-file-name "attachments/topics/aviation" root)))
      (should (directory-files dir nil "\\.webp\\'"))
      (should-not (directory-files dir nil "\\.heic\\'")))
    (should (string-match-p "\\[\\[file:[^]]+\\.webp\\]\\]" (buffer-string)))
    (should (file-exists-p heic))))

(ert-deftest tim/org-heic-displays-as-fallback ()
  "A HEIC that slips through still displays, through ImageMagick."
  (let ((heic (make-temp-file "fallback-" nil ".heic")))
    (unwind-protect
        (progn
          (tim/test-make-image heic)
          (should (equal (image-size (create-image heic) t) '(64 . 48))))
      (delete-file heic))))

;;; org-images-test.el ends here
