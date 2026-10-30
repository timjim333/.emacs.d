;;; frame-resize-probe.el --- Can a shown frame resize? -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-30

;;; Commentary:

;; Evidence for docs/research/2026-10-30-frame-resize.md.  Run with
;;   PROBE_OUT=<file> emacs -Q -l <this file>
;; After 10 s it asks the frame for 1200x600 text pixels, waits 2 s,
;; writes the sizes before and after to PROBE_OUT, and exits.

;;; Code:

(defun probe--sizes (label f)
  "Return a line with frame F's outer and text sizes, after LABEL."
  (format "%s: outer %dx%d text %dx%d\n" label
          (frame-outer-width f) (frame-outer-height f)
          (frame-text-width f) (frame-text-height f)))

(run-with-timer
 10 nil
 (lambda ()
   (let* ((f (selected-frame))
          (log (format "name %S\n%s" (frame-parameter f 'name)
                       (probe--sizes "initial" f))))
     (set-frame-size f 1200 600 t)
     (dotimes (_ 20) (sit-for 0.1))
     (setq log (concat log (probe--sizes "set 1200x600 px" f)))
     (with-temp-file (getenv "PROBE_OUT") (insert log))
     (kill-emacs 0))))

;;; frame-resize-probe.el ends here
