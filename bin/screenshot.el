;;; screenshot.el --- Shot runner for bin/screenshot -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-31

;;; Commentary:

;; Loaded by bin/screenshot after init.  After 15 s, a timer loads the
;; shot script (SCREENSHOT_SCRIPT), which lists its shots with
;; `tim/screenshot-add', opens a frame just under 1600x900, takes each
;; shot into SCREENSHOT_DIR, and exits.  An error is written to
;; error.txt there and ends the run at once.  Not part of the config.

;;; Code:

(require 'package)

(defvar tim/screenshot--shots nil
  "Shots to take, in order, as (NAME . FUNCTION).")

(defmacro tim/screenshot-add (name &rest body)
  "Add a shot saved as NAME.png: run BODY, redisplay, and export."
  (declare (indent 1))
  `(setq tim/screenshot--shots
         (append tim/screenshot--shots (list (cons ,name (lambda () ,@body))))))

(defun tim/screenshot-install (package)
  "Install PACKAGE for this run into SCREENSHOT_ELPA and activate it.
For trying a package the config doesn't have, so it never lands in
the shared elpa/.  Signals an error if SCREENSHOT_ELPA is unset."
  (let ((dir (getenv "SCREENSHOT_ELPA")))
    (unless (and dir (not (string-empty-p dir)))
      (error "Set SCREENSHOT_ELPA to a scratchpad folder to install %s"
             package))
    (setq package-user-dir (expand-file-name dir))
    (unless (package-installed-p package)
      (unless (assq package package-archive-contents)
        (package-refresh-contents))
      ;; DONT-SELECT keeps it out of `package-selected-packages', which
      ;; would otherwise be saved to the shared custom.el.
      (package-install package t))))

(defun tim/screenshot--size-frame (width height)
  "Replace the selected frame with the largest that fits WIDTH x HEIGHT.
PlasmaZones blocks resizing a frame once shown, but a new frame gets
its size; see docs/research/2026-10-30-frame-resize.md.  The frame is
whole columns and lines, a few pixels short, so bin/screenshot pads
the images.  Signals an error if the size doesn't take."
  (let* ((old (selected-frame))
         (dw (- (frame-outer-width old) (frame-text-width old)))
         (dh (- (frame-outer-height old) (frame-text-height old)))
         (cols (/ (- width dw) (frame-char-width old)))
         (lines (/ (- height dh) (frame-char-height old)))
         (want-w (+ dw (* cols (frame-char-width old))))
         (want-h (+ dh (* lines (frame-char-height old))))
         (new (make-frame `((width . ,cols) (height . ,lines)))))
    (select-frame-set-input-focus new)
    (delete-frame old)
    (with-timeout (5 nil)
      (while (not (and (= (frame-outer-width new) want-w)
                       (= (frame-outer-height new) want-h)))
        (sit-for 0.1)))
    (unless (and (= (frame-outer-width new) want-w)
                 (= (frame-outer-height new) want-h))
      (error "Frame is %dx%d, not %dx%d"
             (frame-outer-width new) (frame-outer-height new) want-w want-h))))

(defun tim/screenshot--take (name dir)
  "Save the selected frame as DIR/NAME.png."
  (let ((coding-system-for-write 'binary))
    (write-region (x-export-frames nil 'png) nil
                  (expand-file-name (concat name ".png") dir) nil 'silent)))

(defun tim/screenshot--run ()
  "Load SCREENSHOT_SCRIPT, take every shot into SCREENSHOT_DIR, then exit.
The script is loaded here rather than from the command line, so its
errors are caught too.  On an error, or if the config had an init
error, write it to error.txt there and exit with status 1."
  (let ((dir (getenv "SCREENSHOT_DIR")))
    (condition-case err
        (progn
          (when init-file-had-error
            (error "The config had an init error; run bin/start-check on it"))
          (load (getenv "SCREENSHOT_SCRIPT") nil t)
          (unless tim/screenshot--shots
            (error "The script added no shots"))
          (tim/screenshot--size-frame 1600 900)
          (pcase-dolist (`(,name . ,fn) tim/screenshot--shots)
            (funcall fn)
            (redisplay t)
            (tim/screenshot--take name dir))
          (kill-emacs 0))
      (error
       (with-temp-file (expand-file-name "error.txt" dir)
         (insert (error-message-string err) "\n"))
       (kill-emacs 1)))))

(run-with-timer 15 nil #'tim/screenshot--run)

;;; screenshot.el ends here
