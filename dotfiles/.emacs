;; Copy this file to $HOME/.emacs and edit as needed.

;; Ref: www.emacswiki.org
;;      www.linuxpowered.com/html/tutorials/emacs.html
;;      http://ergoemacs.org/emacs/elisp_basics.html

;; FAQ
;;
;; - increase font size: C-x X-+

;; Use:
;; 1. byte compile draco elisp: (cd ~/draco/environment/elisp; ./compile-elisp)
;; 2. byte compile this file.  From emacs: M-x byte-compile-file
;; 3. Set draco environment directory:
(defvar my-draco-env-dir "~/draco/environment/")
;; 4. Update customizations found in this file

;;------------------------------------------------------------------------------

;;
;; System information
;;
(defvar emacs-load-start-time (current-time))
(defconst linuxp
    (or (eq system-type 'gnu/linux)
        (eq system-type 'linux)) "Are we running on a GNU/Linux system?")
(defconst linux-x-p
    (and window-system 'linuxp) "Are we running under X on a GNU/Linux system?")
(defconst emacs>=24p (> emacs-major-version 23)
  "Are we running GNU Emacs 24 or above?")
(defvar emacs-debug-loading nil)

;;
;; Draco Environment
;;
(load-library (concat my-draco-env-dir "elisp/draco-setup"))
;;(setq draco_vendor_dir (getenv "VENDOR_DIR"))

;;---------------------------------------------------------------------------------------
;; Personal Settings below this line
;;---------------------------------------------------------------------------------------

;; ---------------------------------------------------------------------------
;; MELPA package manager
;; https://melpa.org/#/getting-started
;; https://github.com/atilaneves/cmake-ide
;;
;; package manager for emacs
;; M-x package-refresh-contents
;; M-x package-list-packages
;; M-x package install
(require 'package)
(add-to-list 'package-archives (cons "melpa"  "https://melpa.org/packages/") t)
;(add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
(package-initialize)

;; Useful for Windows and Gnome/KDE users.  Note: Also enables
;; transient-mark-mode.  Turns on C-z, C-x, C-c C-v like windows.  Allow
;; Shift+arrow to select region.
;;(cua-mode t)  set below in (custom-set-variables ... )

;; this is the same title bar format all Gnome apps seem to use
(setq frame-title-format (list "[" (system-name) "] %b" ))

; Turn off warning:
(setq large-file-warning-threshold nil)

;; ediff settings
;; http://www.gnu.org/software/emacs/manual/html_mono/ediff.html#Window-and-Frame-Configuration
;; (setq ediff-narrow-control-frame-leftward-shift 20
;;       ediff-control-frame-upward-shift          40)

;; RefTeX
; (setq reftex-bibpath-environment-variables
;      '("BIBINPUTS" "TEXBIB" "!kpsewhich -show-path=.bib"))
;;       '("/home/kellyt/imcdoc/bib/"))

;; Automatically keep buffers synchronized with file system
;; (i.e. reload the buffer automatically if the file changes outside of emacs).
(global-auto-revert-mode t)

;; load symlinks w/o a question
(setq vc-follow-symlinks t)

;; Bind Alt as Meta
(setq x-alt-keysym 'meta)
;;(setq x-super-keysym 'meta) ;; Use Windows or penguin key as Meta.

;; Disable C-x C-z keybinding (suspend-frame)
(global-unset-key (kbd "C-x C-z"))

;; Email
(setq user-mail-address "kgt@lanl.gov")

;; Set the frame size base on the current resolution.
(when window-system (set-frame-size (selected-frame) 110 70))
;; (defun set-frame-size-according-to-resolution ()
;;   (interactive)
;;   (if window-system
;;       (progn
;;         ;; use 120 char wide window for largeish displays
;;         ;; and smaller 100 column windows for smaller displays
;;         ;; pick whatever numbers make sense for you.
;;         (defvar kt-emacs-width 100)
;;         (defvar kt-emacs-height 24)
;;         (if (> (x-display-pixel-height) 1100)
;;             (progn
;;               (setq kt-emacs-width 105)
;;               (setq kt-emacs-height 80)
;;               ;; Check that the height still fits on the monitor
;;               (setq max-emacs-height (/ (x-display-pixel-height)
;;                                         (frame-char-height) ))
;;               (if (> kt-emacs-height max-emacs-height)
;;                   (setq kt-emacs-height (- max-emacs-height 10)))

;;               ) ; progn
;;           ) ; endif

;;         (set-frame-size (selected-frame) kt-emacs-width
;;                         kt-emacs-height)
;;         )))
;; (set-frame-size-according-to-resolution)
;; (global-set-key [(shift f12)] 'set-frame-size-according-to-resolution)

;; Dired
(setq dired-listing-switches "-alh")
(setq dired-recursive-deletes t)

;; Allow 'emacsclient' to connect to running emacs.
(if 'window-system
    (require 'server)
    (progn
      (or (server-running-p) (server-start))
))

;; EDIFF customization
(setq ediff-window-setup-function 'ediff-setup-windows-plain)

;; GIT customizations
(add-to-list
 'auto-mode-alist
 '("/\\.git/\\(COMMIT\\|TAG\\)_EDITMSG\\'" . vcs-message-mode)
 '("svn-commit.msg" . vcs-message-mode)
 )

(define-derived-mode vcs-message-mode text-mode "VCS-message"
  "Major mode for editing commit and tag messages."
  (auto-fill-mode 1)
  (setq fill-prefix "  ")
  (set (make-local-variable 'tab-stop-list)
       (number-sequence 4 100 4))
  (setq indent-tabs-mode nil
        fill-column 100
        truncate-lines t))

(setq cursor-type '(bar . 2))
(setq fill-column 100)
;(setq draco-code-comment-width 132)

;; (add-hook 'c++-mode-hook
;;           (lambda () (modify-syntax-entry ?_ "w")))

;; ========================================
;; ANSI COLOR
;; - https://emacs.stackexchange.com/questions/24698/ansi-escape-sequences-in-compilation-mode
;; ========================================

(require 'ansi-color)
(defun display-ansi-colors ()
  (interactive)
  (ansi-color-apply-on-region (point-min) (point-max)))
(if (fboundp 'display-ansi-colors)
    (define-key text-mode-map [(f12)] 'display-ansi-colors))
(defun endless/colorize-compilation ()
  "Colorize from `compilation-filter-start' to `point'."
  (let ((inhibit-read-only t))
    (ansi-color-apply-on-region
     compilation-filter-start (point))))
(add-hook 'compilation-filter-hook 'endless/colorize-compilation)

;; ========================================
;; highlight-doxygen-mode
;; https://github.com/Lindydancer/highlight-doxygen
;; ========================================
(highlight-doxygen-global-mode 1)
;; font-lock-doc-face
;; highlight-doxygen-code-block
;; highlight-doxygen-comment



;; (defun draco-dos2unix ()
;;   "Convert line endings to Unix style, untabify, and indent-region by mode.
;; http://www.emacswiki.org/emacs/EndOfLineTips
;; Also C-x <ret> f utf-8-unix <ret>"
;;     (interactive)
;;     (set-fill-column 100)
;;     (progn
;;       (untabify (point-min) (point-max))
;;       (indent-region (point-min) (point-max))
;;       (add-hook 'before-save-hook 'delete-trailing-whitespace)
;;       (set-buffer-file-coding-system 'iso-latin-1-unix t)
;;       )
;;     )
; (define-key global-map [(f12)] 'draco-dos2unix)

; (require 'fill-column-indicator)
; fci-mode




;; ========================================
;; GNU Emacs Custom settings
;; ========================================

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(column-number-mode t)
 '(compilation-auto-jump-to-first-error nil)
 '(compilation-scroll-output (quote first-error))
 '(cua-mode t nil (cua-base))
 '(draco-code-comment-width 100)
 '(draco-elisp-dir "/home/kellyt/draco/environment/elisp/")
 '(draco-env-dir "/home/kellyt/draco/environment/")
 '(font-lock-maximum-decoration t)
 '(global-font-lock-mode t nil (font-lock))
 '(inhibit-startup-screen t)
 '(package-selected-packages
   (quote
    (magit highlight-doxygen lua-mode ansi yaml-mode cmake-mode)))
 '(ring-bell-function (quote ignore))
 '(scroll-bar-mode (quote right))
 '(show-paren-mode t nil (paren))
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify)))
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style (quote forward) nil (uniquify)))

;; '(default ((t (:inherit nil :stipple nil :background "ivory" :foreground "black" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 98 :width semi-condensed :family "Fixed" :foundry "Misc"))))

 ;; '(default ((t (:family "Fixed" :foundry "Misc" :slant
 ;;                        normal :weight normal :height 98 :width
 ;;                        normal :background "ivory" )))))

;; wikipedia.org/wiki/X11_color_names
;; (setq load-home-init-file t) ; don't load init file from ~/.xemacs/init.el

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((((type tty))) (t (:inherit nil :stipple nil :background "ivory" :foreground "black"
                                        :inverse-video nil :box nil :strike-through nil :overline
                                        nil :underline nil :slant normal :weight normal :height 87
                                        :width medium :family "Inconsolata" :foundry "unknown"))))
 '(font-lock-comment-face ((((class color) (min-colors 88) (background light)) (:foreground "purple"))))
 '(font-lock-constant-face ((((class color) (min-colors 88) (background light)) (:foreground "CadetBlue"))))
 '(font-lock-doc-face ((t (:inherit font-lock-comment-face :foreground "peru"))))
 '(font-lock-function-name-face ((((class color) (min-colors 88) (background light)) (:foreground "Blue3"))))
 '(font-lock-keyword-face ((((class color) (min-colors 88) (background light)) (:foreground "firebrick2"))))
 '(font-lock-preprocessor-face ((t (:inherit font-lock-builtin-face :foreground "hotpink"))))
 '(font-lock-string-face ((((class color) (min-colors 88) (background light)) (:foreground "orange3"))))
 '(font-lock-variable-name-face ((((class color) (min-colors 88) (background light)) (:foreground "Royalblue"))))
 '(highlight-doxygen-code-block ((t nil)))
 '(highlight-doxygen-comment ((t (:inherit font-lock-comment-face))))
 '(menu ((((type x-toolkit)) (:weight bold :height 0.8 :family "helvetica"))))
 '(mode-line ((t (:background "wheat" :foreground "black" :box (:line-width -1 :style released-button) :weight bold :height 0.9 :width normal :foundry "inconsolata" :family "unknown"))))
 '(mode-line-emphasis ((t (:foreground "red" :weight bold))))
 '(mode-line-inactive ((t (:background "wheat" :family "Inconsolata" :foundry "unknown" :slant normal :weight normal :height 90 :width normal))))
 '(modeline ((t (:family "Inconsolata" :foundry "unknown" :slant normal :weight normal :height 100 :width normal))))
 '(modeline-face ((((class color) (min-colors 88) (background light)) (:background "wheat")))))
(setq x-alt-keysym 'meta)
