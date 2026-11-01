;;; org-images-test.el --- Item 5 round 4 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-11-01

;;; Commentary:

;; Images in notes: where org-download saves them, the links it
;; writes, and HEIC to WebP.  Uses the real Wayland clipboard and
;; ImageMagick.  Run it with `test/gui-ert test/org-images-test.el'.

;;; Code:

(require 'ert)
(require 'org)
(require 'org-download)
(require 'cl-lib)

(defmacro tim/test-with-notes (bindings &rest body)
  "Run BODY with `org-directory' bound to a fresh temp folder.
BINDINGS names variables bound to files in it, as (VAR RELATIVE-PATH).
Screenshots and staged images go in the folder too, so parallel runs
don't share them."
  (declare (indent 1))
  `(let* ((root (file-name-as-directory (make-temp-file "notes-" t)))
          (org-directory root)
          (org-download-screenshot-file
           (expand-file-name "screenshot.png" root))
          (tim/org-staging-directory (expand-file-name "staging/" root))
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

(defun tim/test-staged-files ()
  "Return the files staged for the current buffer."
  (directory-files org-download-image-dir t
                   directory-files-no-dot-files-regexp))

(ert-deftest tim/org-unsaved-buffer-stages-images ()
  "In a buffer with no file, an image is staged and linked absolutely,
so the link still finds it if the buffer's folder changes."
  (tim/test-with-notes ((png "clip.png"))
    (tim/test-make-image png)
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (progn
            (should (string-prefix-p tim/org-staging-directory
                                     org-download-image-dir))
            (org-download-image png)
            (let ((staged (tim/test-staged-files)))
              (should (= (length staged) 1))
              (should (string-search (concat "[[file:" (car staged) "]]")
                                     (buffer-string)))))
        (set-buffer-modified-p nil)
        (kill-buffer)))))

(ert-deftest tim/org-first-save-refiles-staged-images ()
  "The first save moves staged images to the note's attachment folder
and rewrites their links, before the file is written."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory note) t)
    (with-current-buffer (tim/test-open-draft)
      (org-download-image png)
      (let ((staging org-download-image-dir)
            (name (file-name-nondirectory (car (tim/test-staged-files)))))
        (cl-letf (((symbol-function 'read-file-name)
                   (lambda (&rest _) note)))
          (save-buffer))
        (let ((link (concat "[[file:../attachments/topics/aviation/" name "]]")))
          (should (file-exists-p
                   (expand-file-name (concat "attachments/topics/aviation/" name)
                                     root)))
          (should-not (file-exists-p staging))
          (should (string-search link (buffer-string)))
          (should (string-search link (with-temp-buffer
                                        (insert-file-contents note)
                                        (buffer-string))))
          (should (equal (file-name-as-directory org-download-image-dir)
                         (expand-file-name "attachments/topics/aviation/"
                                           root))))))))

(ert-deftest tim/org-refile-refuses-to-overwrite ()
  "If the note's folder already has a file of that name, the save stops
and the staged image stays where it is."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory note) t)
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (progn
            (org-download-image png)
            (let* ((staged (car (tim/test-staged-files)))
                   (dir (expand-file-name "attachments/topics/aviation/" root)))
              (make-directory dir t)
              (with-temp-file (expand-file-name
                               (file-name-nondirectory staged) dir)
                (insert "already here"))
              (should-error (write-file note) :type 'user-error)
              (should (file-exists-p staged))
              (should-not (file-exists-p note))))
        (set-buffer-modified-p nil)
        (kill-buffer)))))

(ert-deftest tim/org-killing-unsaved-buffer-discards-staged-images ()
  "Killing a buffer that was never saved deletes its staged images,
as its text, which links them, is discarded too."
  (tim/test-with-notes ((png "clip.png"))
    (tim/test-make-image png)
    (with-current-buffer (tim/test-open-draft)
      (org-download-image png)
      (let ((staging org-download-image-dir))
        (should (file-exists-p staging))
        (set-buffer-modified-p nil)
        (kill-buffer)
        (should-not (file-exists-p staging))))))

(ert-deftest tim/org-quitting-discards-staged-images ()
  "Quitting Emacs deletes the staged images of buffers never saved."
  (should (memq 'tim/org-discard-all-staged-images kill-emacs-hook))
  (tim/test-with-notes ((png "clip.png"))
    (tim/test-make-image png)
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (progn
            (org-download-image png)
            (let ((staging org-download-image-dir))
              (tim/org-discard-all-staged-images)
              (should-not (file-exists-p staging))))
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
folder, so its images aren't staged."
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
          (org-directory link)
          (tim/org-staging-directory (expand-file-name "staging/" base)))
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

(ert-deftest tim/org-refile-through-symlink-stays-in-notes ()
  "A draft first saved through a symlinked notes root gets the same
relative links as a note visited there."
  (tim/test-with-symlinked-notes
    (with-current-buffer (tim/test-open-draft)
      (org-download-image png)
      (write-file (expand-file-name "topics/draft.org" link))
      (should (string-match-p
               "\\[\\[file:\\.\\./attachments/topics/draft/[^]/]+\\.png\\]\\]"
               (buffer-string))))))

(ert-deftest tim/org-indirect-buffer-on-draft-stages-absolutely ()
  "An indirect buffer made without cloning, on a draft, stages images
with absolute links, so the draft's first save refiles them."
  (tim/test-with-notes ((note "draft.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (let* ((draft (tim/test-open-draft))
           (indirect (make-indirect-buffer draft "indirect")))
      (with-current-buffer indirect
        (org-mode)
        (goto-char (point-max))
        (org-download-image png))
      (kill-buffer indirect)
      (with-current-buffer draft
        (write-file note)
        (should (string-match-p
                 "\\[\\[file:attachments/draft/[^]/]+\\.png\\]\\]"
                 (buffer-string)))))))

(ert-deftest tim/org-closing-indirect-view-keeps-staged-images ()
  "Closing an indirect view of a draft (C-c C-x b, which clones the
buffer) leaves the draft's staged images alone."
  (tim/test-with-notes ((png "clip.png"))
    (tim/test-make-image png)
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (let ((draft (current-buffer)))
            (goto-char (point-max))
            (org-download-image png)
            (goto-char (point-min))
            (org-tree-to-indirect-buffer)
            (let ((staging (buffer-local-value 'tim/org-staging-dir draft)))
              (kill-buffer (seq-find (lambda (b) (eq (buffer-base-buffer b)
                                                     draft))
                                     (buffer-list)))
              (should (file-exists-p staging))))
        (set-buffer-modified-p nil)
        (kill-buffer)))))

(ert-deftest tim/org-new-note-stages-until-written ()
  "A note opened with C-x C-f but not yet on disk stages its images;
the first save refiles them, and killing it unsaved leaves nothing."
  (tim/test-with-notes ((note "topics/new.org")
                        (other "topics/dropped.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory note) t)
    (find-file note)
    (should (string-prefix-p tim/org-staging-directory org-download-image-dir))
    (org-download-image png)
    (save-buffer)
    (should (string-match-p
             "\\[\\[file:\\.\\./attachments/topics/new/[^]/]+\\.png\\]\\]"
             (buffer-string)))
    (find-file other)
    (org-download-image png)
    (let ((staging org-download-image-dir))
      (set-buffer-modified-p nil)
      (kill-buffer)
      (should-not (file-exists-p staging))
      (should-not (file-exists-p
                   (expand-file-name "attachments/topics/dropped" root))))))

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

(ert-deftest tim/org-refused-folder-moves-nothing ()
  "Answering no to creating a new note's missing folder stops the save
before any staged image moves, so the draft still has them; yes asks
only once."
  (tim/test-with-notes ((note "typo/new.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (find-file note)
    (org-download-image png)
    (let ((staging tim/org-staging-dir)
          (text (buffer-string))
          (asked 0))
      (cl-letf (((symbol-function 'y-or-n-p) (lambda (&rest _) nil)))
        (should-error (save-buffer)))
      (should (equal tim/org-staging-dir staging))
      (should (equal (buffer-string) text))
      (should (= (length (tim/test-staged-files)) 1))
      (should-not (file-exists-p (expand-file-name "attachments" root)))
      (cl-letf (((symbol-function 'y-or-n-p)
                 (lambda (&rest _) (cl-incf asked) t)))
        (save-buffer))
      (should (= asked 1))
      (should (file-exists-p note))
      (should (string-match-p
               "\\[\\[file:\\.\\./attachments/typo/new/[^]/]+\\.png\\]\\]"
               (buffer-string))))))

(defun tim/test-indirect-view (base)
  "Open a C-c C-x b view of BASE's first heading and return it."
  (with-current-buffer base
    (goto-char (point-min))
    (org-tree-to-indirect-buffer))
  (seq-find (lambda (b) (eq (buffer-base-buffer b) base)) (buffer-list)))

(ert-deftest tim/org-indirect-view-follows-first-save ()
  "An image added in a view kept open across its draft's first save
goes to the note's folder, with a relative link."
  (tim/test-with-notes ((note "topics/draft.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (make-directory (file-name-directory note) t)
    (let* ((draft (tim/test-open-draft))
           (view (tim/test-indirect-view draft)))
      (with-current-buffer draft (write-file note))
      (with-current-buffer view
        (goto-char (point-max))
        (org-download-image png))
      (with-current-buffer draft
        (should (string-match-p
                 "\\[\\[file:\\.\\./attachments/topics/draft/[^]/]+\\.png\\]\\]"
                 (buffer-string)))))))

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

(defun tim/test-stage (folder name)
  "Make an image NAME in FOLDER under the staging root; return its path."
  (let ((file (expand-file-name name (expand-file-name
                                      folder tim/org-staging-directory))))
    (make-directory (file-name-directory file) t)
    (tim/test-make-image file)
    file))

(ert-deftest tim/org-save-refiles-any-staged-link ()
  "Saving moves any file the text links under the staging root, as
after recovering a crashed draft's auto-save, and relinks it."
  (tim/test-with-notes ((note "topics/aviation.org"))
    (let ((staged (tim/test-stage "buffer-999999999-abc" "x.png")))
      (tim/test-open-note note)
      (insert "[[file:" staged "]]\n")
      (save-buffer)
      (should (string-search "[[file:../attachments/topics/aviation/x.png]]"
                             (buffer-string)))
      (should (file-exists-p
               (expand-file-name "attachments/topics/aviation/x.png" root)))
      (should-not (file-exists-p (file-name-directory staged))))))

(ert-deftest tim/org-save-copies-live-drafts-images ()
  "A link copied from an open draft into a note is refiled as a copy,
so the draft's own link still works."
  (tim/test-with-notes ((note "topics/aviation.org")
                        (png "clip.png"))
    (tim/test-make-image png)
    (let ((draft (tim/test-open-draft)))
      (unwind-protect
          (let (staged)
            (with-current-buffer draft
              (goto-char (point-max))
              (org-download-image png)
              (setq staged (car (tim/test-staged-files))))
            (tim/test-open-note note)
            (insert "[[file:" staged "]]\n")
            (save-buffer)
            (should (file-exists-p staged))
            (should (string-search
                     (concat "[[file:../attachments/topics/aviation/"
                             (file-name-nondirectory staged) "]]")
                     (buffer-string))))
        (with-current-buffer draft
          (set-buffer-modified-p nil)
          (kill-buffer))))))

(ert-deftest tim/org-save-copies-other-emacs-images ()
  "A link into a folder another running Emacs stages is refiled as a
copy, as that Emacs's draft still links the file."
  (tim/test-with-notes ((note "topics/aviation.org"))
    (let ((other (start-process "other-emacs" nil
                                (expand-file-name invocation-name
                                                  invocation-directory)
                                "-Q" "--batch" "--eval" "(sleep-for 60)")))
      (unwind-protect
          (let ((staged (tim/test-stage
                         (format "buffer-%d-abc" (process-id other)) "x.png")))
            (tim/test-open-note note)
            (insert "[[file:" staged "]]\n")
            (save-buffer)
            (should (file-exists-p staged))
            (should (file-exists-p
                     (expand-file-name "attachments/topics/aviation/x.png"
                                       root))))
        (delete-process other)))))

(ert-deftest tim/org-staging-folder-names-its-emacs ()
  "A staging folder's name holds this Emacs's PID, so a later clean-up
can tell whether its Emacs is still running."
  (tim/test-with-notes ()
    (with-current-buffer (tim/test-open-draft)
      (unwind-protect
          (should (string-prefix-p
                   (expand-file-name (format "buffer-%d-" (emacs-pid))
                                     tim/org-staging-directory)
                   tim/org-staging-dir))
        (set-buffer-modified-p nil)
        (kill-buffer)))))

(ert-deftest tim/org-staging-clean-deletes-orphans-only ()
  "The clean-up deletes folders whose Emacs has gone, keeping any an
auto-save file names (they may still be recovered) and any whose Emacs
is running.  The auto-save folder holds a sessions/ folder, as
no-littering makes one there."
  (tim/test-with-notes ()
    (let* ((tim/org-auto-save-directory (expand-file-name "auto-save/" root))
           (live (file-name-directory
                  (tim/test-stage (format "buffer-%d-live" (emacs-pid)) "a.png")))
           (dead (file-name-directory
                  (tim/test-stage "buffer-999999999-dead" "b.png")))
           (old (file-name-directory (tim/test-stage "buffer-old" "c.png")))
           (saved (tim/test-stage "buffer-999999999-saved" "d.png")))
      (make-directory (expand-file-name "sessions/" tim/org-auto-save-directory)
                      t)
      (with-temp-file (expand-file-name "#!draft#" tim/org-auto-save-directory)
        (insert "* Heading\n[[file:" saved "]]\n"))
      (should (equal (sort (mapcar #'car (tim/org-orphan-staging-folders))
                           #'string<)
                     (sort (list dead old (file-name-directory saved))
                           #'string<)))
      (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest _) t)))
        (tim/org-download-staging-clean))
      (should (file-exists-p live))
      (should (file-exists-p saved))
      (should-not (file-exists-p dead))
      (should-not (file-exists-p old)))))

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
