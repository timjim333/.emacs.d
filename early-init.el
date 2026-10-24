;;; early-init.el --- Tangled from init.org -*- lexical-binding: t -*-

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
