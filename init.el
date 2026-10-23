;;; -*- lexical-binding: t -*-

(defun tangle-init ()
  "If the current buffer is init.org the code-blocks are
tangled, and the tangled file is compiled."
  (when (equal (buffer-file-name)
               (expand-file-name (concat user-emacs-directory "init.org")))
    ;; Avoid running hooks when tangling.
    (let ((prog-mode-hook nil))
      (org-babel-tangle)
      (byte-compile-file (concat user-emacs-directory "init.el")))))

(add-hook 'after-save-hook 'tangle-init)

(setq file-name-handler-alist-original file-name-handler-alist)
(setq file-name-handler-alist nil)

(setq native-comp-async-report-warnings-errors 'silent) ;; native-comp warning
(setq byte-compile-warnings '(not free-vars unresolved noruntime lexical make-local))

(setq which-func-update-delay 1.0)

(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")

(setq native-comp-eln-load-path '("~/.emacs.d/eln-cache/"))

(require 'package)
(require 'use-package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)

(setq package-archives
      '(("GNU ELPA"     . "https://elpa.gnu.org/packages/")
        ("MELPA"        . "https://melpa.org/packages/")
        ("ORG"          . "https://orgmode.org/elpa/")
        ("MELPA Stable" . "https://stable.melpa.org/packages/")
        ("nongnu"       . "https://elpa.nongnu.org/nongnu/"))
      package-archive-priorities
      '(("GNU ELPA"     . 20)
        ("MELPA"        . 15)
        ("ORG"          . 10)
        ("MELPA Stable" . 5)
        ("nongnu"       . 0)))
(package-initialize)

(setq user-emacs-directory "~/.emacs.d/")
(setq default-directory "~/")

(set-language-environment    "UTF-8")
(setq locale-coding-system   'utf-8)
(prefer-coding-system        'utf-8)
(set-default-coding-systems  'utf-8)
(set-terminal-coding-system  'utf-8)
(set-keyboard-coding-system  'utf-8)
(set-selection-coding-system 'utf-8)

(setq large-file-warning-threshold (* 50 1024 1024))

(setq create-lockfiles nil)
(setq make-backup-files nil)

(setq backup-directory-alist
      `(("." . ,(expand-file-name "backup" user-emacs-directory))))
(setq tramp-backup-directory-alist backup-directory-alist)

(setq backup-by-copying-when-linked t)
(setq backup-by-copying             t) ; Backup by copying rather renaming
(setq delete-old-versions           t) ; Delete excess backup versions silently
(setq version-control               t) ; Use version numbers for backup files
(setq kept-new-versions             5)
(setq kept-old-versions             5)

(setq package-gnupghome-dir "~/.gnupg")

(defvar local-lisp (concat user-emacs-directory "user-lisp/"))
(make-directory local-lisp t)
(add-to-list 'load-path  local-lisp)
(let ((default-directory local-lisp))
  (normal-top-level-add-subdirs-to-load-path))

(setq org-agenda-files '())
(setq register-alist '())
(setq projectile-project-search-path '())

(add-hook
 'after-init-hook
 (lambda ()
   (let ((private-file (concat user-emacs-directory "private.el"))
		 (custom-file (concat user-emacs-directory "custom.el")))
     (when (file-exists-p private-file)
       (load-file private-file))
     (when (file-exists-p custom-file)
       (load-file custom-file))
     (server-start))))

(dirtrack-mode t)

(use-package dwim-shell-command
  :defer t
  :init (require 'dwim-shell-commands))

(defvar custom-bindings-map (make-keymap)
  "A keymap for custom keybindings.")

(global-unset-key (kbd "C-x C-z"))
;; (global-unset-key (kbd "C-<wheel-up>"))
;; (global-unset-key (kbd "C-<wheel-down>"))
(global-unset-key (kbd "C-z"))

(setq inhibit-startup-message           t       ;; No startup message
      inhibit-startup-echo-area-message t       ;; No startup message in echo area
      inhibit-startup-screen            t       ;; No default startup screen
      ;; initial-buffer-choice             t       ;; *scratch* is default startup buffer
      initial-major-mode                'fundamental-mode
      ring-bell-function                'ignore ;; No bell
      display-time-default-load-average nil     ;; Don't show me load time
      scroll-margin                     0       ;; Space between top/bottom
      use-dialog-box                    nil)    ;; Disable dialog

;; (add-to-list 'default-frame-alist     '(fullscreen . maximized))
;; (add-hook 'window-setup-hook          'toggle-frame-fullscreen t)  ;; F11

(defun toggle-transparency ()
  (interactive)
  (let ((alpha (frame-parameter nil 'alpha)))
    (set-frame-parameter
     nil 'alpha
     (if (eql (cond ((numberp alpha) alpha)
                    ((numberp (cdr alpha)) (cdr alpha))
                    ;; Also handle undocumented (<active> <inactive>) form.
                    ((numberp (cadr alpha)) (cadr alpha)))
              100)
         '(90 . 55) '(100 . 100)))))
(global-set-key (kbd "C-c h t") 'toggle-transparency)

(add-to-list 'default-frame-alist '(internal-border-width . 16))

(set-fringe-mode 10)                          ;; Set fringe width to 10

(setq-default fringes-outside-margins nil)
(setq-default indicate-buffer-boundaries nil) ;; Otherwise shows a corner icon on the edge
(setq-default indicate-empty-lines nil)       ;; Otherwise there are weird fringes on blank lines

(set-face-attribute 'header-line t :inherit 'default)

(blink-cursor-mode        0)
(setq-default cursor-type 'bar)

(setq-default cursor-in-non-selected-windows nil)
(setq highlight-nonselected-windows          nil)

(use-package beacon
  :defer t
  :init  (beacon-mode 1)
  :bind (:map custom-bindings-map ("C-:" . beacon-blink))
  :config
  (setq beacon-blink-when-window-scrolls nil))

(use-package rainbow-delimiters
  :hook (prog-mode-hook . rainbow-delimiters-mode))

(show-paren-mode t) ;; Highlight matching parentheses

(add-hook 'prog-mode-hook 'display-line-numbers-mode)

(setq-default display-line-numbers-width 3)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(setq my-whitespace-style '(face tabs lines-tail)
      whitespace-style my-whitespace-style
      whitespace-line-column 120
      fill-column 120
      whitespace-display-mappings
      '((space-mark 32 [183] [46])
        (newline-mark 10 [36 10])
        (tab-mark 9 [9655 9] [92 9])))

;; in e.g. clojure-mode-hook
;; (whitespace-mode 1)
;; or globally
;; (global-whitespace-mode 1)
(add-hook 'prog-mode 'whitespace-mode)

(defvar tim/font-height 115)

(when (member "Fragment Mono" (font-family-list))
  (set-face-attribute 'default nil :font "Fragment Mono" :height tim/font-height)
  (set-face-attribute 'fixed-pitch nil :family "Fragment Mono"))

(when (member "Open Sans" (font-family-list))
  (set-face-attribute 'variable-pitch nil :family "Open Sans"))

(use-package mixed-pitch
  :defer t
  :hook ((org-mode   . mixed-pitch-mode)
         (LaTeX-mode . mixed-pitch-mode)))

(defvar ligature-def '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
                       ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
                       "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
                       "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
                       "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
                       "..." "+++" "/==" "///" "_|_" "www" "&&" "^=" "~~" "~@" "~="
                       "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
                       "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
                       ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
                       "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
                       "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
                       "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
                       "\\\\" "://"))

(use-package ligature
  :config
  (ligature-set-ligatures 'prog-mode ligature-def)
  (global-ligature-mode t))

(setq text-scale-mode-step 1.1)

(use-package default-text-scale
  :defer t
  :bind (:map custom-bindings-map
              ("C-x C-+" . default-text-scale-increase)
              ("C-x C--" . default-text-scale-decrease)
              ("C-x C-0" . default-text-scale-reset)))

(use-package nerd-icons)

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t     ; if nil, bold is universally disabled
        doom-themes-enable-italic t)) ; if nil, italics is universally disabled

(use-package south-theme
  :vc (:url "https://github.com/SophieBosio/south"
       :rev :newest
       :branch "main"))

(setq custom-safe-themes t)

(defvar tim/default-dark-theme  'doom-nord)
(defvar tim/default-light-theme 'south)

(defvar tim/default-dark-accent-colour  "SkyBlue4")
(defvar tim/default-light-accent-colour "#D9EDFC")

(load-theme tim/default-dark-theme t)

(use-package autothemer
  :defer t)

(use-package auto-dark
  :ensure t
  :hook ((auto-dark-dark-mode
          .
          (lambda ()
            (interactive)
            (progn
              (custom-set-faces
               `(eval-sexp-fu-flash
                 ((t (:background
                      ,tim/default-dark-accent-colour)))))
              `(load-theme ,tim/default-dark-theme t))))
         (auto-dark-light-mode
          .
          (lambda ()
            (interactive)
            (progn
              (custom-set-faces
               `(eval-sexp-fu-flash
                 ((t (:background
                      ,tim/default-light-accent-colour)))))
              `(load-theme ,tim/default-light-theme t)))))
  :custom
  (auto-dark-themes                   `((,tim/default-dark-theme) (,tim/default-light-theme)))
  (auto-dark-polling-interval-seconds 5)
  (auto-dark-allow-osascript          t)
  :init (auto-dark-mode t))

(when (eq system-type 'darwin)
  (define-key custom-bindings-map (kbd "M-T") 'dwim-shell-commands-macos-toggle-dark-mode))

(defun disable-custom-themes (theme &optional no-confirm no-enable)
  (mapc 'disable-theme custom-enabled-themes))

(advice-add 'load-theme :before #'disable-custom-themes)

(column-number-mode t) ;; Show current column number in mode line

(defvar lsp-modeline--code-actions-string nil)

(setq-default mode-line-format
  '("%e"
	(:propertize " " display (raise +0.4)) ;; Top padding
	(:propertize " " display (raise -0.4)) ;; Bottom padding

	(:propertize "λ " face font-lock-comment-face)
	mode-line-frame-identification
	mode-line-buffer-identification

	;; Version control info
	(:eval (when-let (vc vc-mode)
			 ;; Use a pretty branch symbol in front of the branch name
			 (list (propertize "  ⎇ " 'face 'font-lock-comment-face)
                   ;; Truncate branch name to 50 characters
				   (propertize (truncate-string-to-width
                                (substring vc 5) 50)
							   'face 'font-lock-comment-face))))

	;; Add space to align to the right
	(:eval (propertize
			 " " 'display
			 `((space :align-to
					  (-  (+ right right-fringe right-margin)
						 ,(+ 3
                             (string-width (or lsp-modeline--code-actions-string ""))
                             (string-width "%4l:3%c")))))))

    ;; LSP code actions
    (:eval (or lsp-modeline--code-actions-string ""))
	
	;; Line and column numbers
	(:propertize "%4l:%c" face mode-line-buffer-id)))

(use-package hide-mode-line
  :defer t
  :bind (:map custom-bindings-map ("C-c h m" . hide-mode-line-mode)))

(use-package olivetti
  :defer t
  :config
  (setq olivetti-style t))

(use-package adaptive-wrap
  :defer t
  :hook (visual-line-mode . adaptive-wrap-prefix-mode))

(use-package writeroom-mode
  :defer t)

(use-package focus
  :defer t)

(delete-selection-mode   t) ;; Replace selected text when yanking
(global-so-long-mode     t) ;; Mitigate performance for long lines
(global-visual-line-mode t) ;; Break lines instead of truncating them
(global-auto-revert-mode t) ;; Revert buffers automatically when they change
(recentf-mode            t) ;; Remember recently opened files
(savehist-mode           t) ;; Remember minibuffer prompt history
(save-place-mode         t) ;; Remember last cursor location in file

(setq auto-revert-interval         1         ;; Refresh buffers fast
      auto-revert-verbose          nil       ;; Don't notify me about reverts
      echo-keystrokes              0.1       ;; Show keystrokes fast
      frame-inhibit-implied-resize 1         ;; Don't resize frame implicitly
      sentence-end-double-space    nil       ;; No double spaces
      recentf-max-saved-items      1000      ;; Show more recent files
      use-short-answers            t         ;; 'y'/'n' instead of 'yes'/'no' etc.
      save-interprogram-paste-before-kill t  ;; Save copies between programs
      history-length               25        ;; Only save the last 25 minibuffer prompts
      global-auto-revert-non-file-buffers t) ;; Revert Dired and other buffers

(setq-default tab-width 4)  ;; Smaller tabs

(setq scroll-conservatively            101
      mouse-wheel-follow-mouse         't
      mouse-wheel-progressive-speed    nil
      ;; Scroll 1 line at a time, instead of default 5
      ;; Hold shift to scroll faster and meta to scroll very fast
      mouse-wheel-scroll-amount        '(1 ((shift) . 3) ((meta) . 6)))

(pixel-scroll-mode)
(pixel-scroll-precision-mode)

(setq mac-redisplay-dont-reset-vscroll t
      mac-mouse-wheel-smooth-scroll    nil)

(defun infer-indentation-style ()
  "Default to no tabs, but use tabs if already in project"
  (let ((space-count (how-many "^  " (point-min) (point-max)))
        (tab-count   (how-many "^\t" (point-min) (point-max))))
    (if (> space-count tab-count) (setq-default indent-tabs-mode nil))
    (if (> tab-count space-count) (setq-default indent-tabs-mode t))))

(setq-default indent-tabs-mode nil)
(infer-indentation-style)

(setq backward-delete-char-untabify-method 'hungry)

(defun tim/delete-dont-kill (arg)
  "Delete characters backward until encountering the beginning of a word.
   With argument ARG, do this that many times. Don't add to kill ring."
  (interactive "p")
  (delete-region (point) (progn (backward-word arg) (point))))

(defun tim/backward-delete ()
  "Delete a word, a character, or whitespace."
  (interactive)
  (cond
   ;; If you see a word, delete all of it
   ((looking-back (rx (char word)) 1)
    (tim/delete-dont-kill 1))
   ;; If you see a single whitespace and a word, delete both together
   ((looking-back (rx (seq (char word) (= 1 blank))) 1)
	(tim/delete-dont-kill 1))
   ;; If you see several whitespaces, delete them until the next word
   ((looking-back (rx (char blank)) 1)
    (delete-horizontal-space t))
   ;; If you see a single non-word character, delete that
   (t
    (backward-delete-char-untabify 1))))

(define-key custom-bindings-map [C-backspace] 'tim/backward-delete)

(use-package browse-kill-ring
  :defer t)

(defvar emacs-autosave-directory
  (concat user-emacs-directory "autosaves/")
  "This variable dictates where to put auto saves. It is set to a
  directory called autosaves located wherever your .emacs.d/ is
  located.")

;; Sets all files to be backed up and auto saved in a single directory.
(setq backup-directory-alist
      `((".*" . ,emacs-autosave-directory))
      auto-save-file-name-transforms
      `((".*" ,emacs-autosave-directory t)))

(use-package auto-save-buffers-enhanced
  :ensure t
  :config
  (auto-save-buffers-enhanced t)
  (setq auto-save-buffers-enhanced-exclude-regexps
        '("init.org"
          "\\(\\.js\\|\\.ts\\|\\.jsx\\|\\.tsx\\|\\.html\\)$")))

(use-package mwim
  :ensure t
  :bind (:map custom-bindings-map
              ("C-a" . mwim-beginning-of-code-or-line)
              ("C-e" . mwim-end-of-code-or-line)))

(use-package expand-region
  :defer t
  :bind (:map custom-bindings-map
              ("C-}" . er/expand-region)
              ("C-{" . er/contract-region)))

;;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph (&optional region)
  "Takes a multi-line paragraph and makes it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
		;; This would override `fill-column' if it's an integer.
		(emacs-lisp-docstring-fill-column t))
	(fill-paragraph nil region)))
;; Handy key definition
(define-key custom-bindings-map (kbd "C-c n q") 'unfill-paragraph)

(use-package multiple-cursors
  :defer t
  :functions
  mc/remove-fake-cursors
  mc/save-excursion
  mc/create-fake-cursor-at-point
  mc/maybe-multiple-cursors-mode
  :bind (:map custom-bindings-map
              ("M-n" . mc/mark-next-like-this)
              ("M-p" . mc/mark-previous-like-this))
  :config
  (setq mc/always-run-for-all t))

(use-package symbol-overlay
  :defer t
  :functions
  symbol-overlay-put
  symbol-overlay-mode
  :hook (prog-mode . symbol-overlay-mode)
  :bind (:map custom-bindings-map
              ("C-:" . symbol-overlay-put)
              ("M-N" . symbol-overlay-jump-next)
              ("M-P" . symbol-overlay-jump-prev)))

(defun ar/mc-mark-all-symbol-overlays ()
  "Mark all symbol overlays using multiple cursors."
  (interactive)
  (mc/remove-fake-cursors)
  (when-let* ((overlays (symbol-overlay-get-list 0))
              (point (point))
              (point-overlay (seq-find
                              (lambda (overlay)
                                (and (<= (overlay-start overlay) point)
                                     (<= point (overlay-end overlay))))
                              overlays))
              (offset (- point (overlay-start point-overlay))))
    (setq deactivate-mark t)
    (mapc (lambda (overlay)
            (unless (eq overlay point-overlay)
              (mc/save-excursion
               (goto-char (+ (overlay-start overlay) offset))
               (mc/create-fake-cursor-at-point))))
          overlays)
    (mc/maybe-multiple-cursors-mode)))

(define-key custom-bindings-map (kbd "C-M-:") 'ar/mc-mark-all-symbol-overlays)

(use-package undo-fu
  :defer t
  :bind (:map custom-bindings-map
              ("C-_" . undo-fu-only-undo)
              ("M-_" . undo-fu-only-redo)))

(use-package move-dup
  :bind (:map custom-bindings-map
              (("C-S-<up>"    . move-dup-move-lines-up)
               ("C-S-<down>"  . move-dup-move-lines-down)
               ("M-W"         . move-dup-duplicate-down))))

(define-key custom-bindings-map (kbd "C-j") 'join-line)

(define-key custom-bindings-map
            (kbd "C-J")
            (lambda ()
              (interactive)
              (join-line -1)))

(define-key custom-bindings-map (kbd "C-S-k") 'kill-whole-line)

(defun tim/kill-buffer (&optional arg)
"When called with a prefix argument -- i.e., C-u -- kill all interesting
buffers -- i.e., all buffers without a leading space in the buffer-name.
When called without a prefix argument, kill just the current buffer
-- i.e., interesting or uninteresting."
(interactive "P")
  (cond
    ((and (consp arg) (equal arg '(4)))
      (mapc
        (lambda (x)
          (let ((name (buffer-name x)))
            (unless (eq ?\s (aref name 0))
              (kill-buffer x))))
        (buffer-list)))
    (t
      (kill-buffer (current-buffer)))))

(define-key custom-bindings-map (kbd "C-c k") 'tim/kill-buffer)

(defun split-window-sensibly-prefer-horizontal (&optional window)
"Based on `split-window-sensibly', but prefers to split WINDOW side-by-side."
  (let ((window (or window (selected-window))))
    (or (and (window-splittable-p window t)
         ;; Split window horizontally
         (with-selected-window window
           (split-window-right)))
    (and (window-splittable-p window)
         ;; Split window vertically
         (with-selected-window window
           (split-window-below)))
    (and
         ;; If WINDOW is the only usable window on its frame (it is
         ;; the only one or, not being the only one, all the other
         ;; ones are dedicated) and is not the minibuffer window, try
         ;; to split it horizontally disregarding the value of
         ;; `split-height-threshold'.
         (let ((frame (window-frame window)))
           (or
            (eq window (frame-root-window frame))
            (catch 'done
              (walk-window-tree (lambda (w)
                                  (unless (or (eq w window)
                                              (window-dedicated-p w))
                                    (throw 'done nil)))
                                frame)
              t)))
     (not (window-minibuffer-p window))
     (let ((split-width-threshold 0))
       (when (window-splittable-p window t)
         (with-selected-window window
               (split-window-right))))))))

(defun split-window-really-sensibly (&optional window)
  (let ((window (or window (selected-window))))
    (if (> (window-total-width window) (* 2 (window-total-height window)))
        (with-selected-window window (split-window-sensibly-prefer-horizontal window))
      (with-selected-window window (split-window-sensibly window)))))

(setq split-window-preferred-function 'split-window-really-sensibly)

(setq-default split-height-threshold nil
              split-width-threshold  nil
              fill-column            80) ;; Maximum line width
              ;; window-min-width       80) ;; No smaller windows than this

(use-package transpose-frame
  :bind (:map custom-bindings-map
              ("C-c f" . 'flop-frame)))

(use-package javelin
  :ensure t
  :config
  (global-javelin-minor-mode 1)
  :bind (:map javelin-minor-mode-map
              ("M-+" . javelin-toggle-quick-menu)))

(setq ibuffer-saved-filter-groups
      '(("default"
         ("Programming"   (predicate . (derived-mode-p 'prog-mode)))
         ("Clojure/CIDER" (or (name  . "clojure")
                              (name  . "cider")
                              (name  . "nrepl")))
         ("Org"           (mode . org-mode))
         ("Dired"         (mode . dired-mode))
         ("Magit"         (name . "magit")))))

(add-hook 'ibuffer-mode-hook
          (lambda ()
            (ibuffer-switch-to-saved-filter-groups "default")))

(setq ibuffer-never-show-predicates
      '(;; System buffers
        "^\\*Messages\\*$"
        "^\\*scratch\\*$"
        "^\\*Completions\\*$"
        "^\\*Help\\*$"
        "^\\*Apropos\\*$"
        "^\\*info\\*$"
        "^\\*Async-native-compile-log\\*$"

        ;; LSP Buffers
        "^\\*lsp-log\\*$"
        "^\\*clojure-lsp\\*$"
        "^\\*clojure-lsp::stderr\\*$"
        "^\\*ts-ls\\*$"
        "^\\*ts-ls::stderr\\*$"))

(setq ibuffer-formats
      '((mark " " (name 60 -1 :left))))

(use-package dired
  :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :bind (:map dired-mode-map
              ("C-<right>" . dired-find-alternate-file)
              ("C-<left>"  . dired-up-directory)
              ("C-<down>"  . dired-find-alternate-file)
              ("C-<up>"    . dired-up-directory)
              ("c"         . dired-create-empty-file))
  :config
  (when (and (eq system-type 'darwin) (executable-find "gls"))
    (setq dired-use-ls-dired nil)))

(put 'dired-find-alternate-file 'disabled nil) ; disables warning
(define-key dired-mode-map (kbd "RET") 'dired-find-alternate-file) ; was dired-advertised-find-file
(define-key dired-mode-map (kbd "^") (lambda () (interactive) (find-alternate-file "..")))  ; was dired-up-directory

(defun tim/take-me-home ()
  (interactive)
  (if (looking-back "/" nil)
      (progn (call-interactively 'delete-minibuffer-contents) (insert "~/"))
    (call-interactively 'self-insert-command)))

(use-package vertico
  :defer t
  :bind (:map vertico-map ("~" . tim/take-me-home))
  :config
  (vertico-mode)
  (vertico-multiform-mode)
  (setq read-extended-command-predicate       'command-completion-default-include-p
        vertico-count                         32  ; Show more candidates
        read-file-name-completion-ignore-case t   ; Ignore case of file names
        read-buffer-completion-ignore-case    t   ; Ignore case in buffer completion
        completion-ignore-case                t)) ; Ignore case in completion

(use-package vertico-posframe
  :init
  (setq vertico-posframe-parameters   '((left-fringe  . 12)    ;; Fringes
                                        (right-fringe . 12)
                                        (undecorated  . nil))) ;; Rounded frame
  :config
  (vertico-posframe-mode 1)
  (setq vertico-posframe-width        96                       ;; Narrow frame
        vertico-posframe-height       vertico-count            ;; Default height
        ;; Don't create posframe for these commands
        vertico-multiform-commands    '((consult-line    (:not posframe))
                                        (consult-ripgrep (:not posframe)))))

(use-package corfu
  :defer t
  :custom
  (corfu-auto          t)
  (corfu-auto-delay    0.1)
  (corfu-auto-prefix   1)
  (corfu-cycle         t)
  (corfu-quit-no-match 'separator)
  :bind (:map corfu-map
              (" " . corfu-insert-separator)) ;; Option + Space on Norwegian Mac
  :init
  (global-corfu-mode))

(setq tab-always-indent 'complete)

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic partial-completion)
        completion-category-overrides '((file (styles basic partial-completion)))))

(use-package ripgrep
  :defer t)

(use-package rg
  :defer t)

;; (use-package ag
;;   :defer t)

(use-package wgrep
  :defer t)

(setq grep-command "rg -nS --no-heading "
      grep-use-null-device nil)

(use-package consult
  :bind (:map custom-bindings-map
              ("C-s"     . consult-line)
              ("C-M-s"   . consult-ripgrep)
              ("C-x b"   . consult-buffer)
              ("C-x C-b" . consult-buffer)
              ("M-g g"   . consult-goto-line)
              ("M-g t"   . consult-imenu)
              ("M-g a"   . consult-imenu-multi)))

(use-package imenu-list
  :defer t
  :bind (:map custom-bindings-map
              ("M-g i" . imenu-list-smart-toggle)))

(use-package marginalia
  :init 
  (marginalia-mode 1))

(use-package diff-hl
  :config
  (global-diff-hl-mode))

(use-package magit
  :defer t
  :bind (:map magit-mode-map
              ("C-M-f" . magit-section-forward)
              ("C-M-b" . magit-section-backward))
  :bind (:map custom-bindings-map
              ("M-g b" . magit-blame-addition))
  :hook
  ((magit-pre-refresh  . diff-hl-magit-pre-refresh)
   (magit-post-refresh . diff-hl-magit-post-refresh))
  :config
  (setq magit-mode-quit-window 'magit-restore-window-configuration
		magit-auto-revert-mode t)
  ; Remove tags from status buffer headings to speed up refresh slightly
  (remove-hook 'magit-status-sections-hook 'magit-insert-tags-header)
  ; Remove the "Head", "Merge", and "Push" status headers for even more speed!
  (remove-hook 'magit-status-sections-hook 'magit-insert-status-headers))

(use-package forge
  :after magit)

(use-package blamer
  :after magit
  :bind (("C-c g i" . blamer-show-commit-info)
         ("C-c g b" . blamer-show-posframe-commit-info))
  :defer 20
  :custom
  (blamer-idle-time                 0.3)
  (blamer-min-offset                4)
  (blamer-max-commit-message-length 100)
  (blamer-datetime-formatter        "[%s]")
  (blamer-commit-formatter          " ● %s")
  :custom-face
  (blamer-face ((t :foreground "#7aa2cf"
                    :background nil
                    :height 1
                    :italic nil))))

(use-package git-link
  :defer t
  :init
  (setq git-link-use-commit t
        git-link-open-in-browser t))

(use-package git-timemachine
  :defer t)

(use-package try)

(use-package yasnippet
  :diminish yas-minor-mode
  :defer 5
  :config
  (setq yas-snippet-dirs '("~/.emacs.d/snippets/"))
  (yas-global-mode 1)) ;; or M-x yas-reload-all if you've started YASnippet already.

;; Silences the warning when running a snippet with backticks (runs a command in the snippet)
(require 'warnings)
(add-to-list 'warning-suppress-types '(yasnippet backquote-change))

(use-package helpful
  :bind (:map custom-bindings-map
			  ("C-h f" . #'helpful-function)
			  ("C-h v" . #'helpful-variable)
			  ("C-h k" . #'helpful-key)
			  ("C-h x" . #'helpful-command)
			  ("C-h d" . #'helpful-at-point)
			  ("C-h c" . #'helpful-callable)))

(use-package which-key
  :config
  (which-key-mode))

(use-package jinx
  :hook (emacs-startup . global-jinx-mode)
  :bind (("<f7>"  . jinx-correct)
         ("C-'"   . jinx-correct)
         ("C-M-$" . jinx-languages))
  :config
  (setq jinx-languages "en_GB"))

(use-package auctex
  :hook
  (LaTeX-mode . turn-on-prettify-symbols-mode)
  (LaTeX-mode . reftex-mode)
  (LaTeX-mode . outline-minor-mode)
  (LaTeX-mode . olivetti-mode))

(setq reftex-toc-split-windows-horizontally t
	  reftex-toc-split-windows-fraction     0.2)

(use-package pdf-tools
  :defer t
  :init (pdf-loader-install)
  :hook ((pdf-view-mode . (lambda () (auto-revert-mode -1)))
         (pdf-view-mode . (lambda () (company-mode -1))))
  :bind (:map pdf-view-mode-map
              ("C-s"   . isearch-forward)
              ("C-M-s" . pdf-occur)))

(use-package doc-view
  :hook (doc-view-mode . (lambda ()
                           (display-warning
                            emacs
                            "Oops, using DocView instead of PDF Tools!"
                            :warning))))

(use-package pdf-view-restore
  :after pdf-tools
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode))

(use-package nov
  :defer t
  :config
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode)))

(use-package editorconfig
  :defer t)

(use-package elfeed
  :bind (:map custom-bindings-map ("C-x w" . elfeed))
  :config
  (setq elfeed-feeds
      '("http://nullprogram.com/feed/"
        "https://planet.emacslife.com/atom.xml"
        "https://deniskyashif.com/index.xml"
        "https://sophiebos.io/index.xml")))

(use-package esup
  :defer t
  :config
  (setq esup-depth 0))

(use-package org
  :defer t

:hook (org-mode . olivetti-mode)

:config
;; Resize Org headings
(custom-set-faces
'(org-document-title ((t (:height 1.6))))
'(outline-1          ((t (:height 1.25))))
'(outline-2          ((t (:height 1.2))))
'(outline-3          ((t (:height 1.2))))
'(outline-4          ((t (:height 1.2))))
'(outline-5          ((t (:height 1.2))))
'(outline-6          ((t (:height 1.2))))
'(outline-7          ((t (:height 1.2))))
'(outline-8          ((t (:height 1.2))))
'(outline-9          ((t (:height 1.2)))))

(org-indent-mode -1)

(setq org-startup-with-latex-preview t)

(plist-put org-format-latex-options :scale 1.35)

(let ((png (cdr (assoc 'dvipng org-preview-latex-process-alist))))
    (plist-put png :latex-compiler '("latex -interaction nonstopmode -output-directory %o %F"))
    (plist-put png :image-converter '("dvipng -D %D -T tight -o %O %F"))
    (plist-put png :transparent-image-converter '("dvipng -D %D -T tight -bg Transparent -o %O %F")))

(setq org-startup-folded 'content)

(setq org-hide-leading-stars t
      org-pretty-entities t
      org-ellipsis "  ·")

(setq org-src-fontify-natively t
      org-src-tab-acts-natively t
      org-edit-src-content-indentation 0)

(setq org-log-done                       t
      org-auto-align-tags                t
      org-tags-column                    -80
      org-fold-catch-invisible-edits     'show-and-error
      org-special-ctrl-a/e               t
      org-insert-heading-respect-content t)

)

(use-package org-appear
  :commands (org-appear-mode)
  :hook     (org-mode . org-appear-mode)
  :config 
  (setq org-hide-emphasis-markers t)  ;; Must be activated for org-appear to work
  (setq org-appear-autoemphasis   t   ;; Show bold, italics, verbatim, etc.
        org-appear-autolinks      t   ;; Show links
        org-appear-autosubmarkers t)) ;; Show sub- and superscripts

(setq org-startup-with-inline-images t)

(add-hook 'org-mode-hook 'variable-pitch-mode)

(use-package org-fragtog
  :after org
  :hook (org-mode . org-fragtog-mode))

(use-package org-superstar
  :after org
  :config
  (setq org-superstar-leading-bullet " ")
  (setq org-superstar-headline-bullets-list '("◆" "◇" "•" "⚬" "●" "○"))
  (setq org-superstar-special-todo-items t)        ;; Makes TODO header bullets into boxes
  (setq org-superstar-todo-bullet-alist '(("TODO"     . 9744)
                                          ("PROG"     . 9744)
                                          ("NEXT"     . 9744)
                                          ("WAIT"     . 9744)
                                          ("DROP"     . 9744)
                                          ("QUESTION" . 9744)
                                          ("DONE"     . 9745)))
  :hook (org-mode . org-superstar-mode))

(use-package svg-tag-mode
  :after org
  :config
  (defconst date-re "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}")
  (defconst time-re "[0-9]\\{2\\}:[0-9]\\{2\\}")
  (defconst day-re "[A-Za-z]\\{3\\}")
  (defconst day-time-re (format "\\(%s\\)? ?\\(%s\\)?" day-re time-re))

  (defun svg-progress-percent (value)
	(svg-image (svg-lib-concat
				(svg-lib-progress-bar (/ (string-to-number value) 100.0)
			      nil :margin 0 :stroke 2 :radius 3 :padding 2 :width 11)
				(svg-lib-tag (concat value "%")
				  nil :stroke 0 :margin 0)) :ascent 'center))

  (defun svg-progress-count (value)
	(let* ((seq (mapcar #'string-to-number (split-string value "/")))
           (count (float (car seq)))
           (total (float (cadr seq))))
	  (svg-image (svg-lib-concat
				  (svg-lib-progress-bar (/ count total) nil
					:margin 0 :stroke 2 :radius 3 :padding 2 :width 11)
				  (svg-lib-tag value nil
					:stroke 0 :margin 0)) :ascent 'center)))
  (setq svg-tag-tags
      `(;; Org tags
        ;; (":\\([A-Za-z0-9]+\\)" . ((lambda (tag) (svg-tag-make tag))))
        ;; (":\\([A-Za-z0-9]+[ \-]\\)" . ((lambda (tag) tag)))
        
        ;; Task priority
        ("\\[#[A-Z]\\]" . ( (lambda (tag)
                              (svg-tag-make tag :face 'org-priority 
                                            :beg 2 :end -1 :margin 0))))

        ;; Progress
        ("\\(\\[[0-9]\\{1,3\\}%\\]\\)" . ((lambda (tag)
          (svg-progress-percent (substring tag 1 -2)))))
        ("\\(\\[[0-9]+/[0-9]+\\]\\)" . ((lambda (tag)
          (svg-progress-count (substring tag 1 -1)))))
        
        ;; TODO / DONE
        ;; ("TODO" . ((lambda (tag) (svg-tag-make "TODO" :face 'org-todo
		;; 									           :inverse t :margin 0))))
        ;; ("DONE" . ((lambda (tag) (svg-tag-make "DONE" :face 'org-done :margin 0))))


        ;; Citation of the form [cite:@Knuth:1984] 
        ("\\(\\[cite:@[A-Za-z]+:\\)" . ((lambda (tag)
                                          (svg-tag-make tag
                                                        :inverse t
                                                        :beg 7 :end -1
                                                        :crop-right t))))
        ("\\[cite:@[A-Za-z]+:\\([0-9]+\\]\\)" . ((lambda (tag)
                                                (svg-tag-make tag
                                                              :end -1
                                                              :crop-left t))))

        
        ;; Active date (with or without day name, with or without time)
        (,(format "\\(<%s>\\)" date-re) .
         ((lambda (tag)
            (svg-tag-make tag :beg 1 :end -1 :margin 0))))
        (,(format "\\(<%s \\)%s>" date-re day-time-re) .
         ((lambda (tag)
            (svg-tag-make tag :beg 1 :inverse nil :crop-right t :margin 0))))
        (,(format "<%s \\(%s>\\)" date-re day-time-re) .
         ((lambda (tag)
            (svg-tag-make tag :end -1 :inverse t :crop-left t :margin 0))))

        ;; Inactive date  (with or without day name, with or without time)
         (,(format "\\(\\[%s\\]\\)" date-re) .
          ((lambda (tag)
             (svg-tag-make tag :beg 1 :end -1 :margin 0 :face 'org-date))))
         (,(format "\\(\\[%s \\)%s\\]" date-re day-time-re) .
          ((lambda (tag)
             (svg-tag-make tag :beg 1 :inverse nil :crop-right t :margin 0 :face 'org-date))))
         (,(format "\\[%s \\(%s\\]\\)" date-re day-time-re) .
          ((lambda (tag)
             (svg-tag-make tag :end -1 :inverse t :crop-left t :margin 0 :face 'org-date)))))))

(add-hook 'org-mode-hook 'svg-tag-mode)

(defun tim/prettify-symbols-setup ()
  "Beautify keywords"
  (interactive)
  (setq prettify-symbols-alist
		(mapcan (lambda (x)
                  (when (and (consp x) (stringp (car x)))
                    (list x (cons (upcase (car x)) (cdr x)))))
				'(; Greek symbols
				  ("lambda" . ?λ)
				  ("delta"  . ?Δ)
				  ("gamma"  . ?Γ)
				  ("phi"    . ?φ)
				  ("psi"    . ?ψ)
                  ; Org headers
				  ("#+title:"  . ? )
				  ("#+author:" . ? )
                  ("#+date:"   . ? )                
                  ; Checkboxes
				  ("[ ]" . ?)
				  ("[X]" . ?)
				  ("[-]" . ?)
                  ; Misc
                  ("->" . ?➜)
                  ; Blocks
				  ("#+begin_src"   . ?) ; 
				  ("#+end_src"     . ?)
				  ("#+begin_QUOTE" . ?‟)
				  ("#+end_QUOTE"   . ?”)
                  ; Drawers
				  (":properties:" . ?)
                  ; Agenda scheduling
				  ("SCHEDULED:"   . ?🕘)
				  ("DEADLINE:"    . ?⏰)
                  ; Agenda tags  
				  (":@projects:"  . ?☕)
				  (":work:"       . ?🚀)
				  (":@inbox:"     . ?✉)
				  (":goal:"       . ?🎯)
				  (":task:"       . ?📋)
				  (":@thesis:"    . ?📝)
				  (":thesis:"     . ?📝)
				  (":emacs:"      . ?)
				  (":learn:"      . ?🌱)
				  (":code:"       . ?💻)
				  (":fix:"        . ?🛠)
				  (":bug:"        . ?🚩)
				  (":read:"       . ?📚)
                  ; Roam tags
				  ("#+filetags:"  . ?📎)
				  (":wip:"        . ?🏗)
				  (":ct:"         . ?➡)    ; Category Theory
                  (":verb:"       . ?🌐) ; HTTP Requests in Org mode
                  )))
  (prettify-symbols-mode))

(add-hook 'org-mode-hook        #'tim/prettify-symbols-setup)
(add-hook 'org-agenda-mode-hook #'tim/prettify-symbols-setup)

(add-to-list 'font-lock-extra-managed-props 'display)
(font-lock-add-keywords 'org-mode
                        `(("^.*?\\( \\)\\(:[[:alnum:]_@#%:]+:\\)$"
                           (1 `(face nil
                                     display (space :align-to (- right ,(org-string-width (match-string 2)) 3)))
                              prepend))) t)

(add-hook 'org-mode-hook #'(lambda () (electric-indent-local-mode -1)))

(setq org-return-follows-link t)

(setq org-blank-before-new-entry '((heading . nil)
                                   (plain-list-item . nil)))

(setq org-agenda-start-on-weekday nil
      org-agenda-block-separator  nil
      org-agenda-remove-tags      t)

(use-package org-super-agenda
  :after org
  :config
  (setq org-super-agenda-header-prefix "\n❯ ")
  ;; Hide the thin width char glyph
  (add-hook 'org-agenda-mode-hook
            #'(lambda () (setq-local nobreak-char-display nil)))
  (org-super-agenda-mode))

;; Delete default agenda commands
(setq org-agenda-custom-commands nil)

(defvar regular-view-groups
  '((:name "Scheduled"
     :scheduled t
     :order 1)
	(:name "Deadlines"
     :deadline t
     :order 2)))

(add-to-list 'org-agenda-custom-commands
	  '("d" "Day View"
		 ((agenda "" ((org-agenda-overriding-header "Day View")
                      (org-agenda-span 'day)
                      (org-super-agenda-groups regular-view-groups)))
		  (org-ql-block '(todo "PROG") ((org-ql-block-header "\n❯ In Progress")))
		  (org-ql-block '(todo "NEXT") ((org-ql-block-header "\n❯ Next Up")))
          (org-ql-block '(todo "WAIT") ((org-ql-block-header "\n❯ Backlog")))
		  (org-ql-block '(priority "A") ((org-ql-block-header "\n❯ Important"))))))


(add-to-list 'org-agenda-custom-commands
		'("e" "Three-Day View"
               ((agenda "" ((org-agenda-span 3)
                            (org-agenda-start-on-weekday nil)
                            (org-deadline-warning-days 0))))))

(setq org-agenda-skip-deadline-if-done  t
	  org-agenda-skip-scheduled-if-done t)

(setq org-agenda-deadline-leaders '("Deadline:  " "In %2d d.: " "%2d d. ago: "))

(setq org-lowest-priority  ?F) ;; Gives us priorities A through F
(setq org-default-priority ?E) ;; If an item has no priority, it is considered [#E].

(setq org-priority-faces
      '((65 . "#BF616A")
        (66 . "#EBCB8B")
        (67 . "#B48EAD")
        (68 . "#81A1C1")
        (69 . "#5E81AC")
        (70 . "#4C566A")))

(setq org-todo-keywords
      '((sequence
         ;; Needs further action
		 "TODO(t)" "PROG(p)" "NEXT(n)" "WAIT(w)" "QUESTION(q) DROP(x)"
		 "|"
         ;; Needs no action currently
		 "DONE(d)")))

(defun org-mark-as-done ()
  (interactive)
  (save-excursion
    (org-back-to-heading t) ;; Make sure command works even if point is
                            ;; below target heading
    (cond ((looking-at "\*+ TODO")
           (org-todo "DONE"))
		  ((looking-at "\*+ NEXT")
           (org-todo "DONE"))
          ((looking-at "\*+ WAIT")
           (org-todo "DONE"))
		  ((looking-at "\*+ PROG")
           (org-todo "DONE"))
		  ((looking-at "\*+ DROP")
           (org-todo "DONE"))
		  ((looking-at "\*+ DROP")
           (org-todo "QUESTION"))
		  ((looking-at "\*+ DONE")
           (org-todo "DONE"))
          (t (message "Undefined TODO state.")))))

(use-package hide-lines
  :vc (:url "https://github.com/vapniks/hide-lines.git"
       :branch "master"
       :rev :newest))

(defun hide-done-tasks ()
  (interactive)
  (hide-lines-matching "* DONE"))

(defun show-done-tasks ()
  (interactive)
  (hide-lines-show-all))

(setq org-directory "~/org/")
(add-to-list 'org-agenda-files "inbox.org")

(setq org-archive-location (concat org-directory "archive.org::"))

(setq org-capture-templates
       `(("i" "Inbox" entry  (file "inbox.org")
        ,(concat "* TODO %?\n"
                 "/Entered on/ %U"))))
(defun org-capture-inbox ()
     (interactive)
     (call-interactively 'org-store-link)
     (org-capture nil "i"))

(define-key custom-bindings-map (kbd "C-c l") 'org-store-link)
(define-key custom-bindings-map (kbd "C-c a") 'org-agenda)
(define-key custom-bindings-map (kbd "C-c c") 'org-capture)

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c t") 'org-todo)
  (define-key org-mode-map (kbd "C-c d") 'org-mark-as-done))

(set-register ?i (cons 'file (concat org-directory "inbox.org")))
(set-register ?r (cons 'file (concat org-directory "roam/20240128135100-roam.org")))
(set-register ?p (cons 'file (concat org-directory "projects.org")))
(set-register ?c (cons 'file "~/Dropbox/playground/clj-playground/src/clj_playground/playground.clj"))
(set-register ?b (cons 'file "~/Dropbox/projects/blog/org-content/all-posts.org"))

(define-key custom-bindings-map (kbd "C-r") 'jump-to-register)

(setq org-export-use-babel       nil
      org-confirm-babel-evaluate nil)
;; (org-babel-do-load-languages
;;  'org-babel-load-languages
;;  '((emacs-lisp . t)
;;    (python     . t)
;;    (haskell    . t)
;;    (clojure    . t)))

(use-package ob-python
  :ensure nil
  :after (ob python)
  :config
  (setq org-babel-python-command python-shell-interpreter))

(use-package ox-hugo
  :after org)

(with-eval-after-load 'org-capture
  (defun org-hugo-new-subtree-post-capture-template ()
    "Returns `org-capture' template string for new Hugo post.
See `org-capture-templates' for more information."
    (let* ((title (read-from-minibuffer "Post Title: "))
           (fname (org-hugo-slug title)))
      (mapconcat #'identity
                 `(
                   ,(concat "* TODO " title)
                   ":PROPERTIES:"
                   ,(concat ":EXPORT_FILE_NAME: " fname)
                   ":END:"
                   "%?\n")          ;Place the cursor here finally
                 "\n")))

  (add-to-list 'org-capture-templates
               '("h"                ;`org-capture' binding + h
                 "Hugo post"
                 entry
                 (file+olp "all-posts.org" "Blog Posts")
                 (function org-hugo-new-subtree-post-capture-template))))

(defun tim/org-present-prepare-slide ()
  ;; Show only top-level headlines
  (org-overview)
  ;; Unfold the current entry
  (org-fold-show-entry)
  ;; Show only direct subheadings of the slide but don't expand them
  (org-fold-show-children))

(defun tim/org-present-start ()
  ;; Tweak font sizes
  (setq-local
   face-remapping-alist '((default (:height 1.5) variable-pitch)
                          (header-line (:height 3.0) variable-pitch)
                          (org-document-title (:height 1.75) org-document-title)
                          (org-code (:height 1.55) org-code)
                          (org-verbatim (:height 1.55) org-verbatim)
                          (org-block (:height 1.25) org-block)
                          (org-block-begin-line (:height 0.7) org-block)))
  ;; Set a blank header line string to create blank space at the top
  (setq header-line-format " "))

(defun tim/org-present-end ()
  ;; Reset font customizations
  (setq-local face-remapping-alist '((default variable-pitch default)))
  ;; Clear the header line string so that it isn't displayed
  (setq header-line-format nil))


(use-package org-present
  :defer t
  :hook
  ((org-present-after-navigate-functions . tim/org-present-prepare-slide)
  (org-present-mode                      . tim/org-present-start)
  (org-present-mode-quit                 . tim/org-present-end)))

(use-package org-download
  :after org
  :bind
  (:map org-mode-map
        (("s-t" . org-download-screenshot)
         ("s-y" . org-download-clipboard))))

(use-package toc-org
  :after org
  :config
  (add-hook 'org-mode-hook 'toc-org-mode)

  ;; enable in markdown, too
  (add-hook 'markdown-mode-hook 'toc-org-mode))

(add-hook 'prog-mode-hook 'subword-mode)

(electric-pair-mode 1)

(use-package hl-todo
    :hook (prog-mode . hl-todo-mode)
    :config
    (setq hl-todo-highlight-punctuation ":"
          hl-todo-keyword-faces
          `(("TODO"       font-lock-keyword-face  bold)
            ("FIXME"      error                   bold)
            ("HACK"       font-lock-constant-face bold)
            ("REVIEW"     font-lock-keyword-face  bold)
            ("NOTE"       success                 bold)
            ("DEPRECATED" font-lock-doc-face      bold))))

(use-package markdown-mode
  :defer t)

(global-unset-key (kbd "M--"))

(use-package flycheck
  :defer t
  :init (global-flycheck-mode)
  :bind (:map flycheck-mode-map
              ("M-- -"    . flycheck-explain-error-at-point)
              ("M-- M--"  . flycheck-explain-error-at-point)
              ("M-- ?"    . flycheck-describe-checker)
              ("M-- C"    . flycheck-clear)
              ("M-- C-c"  . flycheck-compile)
              ("M-- C-w"  . flycheck-copy-errors-as-kill)
              ("M-- H"    . display-local-help)
              ("M-- V"    . flycheck-version)
              ("M-- c"    . flycheck-buffer)
              ("M-- e"    . flycheck-explain-error-at-point)
              ("M-- h"    . flycheck-display-error-at-point)
              ("M-- i"    . flycheck-manual)
              ("M-- l"    . flycheck-list-errors)
              ("M-- n"    . flycheck-next-error)
              ("M-- p"    . flycheck-previous-error)
              ("M-- s"    . flycheck-select-checker)
              ("M-- v"    . flycheck-verify-setup)
              ("M-- x"    . flycheck-disable-checker))
  :config (setq flycheck-display-errors-function #'ignore))

(use-package eldoc
  :defer t
  :config
  (global-eldoc-mode))

(use-package consult-xref-stack
  :vc
  (:url "https://github.com/brett-lempereur/consult-xref-stack" :branch "main")
  :bind (:map custom-bindings-map
              ("C-," . consult-xref-stack-backward)
              ("C-." . consult-xref-stack-forward)))

(use-package verb
  :after org
  :config
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))

(use-package treesit
  :ensure nil
  :mode (("\\.mjs\\'" . typescript-ts-mode)
         ("\\.mts\\'" . typescript-ts-mode)
         ("\\.cjs\\'" . typescript-ts-mode)
         ("\\.json\\'" .  json-ts-mode)
         ("\\.Dockerfile\\'" . dockerfile-ts-mode)
         ("\\.prisma\\'" . prisma-ts-mode))
  :preface
  (defun os/setup-install-grammars ()
    "Install Tree-sitter grammars if they are absent."
    (interactive)
    (dolist (grammar
             '((css . ("https://github.com/tree-sitter/tree-sitter-css" "v0.20.0"))
               (bash "https://github.com/tree-sitter/tree-sitter-bash")
               (html . ("https://github.com/tree-sitter/tree-sitter-html" "v0.20.1"))
               (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript" "v0.21.2" "src"))
               (json . ("https://github.com/tree-sitter/tree-sitter-json" "v0.20.2"))
               (python . ("https://github.com/tree-sitter/tree-sitter-python" "v0.20.4"))
               (go "https://github.com/tree-sitter/tree-sitter-go" "v0.20.0")
               (markdown "https://github.com/ikatyang/tree-sitter-markdown")
               (make "https://github.com/alemuller/tree-sitter-make")
               (elisp "https://github.com/Wilfred/tree-sitter-elisp")
               (cmake "https://github.com/uyha/tree-sitter-cmake")
               (c "https://github.com/tree-sitter/tree-sitter-c")
               (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
               (toml "https://github.com/tree-sitter/tree-sitter-toml")
               (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "tsx/src"))
               (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "v0.20.3" "typescript/src"))
               (yaml . ("https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0"))
               (prisma "https://github.com/victorhqc/tree-sitter-prisma")))
      (add-to-list 'treesit-language-source-alist grammar)
      ;; Only install `grammar' if we don't already have it
      ;; installed. However, if you want to *update* a grammar then
      ;; this obviously prevents that from happening.
      (unless (treesit-language-available-p (car grammar))
        (treesit-install-language-grammar (car grammar)))))

  ;; Optional, but recommended. Tree-sitter enabled major modes are
  ;; distinct from their ordinary counterparts.
  ;;
  ;; You can remap major modes with `major-mode-remap-alist'. Note
  ;; that this does *not* extend to hooks! Make sure you migrate them
  ;; also
  (dolist (mapping
           '((typescript-mode . typescript-ts-mode)
             (js-mode . typescript-ts-mode)
             (js2-mode . typescript-ts-mode)
             (css-mode . css-ts-mode)
             (json-mode . json-ts-mode)
             (js-json-mode . json-ts-mode)))
    (add-to-list 'major-mode-remap-alist mapping))
  :config
  (os/setup-install-grammars))

(use-package lispy
  :defer t
  :config
  (setcdr lispy-mode-map nil)
  :commands
  lispy-different
  lispy-clone
  lispy-comment
  lispy-move-up
  lispy-mode-down)

(use-package smartparens
  :hook ((prog-mode        . smartparens-mode)
         (text-mode        . smartparens-mode)
         (markdown-mode    . smartparens-mode)
         (smartparens-mode . (lambda () (electric-pair-local-mode -1))))
  :config
  (require 'smartparens-config)
  ;; Don't highlight delimiters when created
  (setq sp-highlight-pair-overlay     nil
        sp-highlight-wrap-overlay     nil
        sp-highlight-wrap-tag-overlay nil)
  :bind (:map smartparens-mode-map

              ;; Navigating
              ;; ("C-f"         . sp-forward-sexp)
              ;; ("C-b"         . sp-backward-sexp)
              ("M-A"         . sp-beginning-of-sexp)
              ("M-E"         . sp-end-of-sexp)
              ("C-M-f"       . sp-up-sexp)
              ("C-M-b"       . sp-backward-up-sexp)

              ;; Slurping & barfing
              ;; ("C-<right>"   . sp-forward-slurp-sexp)
              ;; ("C-<left>"    . sp-forward-barf-sexp)
              ("C-M-<right>" . sp-backward-barf-sexp)
              ("C-M-<left>"  . sp-backward-slurp-sexp)

              ;; Manipulating
              ("C-k"         . sp-kill-sexp)
              ("M-s"         . sp-splice-sexp)
              ("M-r"         . sp-raise-sexp)
              ;; ("M-<up>"      . sp-splice-sexp-killing-backward)
              ;; ("M-<down>"    . sp-splice-sexp-killing-forward)
              ("C-M-t"       . sp-transpose-sexp)
              ("M-?"         . sp-convolute-sexp)
              ("M-S"         . sp-split-sexp)
              ("M-J"         . sp-join-sexp)

              ;; Functions from lispy
              ("M-d"         . lispy-different)
              ("M-c"         . lispy-clone)
              (";"           . lispy-comment)
              ("C-M-<up>"    . lispy-move-up)
              ("C-M-<down>"  . lispy-move-down)))

(use-package lsp-mode
  :defer t
  :init (setq lsp-use-plists t)
  :hook ((clojure-mode          . lsp)
         (clojurec-mode         . lsp)
         (lsp-mode              . lsp-enable-which-key-integration)
         (typescript-mode       . lsp)
         (tsx-ts-mode           . lsp)
         (typescript-ts-mode    . lsp)
         (web-mode              . lsp))
  :bind (:map lsp-mode-map
              ("M-<return>" . lsp-execute-code-action)
              ("C-M-."      . lsp-find-references)
              ("C-c r"      . lsp-rename))
  :config
  (setq lsp-diagnostics-provider :flycheck
        lsp-completion-provider  :none)       ;; I use corfu
  ;; Disable visual features
  (setq lsp-headerline-breadcrumb-enable nil  ;; No breadcrumbs
        lsp-lens-enable                  nil  ;; No lenses

        ;; Enable code actions in the mode line
        lsp-modeline-code-actions-enable t
        lsp-modeline-code-action-fallback-icon "✦"

        ;; Limit raising of the echo area to show docs
        lsp-signature-doc-lines 3)
  (setq lsp-file-watch-threshold  1500)
  (setq lsp-format-buffer-on-save nil)

  (with-eval-after-load 'lsp-modeline
    (set-face-attribute 'lsp-modeline-code-actions-preferred-face nil
                        :inherit 'font-lock-comment-face)
    (set-face-attribute 'lsp-modeline-code-actions-face nil
                        :inherit 'font-lock-comment-face)))

(use-package lsp-ui
  :after lsp-mode
  :config
  (setq lsp-ui-sideline-enable nil
        lsp-ui-doc-enable      nil))

(use-package lsp-treemacs
  :after lsp-mode
  :bind (:map lsp-mode-map
              ("C-c ." . lsp-treemacs-references)
              ("C-c :" . lsp-treemacs-call-hierarchy)))

(use-package origami
  :defer t
  :hook (prog-mode . origami-mode)
  :bind (:map origami-mode-map
              ("M-z" . origami-toggle-node)))

(use-package lsp-origami
  :after lsp
  :hook (lsp-mode . lsp-origami-try-enable))

(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))
(advice-add (if (progn (require 'json)
                       (fboundp 'json-parse-buffer))
                'json-parse-buffer
              'json-read)
            :around
            #'lsp-booster--advice-json-parse)

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             ;; for check lsp-server-present?
             (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command, it would add extra shell wrapper
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ;; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let ((command-from-exec-path (executable-find (car orig-result))))  ;; resolve command from exec-path (in case not found in $PATH)
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))
(advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)

(use-package dash
  :defer t)

(use-package s
  :defer t)

(use-package f
  :defer t)

(use-package eros
  :defer t
  :functions
  eros-mode
  eros-eval-defun
  :bind (:map emacs-lisp-mode-map
              ("C-c C-c" . eros-eval-defun)
              ("C-c C-k" . eval-buffer))
  :config
  (eros-mode 1))

(use-package emacs
  :hook (emacs-lisp-mode . lispy-mode))

(use-package python
  :interpreter ("python3" . python-mode)
  :defer t
  :config
  (setq python-shell-interpreter "python3.11")
  (add-hook 'python-mode
   		 (lambda () (setq forward-sexp-function nil))))

(define-key custom-bindings-map (kbd "C-c b") 'ibuffer)

(define-key custom-bindings-map (kbd "C-c u") 'revert-buffer)

(define-minor-mode custom-bindings-mode
  "A mode that activates custom keybindings."
  :init-value t
  :keymap custom-bindings-map)
