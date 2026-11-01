;;; gui-ert.el --- Run ERT tests in a GUI Emacs -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-11-01

;;; Commentary:

;; Loaded by test/gui-ert after init.  Loads the test file
;; (GUI_ERT_TESTS), waits for start-up to settle, runs every loaded
;; ERT test, writes the results to GUI_ERT_REPORT, and exits with 0 if
;; all passed, 1 otherwise.

;;; Code:

(require 'ert)

(defun tim/gui-ert-run ()
  "Load GUI_ERT_TESTS, run its tests after a short delay, then exit.
The file is loaded here rather than from the command line, so a load
error, or an init error in the config, is written to GUI_ERT_REPORT
and exits at once with status 1."
  (condition-case err
      (progn
        (when init-file-had-error
          (error "The config had an init error; run bin/start-check on it"))
        (load (getenv "GUI_ERT_TESTS") nil t))
    (error
     (with-temp-file (getenv "GUI_ERT_REPORT")
       (insert "FAIL: before the tests: " (error-message-string err) "\n"))
     (kill-emacs 1)))
  (run-with-timer
   3 nil
   (lambda ()
     ;; Keep every line of *Messages*, so trimming its top can't move
     ;; the report's start.
     (let* ((message-log-max t)
            (start (with-current-buffer (messages-buffer) (point-max)))
            (stats (ert-run-tests-batch t))
            (failed (ert-stats-completed-unexpected stats))
            (none (zerop (ert-stats-total stats))))
       (with-temp-file (getenv "GUI_ERT_REPORT")
         (insert (with-current-buffer (messages-buffer)
                   (buffer-substring start (point-max))))
         ;; A file with a typo'd or missing test mustn't pass.
         (when none
           (insert "FAIL: no tests ran\n")))
       (kill-emacs (if (and (zerop failed) (not none)) 0 1))))))

;;; gui-ert.el ends here
