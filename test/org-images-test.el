;;; org-images-test.el --- Item 5 round 4 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-11-01

;;; Commentary:

;; Images in notes: where org-download saves them, the links it
;; writes, refusing a buffer with no file, and HEIC to WebP.  Uses the real Wayland clipboard and
;; ImageMagick.  Run it with `test/gui-ert test/org-images-test.el'.

;;; Code:

(require 'ert)
(require 'org)
(require 'org-download)
(require 'cl-lib)

(defmacro tim/test-with-notes (bindings &rest body)
  "Run BODY with `org-directory' bound to a fresh temp folder.
BINDINGS names variables bound to files in it, as (VAR RELATIVE-PATH).
Screenshots go in the folder too, so parallel runs don't share them."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "notes-" t)))
          (org-directory root)
          (org-download-screenshot-file
           (expand-file-name "screenshot.png" root))
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

(defmacro tim/test-keeping-clipboard (&rest body)
  "Run BODY, then put back what the Wayland clipboard held before.
Only the first type it offers is kept, which covers text and images."
  (declare (indent 0))
  `(let ((type (car (ignore-errors
                      (process-lines "wl-paste" "--list-types"))))
         (saved (make-temp-file "clipboard-")))
     (when type
       (call-process "wl-paste" nil (list :file saved) nil
                     "--no-newline" "--type" type))
     (unwind-protect
         (progn ,@body)
       (if type
           (call-process "wl-copy" saved nil nil "--type" type)
         (call-process "wl-copy" nil nil nil "--clear"))
       (delete-file saved))))

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
  (tim/test-keeping-clipboard
    (tim/test-with-notes ((note "topics/aviation.org")
                          (png "clip.png"))
      (tim/test-make-image png)
      (call-process "wl-copy" png nil nil "--type" "image/png")
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
      (should (tim/test-image-overlay-p)))))

(defun tim/test-open-draft ()
  "Show a new Org buffer with no file and one heading; return it."
  (switch-to-buffer (generate-new-buffer "draft"))
  (insert "* Heading\n")
  (org-mode)
  (current-buffer))

(ert-deftest tim/org-buffer-without-file-refuses-images ()
  "A buffer with no file can't add an image, by any way in, and says
why; nothing is written."
  (tim/test-with-notes ((png "clip.png"))
    (tim/test-make-image png)
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (let ((text (buffer-string)))
            (should-error (org-download-image png) :type 'user-error)
            (cl-letf (((symbol-function 'shell-command)
                       (lambda (&rest _) (error "Took a screenshot"))))
              (should-error (org-download-screenshot) :type 'user-error))
            (should (equal (buffer-string) text))
            (should (equal (directory-files root nil
                                            directory-files-no-dot-files-regexp)
                           '("clip.png"))))
        (set-buffer-modified-p nil)
        (kill-buffer)))))

(ert-deftest tim/org-write-file-moves-attachment-dir ()
  "After C-x C-w to a new name, new images go to the new note's folder."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (copy "topics/gliding.org"))
    (tim/test-open-note note)
    (write-file copy)
    (should (equal (file-name-as-directory org-download-image-dir)
                   (expand-file-name "attachments/topics/gliding/" root)))))

(ert-deftest tim/org-indirect-buffer-uses-base-folder ()
  "An indirect buffer (as Org capture makes) uses its base file's
folder."
  (tim/test-with-notes ((note "inbox.org"))
    (tim/test-open-note note)
    (let ((indirect (make-indirect-buffer (current-buffer) "indirect" t)))
      (unwind-protect
          (with-current-buffer indirect
            (org-mode)
            (should (equal (file-name-as-directory org-download-image-dir)
                           (expand-file-name "attachments/inbox/" root))))
        (kill-buffer indirect)))))

(defmacro tim/test-with-symlinked-notes (&rest body)
  "Run BODY with `org-directory' a symlink `link' to a folder `real'.
`png' is an image file outside both."
  (declare (indent 0))
  `(let* ((base (make-temp-file "symlinked-" t))
          (real (expand-file-name "real-org" base))
          (link (expand-file-name "org" base))
          (png (expand-file-name "clip.png" base))
          (org-directory link))
     (make-directory (expand-file-name "topics" real) t)
     (make-symbolic-link real link)
     (tim/test-make-image png)
     (unwind-protect
         (progn ,@body)
       (dolist (buffer (buffer-list))
         (when (string-prefix-p base (or (buffer-file-name buffer) ""))
           (with-current-buffer buffer (set-buffer-modified-p nil))
           (kill-buffer buffer)))
       (delete-directory base t))))

(ert-deftest tim/org-link-through-symlink-stays-in-notes ()
  "A note visited through a symlinked notes root links its images
relative to the note as visited, not through the real folder."
  (tim/test-with-symlinked-notes
    (tim/test-open-note (expand-file-name "topics/aviation.org" link))
    (org-download-image png)
    (should (string-match-p
             "\\[\\[file:\\.\\./attachments/topics/aviation/[^]/]+\\.png\\]\\]"
             (buffer-string)))))

(ert-deftest tim/org-new-note-links-images-at-once ()
  "A note opened with C-x C-f but not yet on disk adds images straight
to its own folder, with the relative link it keeps when saved."
  (tim/test-with-notes ((note "topics/new.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory note) t)
    (find-file note)
    (should (equal (file-name-as-directory org-download-image-dir)
                   (expand-file-name "attachments/topics/new/" root)))
    (org-download-image png)
    (let ((re "\\[\\[file:\\.\\./attachments/topics/new/\\([^]/]+\\.png\\)\\]\\]"))
      (should (string-match re (buffer-string)))
      (should (file-exists-p
               (expand-file-name (concat "attachments/topics/new/"
                                         (match-string 1 (buffer-string)))
                                 root)))
      (save-buffer)
      (should (string-match-p re (with-temp-buffer
                                   (insert-file-contents note)
                                   (buffer-string)))))))

(ert-deftest tim/org-new-note-before-notes-root-exists ()
  "A new note saved before the notes root exists still puts its images
in attachments/ under the root, not beside the note."
  (tim/test-with-notes ((note "org/topics/new.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (let ((org-directory (expand-file-name "org/" root)))
      (find-file note)
      (org-download-image png)
      (cl-letf (((symbol-function 'y-or-n-p) (lambda (&rest _) t)))
        (save-buffer))
      (should (string-match-p
               "\\[\\[file:\\.\\./attachments/topics/new/[^]/]+\\.png\\]\\]"
               (buffer-string)))
      (should (file-directory-p
               (expand-file-name "org/attachments/topics/new" root))))))

(defun tim/test-indirect-view (base)
  "Open a C-c C-x b view of BASE's first heading and return it."
  (with-current-buffer base
    (goto-char (point-min))
    (org-tree-to-indirect-buffer))
  (seq-find (lambda (b) (eq (buffer-base-buffer b) base)) (buffer-list)))

(ert-deftest tim/org-indirect-view-follows-write-file ()
  "An image added in a view kept open across C-x C-w of its note into
another folder goes to the new name's folder, linked from there."
  (tim/test-with-notes ((note "topics/a.org")
                        (copy "other/b.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory copy) t)
    (tim/test-open-note note)
    (let* ((base (current-buffer))
           (view (tim/test-indirect-view base)))
      (with-current-buffer base (write-file copy))
      (with-current-buffer view
        (goto-char (point-max))
        (org-download-image png))
      (with-current-buffer base
        (should (string-match-p
                 "\\[\\[file:\\.\\./attachments/other/b/[^]/]+\\.png\\]\\]"
                 (buffer-string)))))))

(ert-deftest tim/org-paste-without-image-says-so ()
  "With no image on the clipboard, C-c i says so and links nothing."
  (tim/test-keeping-clipboard
    (call-process "wl-copy" nil nil nil "not an image")
    (tim/test-with-notes ((note "topics/aviation.org"))
      (tim/test-open-note note)
      (should-error (call-interactively (key-binding (kbd "C-c i")))
                    :type 'user-error)
      (should-not (string-search "[[file:" (buffer-string)))
      (should-not (file-exists-p (expand-file-name "attachments" root)))
      (should-not (file-exists-p org-download-screenshot-file)))))

(ert-deftest tim/test-clipboard-restored ()
  "The tests above leave the clipboard as they found it."
  (tim/test-keeping-clipboard
    (call-process "wl-copy" nil nil nil "keep me")
    (tim/test-keeping-clipboard
      (call-process "wl-copy" nil nil nil "scratch"))
    (should (equal (car (process-lines "wl-paste" "--no-newline"))
                   "keep me"))))

(ert-deftest tim/org-attachment-dir-through-symlink ()
  "A note visited by its real path, under a symlinked notes root,
still gets attachments/<note>/ in that root."
  (let* ((base (make-temp-file "symlinked-" t))
         (real (expand-file-name "real-org" base))
         (link (expand-file-name "org" base))
         (note (expand-file-name "a.org" real))
         (org-directory link))
    (make-directory real)
    (make-symbolic-link real link)
    (unwind-protect
        (progn
          (tim/test-open-note note)
          (should (equal (file-truename (tim/org-attachment-dir))
                         (file-truename
                          (expand-file-name "attachments/a/" link)))))
      (when (get-file-buffer note)
        (kill-buffer (get-file-buffer note)))
      (delete-directory base t))))

(ert-deftest tim/org-download-notes-web-source-only ()
  "Web images get a #+DOWNLOADED: line naming their URL; local files
don't, since their name already carries the time."
  (require 'org-download)
  (should (string-prefix-p "#+DOWNLOADED: https://example.com/fig3.png @ "
                           (funcall org-download-annotate-function
                                    "https://example.com/fig3.png")))
  (should (equal (funcall org-download-annotate-function
                          "/tmp/phone/photo.webp")
                 "")))

(defun tim/test-exif (file)
  "Return FILE's GPS latitude and original date, as ImageMagick reads them."
  (car (process-lines "magick" "identify" "-format"
                      "%[EXIF:GPSLatitude] | %[EXIF:DateTimeOriginal]" file)))

;; Test 4
(ert-deftest tim/org-heic-becomes-webp ()
  "Adding a .heic saves a .webp and links that; the source is kept,
and the photo's metadata (GPS, date taken) carries over."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (jpg "phone/photo.jpg")
                        (heic "phone/photo.heic"))
    (make-directory (file-name-directory heic) t)
    (tim/test-make-image jpg)
    (call-process "exiv2" nil nil nil
                  "-M" "set Exif.GPSInfo.GPSLatitude 51/1 30/1 0/1"
                  "-M" "set Exif.Photo.DateTimeOriginal 2026:10:01 12:00:00"
                  jpg)
    (call-process "magick" nil nil nil jpg heic)
    (tim/test-open-note note)
    (org-download-image heic)
    (let* ((dir (expand-file-name "attachments/topics/aviation" root))
           (webp (car (directory-files dir t "\\.webp\\'"))))
      (should webp)
      (should-not (directory-files dir nil "\\.heic\\'"))
      (should (equal (tim/test-exif webp)
                     "51/1,30/1,0/1 | 2026:10:01 12:00:00")))
    (should (string-match-p "\\[\\[file:[^]]+\\.webp\\]\\]" (buffer-string)))
    (should (file-exists-p heic))))

(defmacro tim/test-adding-heic (heic &rest body)
  "Open a note, make the image file HEIC (relative to the notes root),
and run BODY with `dir' bound to the note's attachment folder."
  (declare (indent 1))
  `(tim/test-with-notes ((note "topics/aviation.org")
                         (heic ,heic))
     (make-directory (file-name-directory heic) t)
     (tim/test-make-image heic)
     (tim/test-open-note note)
     (let ((dir (expand-file-name "attachments/topics/aviation" root)))
       ,@body)))

(defun tim/test-linked-webp-p (dir)
  "Non-nil if DIR holds a .webp and the buffer links a .webp."
  (and (directory-files dir nil "\\.webp\\'")
       (string-match-p "\\[\\[file:[^]]+\\.webp\\]\\]" (buffer-string))))

(ert-deftest tim/org-heic-from-file-url ()
  "A file:// link with an escaped space is converted too."
  (tim/test-adding-heic "phone/my photo.heic"
    (org-download-image
     (concat "file://" (string-replace " " "%20" heic)))
    (should (tim/test-linked-webp-p dir))))

(ert-deftest tim/org-heic-uppercase-extension ()
  "A .HEIC, as some phones name them, is converted too."
  (tim/test-adding-heic "phone/IMG_0001.HEIC"
    (org-download-image heic)
    (should (tim/test-linked-webp-p dir))))

(ert-deftest tim/org-heic-conversion-failure ()
  "If ImageMagick can't convert the HEIC, it says so and links nothing."
  (tim/test-adding-heic "phone/broken.heic"
    (with-temp-file heic (insert "not an image"))
    (should-error (org-download-image heic) :type 'user-error)
    (should-not (file-exists-p dir))
    (should-not (string-search "[[file:" (buffer-string)))
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
