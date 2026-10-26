;;; init.el --- Tangle and load config.org -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-26

;;; Commentary:

;; The config lives in config.org (ADR 0003).  This stub re-tangles it
;; to config.el when the Org file is newer, then loads config.el, which
;; is not in git.  Uses the built-in Org.

;;; Code:

(let ((org (expand-file-name "config.org" user-emacs-directory))
      (el  (expand-file-name "config.el" user-emacs-directory)))
  (when (file-newer-than-file-p org el)
    (require 'ob-tangle)
    (org-babel-tangle-file org))
  (load el nil 'nomessage))

;;; init.el ends here
