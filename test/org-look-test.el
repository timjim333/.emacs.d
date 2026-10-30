;;; org-look-test.el --- Item 5 round 5 tests -*- lexical-binding: t -*-

;; Author: Tim Jim
;; Date: 2026-10-30

;;; Commentary:

;; Presentation and look: the light and dark themes, ligatures, casual
;; menus, org-present, and focus.  Run it with
;; `test/gui-ert test/org-look-test.el', so it sees the full config in
;; a real frame.

;;; Code:

(require 'ert)
(require 'org)
(require 'cl-lib)

(defmacro tim/test-in-window (mode text &rest body)
  "Run BODY in a buffer in MODE holding TEXT, shown in the selected window."
  (declare (indent 2))
  `(let ((buf (generate-new-buffer "*look-test*")))
     (unwind-protect
         (progn
           (switch-to-buffer buf)
           (insert ,text)
           (funcall ,mode)
           (goto-char (point-min))
           (redisplay t)
           ,@body)
       (kill-buffer buf))))

(defmacro tim/test-with-text-scale-limit (&rest body)
  "Run BODY with a sane text-scale limit even when the monitor sleeps.
Asleep, it reports no monitors, so `display-pixel-width' is 0 and
`text-scale-increase' refuses every change."
  (declare (indent 0))
  `(if (> (display-pixel-width) 0)
       (progn ,@body)
     (cl-letf (((symbol-function 'text-scale-max-amount) (lambda () 20)))
       ,@body)))

(defun tim/test-transient-shown-p ()
  "Return non-nil if a transient menu is showing, then close it."
  (prog1 (and transient--prefix
              (get-buffer-window transient--buffer-name t))
    (transient-quit-all)))

;; Test (a): the switch itself.  Following KDE is checked at the screen.
(ert-deftest tim/look-theme-follows-toolkit ()
  "The toolkit theme hook loads doom-nord-light or doom-nord."
  (should (memq 'tim/apply-toolkit-theme toolkit-theme-set-functions))
  (unwind-protect
      (progn
        (run-hook-with-args 'toolkit-theme-set-functions 'light)
        (should (equal custom-enabled-themes '(doom-nord-light)))
        (run-hook-with-args 'toolkit-theme-set-functions 'dark)
        (should (equal custom-enabled-themes '(doom-nord))))
    (tim/apply-toolkit-theme (or toolkit-theme 'dark))))

;; A daemon's first frame, started in light mode, takes this path.
(ert-deftest tim/look-new-frame-applies-toolkit-theme ()
  "Opening a frame runs the toolkit theme hook, so a theme out of step
with the desktop is put right."
  (skip-unless toolkit-theme)
  (let* ((mode toolkit-theme)
         (wrong (if (eq mode 'light) 'dark 'light))
         (seen nil)
         (record (lambda (m) (push m seen)))
         frame)
    (add-hook 'toolkit-theme-set-functions record)
    (unwind-protect
        (progn
          (tim/apply-toolkit-theme wrong)
          (setq frame (make-frame))
          ;; GTK queues the event as the frame is made; reading input
          ;; runs the hook.
          (with-timeout (5 nil)
            (while (not seen) (read-event nil nil 0.1)))
          (should (equal seen (list mode)))
          (should (equal custom-enabled-themes
                         (list (if (eq mode 'light) 'doom-nord-light
                                 'doom-nord)))))
      (remove-hook 'toolkit-theme-set-functions record)
      (when (frame-live-p frame) (delete-frame frame))
      (tim/apply-toolkit-theme mode))))

;; Test (b)
(ert-deftest tim/look-ligatures-in-python ()
  "-> and != are composed in a Python buffer."
  (tim/test-in-window #'python-mode "def f(a) -> bool:\n    return a != 1\n"
    (dolist (lig '("->" "!="))
      (goto-char (point-min))
      (search-forward lig)
      (should (find-composition (match-beginning 0) nil nil t)))))

;; Test (c)
(ert-deftest tim/look-casual-dired ()
  "C-o in Dired opens casual's menu."
  (let ((buf (dired-noselect temporary-file-directory)))
    (unwind-protect
        (progn
          (switch-to-buffer buf)
          (call-interactively (keymap-lookup dired-mode-map "C-o"))
          (should (tim/test-transient-shown-p)))
      (kill-buffer buf))))

(ert-deftest tim/look-casual-agenda ()
  "C-o in an (empty) agenda opens casual's menu."
  (let* ((file (make-temp-file "look-test" nil ".org" "* Nothing\n"))
         (org-agenda-files (list file)))
    (unwind-protect
        (progn
          (org-agenda-list)
          (call-interactively (keymap-lookup org-agenda-mode-map "C-o"))
          (should (tim/test-transient-shown-p)))
      (org-agenda-quit)
      (when-let* ((b (find-buffer-visiting file))) (kill-buffer b))
      (delete-file file))))

;; Test (d)
(ert-deftest tim/look-org-present-steps ()
  "org-present shows one heading at a time and restores the buffer."
  (tim/test-in-window #'org-mode "* One\nfirst\n* Two\nsecond\n"
    (tim/test-with-text-scale-limit
      (org-present))
    (unwind-protect
        (progn
          (should (string-prefix-p "* One" (buffer-string)))
          (should-not (string-search "Two" (buffer-string)))
          (org-present-next)
          (should (string-prefix-p "* Two" (buffer-string))))
      (tim/test-with-text-scale-limit
        (org-present-quit)))
    (should (string-search "* One" (buffer-string)))
    (should-not buffer-read-only)))

;; Test (e)
(ert-deftest tim/look-focus-dims-other-paragraphs ()
  "focus-mode dims every paragraph but the one at point."
  (tim/test-in-window #'text-mode "First paragraph.\n\nSecond paragraph.\n"
    (focus-mode 1)
    ;; Focus moves its overlays from `post-command-hook'.
    (run-hooks 'post-command-hook)
    (unwind-protect
        (let ((dimmed (lambda (pos)
                        (seq-some (lambda (ov)
                                    (eq (overlay-get ov 'face)
                                        'focus-unfocused))
                                  (overlays-at pos)))))
          (should-not (funcall dimmed 3))
          (should (funcall dimmed (- (point-max) 3))))
      (focus-mode 0))))

;;; org-look-test.el ends here
