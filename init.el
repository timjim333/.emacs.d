;;; init.el --- Tangled from init.org -*- lexical-binding: t -*-

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities
      '(("gnu" . 30) ("nongnu" . 20) ("melpa" . 10)))
(package-initialize)

(require 'use-package)
(setq use-package-always-ensure t)

(defun tim/tangle-init ()
  "Tangle init.org when it is saved."
  (when (equal (buffer-file-name)
               (expand-file-name "init.org" user-emacs-directory))
    ;; Avoid running hooks while tangling.
    (let ((prog-mode-hook nil))
      (org-babel-tangle))))

(add-hook 'after-save-hook #'tim/tangle-init)

(use-package no-littering
  :demand t
  :config
  (no-littering-theme-backups))

(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(dolist (file (list custom-file
                    (expand-file-name "private.el" user-emacs-directory)))
  (when (file-exists-p file)
    (load file nil t)))

(setq create-lockfiles             nil
      ring-bell-function           'ignore
      use-dialog-box               nil
      use-short-answers            t
      sentence-end-double-space    nil
      echo-keystrokes              0.1
      recentf-max-saved-items      1000
      auto-revert-verbose          nil
      global-auto-revert-non-file-buffers t
      save-interprogram-paste-before-kill t
      large-file-warning-threshold (* 50 1024 1024))

(setq-default indent-tabs-mode nil
              tab-width        4
              fill-column      80)

(set-language-environment "UTF-8")
(setq default-input-method nil)

(delete-selection-mode   1) ;; Typing replaces the selection
(global-auto-revert-mode 1) ;; Reload files changed on disk (e.g. by sync)
(recentf-mode            1) ;; Remember recently opened files
(savehist-mode           1) ;; Remember minibuffer history
(save-place-mode         1) ;; Reopen files where I left off
(global-so-long-mode     1) ;; Stay fast on files with very long lines

(require 'server)
(unless (or (daemonp) (server-running-p))
  (server-start))

(blink-cursor-mode 0)
(setq-default cursor-type 'bar
              cursor-in-non-selected-windows nil)

(column-number-mode 1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(setq-default display-line-numbers-width 3)

;; Smooth, pixel-precise scrolling (works well on pgtk/Wayland).
(pixel-scroll-precision-mode 1)
(setq scroll-conservatively         101
      mouse-wheel-progressive-speed nil
      mouse-wheel-scroll-amount     '(1 ((shift) . 3) ((meta) . 6)))

(defvar tim/font-height 115)

(defun tim/set-fonts ()
  "Set fonts, skipping any that aren't installed."
  (when (member "JetBrains Mono" (font-family-list))
    (set-face-attribute 'default nil :family "JetBrains Mono" :height tim/font-height)
    (set-face-attribute 'fixed-pitch nil :family "JetBrains Mono" :height 1.0))
  (when (member "Inter" (font-family-list))
    (set-face-attribute 'variable-pitch nil :family "Inter" :height 1.05)))

;; Fonts can only be set once a graphical frame exists, which matters when
;; running as a daemon.
(if (daemonp)
    (add-hook 'server-after-make-frame-hook #'tim/set-fonts)
  (tim/set-fonts))

(use-package nerd-icons)

(use-package doom-themes
  :demand t
  :config
  (setq doom-themes-enable-bold   t
        doom-themes-enable-italic t)
  (load-theme 'doom-nord t)
  (doom-themes-org-config))

;; Fully unload the previous theme when switching, so faces don't mix.
(defun tim/disable-themes (&rest _)
  (mapc #'disable-theme custom-enabled-themes))
(advice-add 'load-theme :before #'tim/disable-themes)

(electric-pair-mode 1)   ;; Insert matching brackets and quotes
(show-paren-mode    1)   ;; Highlight matching brackets
(add-hook 'text-mode-hook #'visual-line-mode)

;; C-/ undoes, C-? redoes.
(global-set-key (kbd "C-?") #'undo-redo)

(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind (("M-$"   . jinx-correct)
         ("C-M-$" . jinx-languages)))

(use-package which-key
  :ensure nil
  :config (which-key-mode 1))

(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-key]      . helpful-key)
         ([remap describe-command]  . helpful-command)
         ("C-h F"                   . helpful-function)))

(use-package vertico
  :init (vertico-mode 1)
  :config
  (setq vertico-cycle t
        vertico-count 15))

;; Go up a directory with one key when finding files.
(use-package vertico-directory
  :ensure nil
  :after vertico
  :bind (:map vertico-map
              ("DEL"   . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)))

(use-package vertico-posframe
  :after vertico
  :config
  (setq vertico-posframe-parameters '((left-fringe . 8) (right-fringe . 8)))
  (vertico-posframe-mode 1))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-s"     . consult-line)          ;; Search in buffer
         ("C-x b"   . consult-buffer)        ;; Buffers, recent files, bookmarks
         ("M-y"     . consult-yank-pop)      ;; Kill ring
         ("M-g g"   . consult-goto-line)
         ("M-g i"   . consult-imenu)         ;; Jump to heading/function
         ("M-g o"   . consult-outline)
         ("M-s r"   . consult-ripgrep)       ;; Full-text search in project
         ("M-s f"   . consult-fd)            ;; Find file by name
         ("C-x r b" . consult-bookmark))
  :config
  (setq consult-narrow-key "<"
        xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref))

(use-package embark
  :bind (("C-."   . embark-act)
         ("C-h B" . embark-bindings))
  :config
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package corfu
  :init (global-corfu-mode 1)
  :config
  (setq corfu-auto       t
        corfu-auto-delay 0.2
        corfu-cycle      t))

(use-package magit
  :bind ("C-x g" . magit-status))

(use-package diff-hl
  :hook ((after-init         . global-diff-hl-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh)))
