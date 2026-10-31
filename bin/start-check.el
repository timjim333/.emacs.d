;;; start-check.el --- Start report for bin/start-check -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-31

;;; Commentary:

;; Loaded by bin/start-check after init: from the command line for a
;; GUI start, or through emacsclient for the daemon.  Not part of the
;; config.

;;; Code:

(defun tim/start-check--warnings-state ()
  "Return none, empty, or the line count of the *Warnings* buffer."
  (let ((buffer (get-buffer "*Warnings*")))
    (cond ((null buffer) "none")
          ((zerop (buffer-size buffer)) "empty")
          (t (with-current-buffer buffer
               (format "%d lines" (count-lines (point-min) (point-max))))))))

(defun tim/start-check-report (file)
  "Write a start report to FILE.
The header lines are what bin/start-check judges; the *Warnings* and
*Messages* buffers follow for reading."
  (let ((warnings (get-buffer "*Warnings*")))
    (with-temp-file file
      (insert (format "emacs-version: %s\n" emacs-version)
              (format "user-emacs-directory: %s\n" user-emacs-directory)
              (format "user-emacs-directory-truename: %s\n"
                      (file-truename user-emacs-directory))
              (format "package-user-dir: %s\n" package-user-dir)
              (format "init-file-had-error: %S\n" init-file-had-error)
              (format "warnings-buffer: %s\n"
                      (tim/start-check--warnings-state))
              "\n--- *Warnings* ---\n"
              (if warnings
                  (with-current-buffer warnings (buffer-string))
                "NO WARNINGS BUFFER\n")
              "\n--- *Messages* ---\n"
              (with-current-buffer (messages-buffer) (buffer-string))))))

(defun tim/start-check-run ()
  "Write the report after a delay, then exit.
Reads the report path from START_CHECK_REPORT and the delay in seconds
from START_CHECK_DELAY (default 25)."
  (run-with-timer
   (string-to-number (or (getenv "START_CHECK_DELAY") "25")) nil
   (lambda ()
     (tim/start-check-report (getenv "START_CHECK_REPORT"))
     (kill-emacs 0))))

;;; start-check.el ends here
