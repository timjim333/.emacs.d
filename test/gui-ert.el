;;; gui-ert.el --- Run ERT tests in a GUI Emacs -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-27

;;; Commentary:

;; Loaded by test/gui-ert after init.  Waits for start-up to settle,
;; runs every loaded ERT test, writes the results to GUI_ERT_REPORT,
;; and exits with 0 if all passed, 1 otherwise.

;;; Code:

(require 'ert)

(defun tim/gui-ert-run ()
  "Run all ERT tests after a short delay, then exit."
  (run-with-timer
   3 nil
   (lambda ()
     (let* ((start (with-current-buffer (messages-buffer) (point-max)))
            (stats (ert-run-tests-batch t))
            (failed (ert-stats-completed-unexpected stats)))
       (with-temp-file (getenv "GUI_ERT_REPORT")
         (insert (with-current-buffer (messages-buffer)
                   (buffer-substring start (point-max)))))
       (kill-emacs (if (zerop failed) 0 1))))))

;;; gui-ert.el ends here
