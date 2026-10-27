;;; early-init.el --- Paths and frame settings before init -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-27

;;; Commentary:

;; Hand-written, because it runs before init.el could tangle anything
;; (ADR 0003).  It points all State outside the repo (ADR 0002):
;; packages and data under $XDG_DATA_HOME/emacs, caches under
;; $XDG_CACHE_HOME/emacs.

;;; Code:

;;;; State paths

(defconst tim/data-dir
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_DATA_HOME") "~/.local/share")))
  "Where packages and other State that should survive live.")

(defconst tim/cache-dir
  (file-name-as-directory
   (expand-file-name "emacs" (or (getenv "XDG_CACHE_HOME") "~/.cache")))
  "Where State that can be rebuilt (native-comp output) lives.")

(setq package-user-dir (expand-file-name "elpa" tim/data-dir))

;; Read by no-littering when it loads, so set before then.
(setq no-littering-var-directory (expand-file-name "var/" tim/data-dir)
      no-littering-etc-directory (expand-file-name "etc/" tim/data-dir))

(setq custom-file (expand-file-name "custom.el" tim/data-dir))

;; Org's default, ltximg/ beside each note, would sync to the phone.
(setq org-preview-latex-image-directory
      (expand-file-name "org-latex/" tim/cache-dir))

(when (fboundp 'startup-redirect-eln-cache)
  (startup-redirect-eln-cache (expand-file-name "eln-cache/" tim/cache-dir)))

;; Auto-install uses the first writable entry here; seeding the history
;; makes `treesit-install-language-grammar' default to it too.
(let ((grammars (expand-file-name "tree-sitter" tim/data-dir)))
  (setq treesit-extra-load-path (list grammars))
  (defvar treesit--install-language-grammar-out-dir-history)
  (setq treesit--install-language-grammar-out-dir-history (list grammars)))

;;;; Start-up speed

;; Collect garbage rarely while starting, then go back to a sane value.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; Language servers send a lot of data; read it in bigger chunks.
(setq read-process-output-max (* 4 1024 1024))

;; Prefer newer .el files over stale .elc files.
(setq load-prefer-newer t)

;;;; Frames

;; No menu bar, tool bar or scroll bars, set before the first frame is drawn.
(setq default-frame-alist
      '((menu-bar-lines       . 0)
        (tool-bar-lines       . 0)
        (vertical-scroll-bars . nil)
        (internal-border-width . 16)))

(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise       t
      inhibit-startup-screen       t
      initial-scratch-message      nil)

;; Native compilation warnings are noisy and almost always harmless.
(setq native-comp-async-report-warnings-errors 'silent)

;; On pgtk, a shorter event timeout makes child frames (the pop-up
;; completion window) feel snappier.
(when (boundp 'pgtk-wait-for-event-timeout)
  (setq pgtk-wait-for-event-timeout 0.001))

;;; early-init.el ends here
