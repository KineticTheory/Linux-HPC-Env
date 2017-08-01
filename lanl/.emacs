;; Copy this file to $HOME/.emacs and edit as needed.

;; Ref: www.emacswiki.org
;;      www.linuxpowered.com/html/tutorials/emacs.html

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

;;
;; Personal settings
;;

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
(setq reftex-bibpath-environment-variables
      '("BIBINPUTS" "TEXBIB" "!kpsewhich -show-path=.bib"))
;;       '("/home/kellyt/imcdoc/bib/"))

;; Automatically keep buffers synchronized with file system
;; (i.e. reload the buffer automatically if the file changes outside
;; of emacs).
(global-auto-revert-mode t)

;; Bind Alt as Meta
(setq x-alt-keysym 'meta)
;;(setq x-super-keysym 'meta) ;; Use Windows or penguin key as Meta.

;; Email
(setq user-mail-address "kgt@lanl.gov")

;; Set the frame size base on the current resolution.
(defun set-frame-size-according-to-resolution ()
  (interactive)
  (if window-system
      (progn
        ;; use 120 char wide window for largeish displays
        ;; and smaller 80 column windows for smaller displays
        ;; pick whatever numbers make sense for you.
        (defvar kt-emacs-width 80)
        (defvar kt-emacs-height 24)
        (if (> (x-display-pixel-height) 1100)
            (progn
              (setq kt-emacs-width 85)
              (setq kt-emacs-height 80)
              ;; Check that the height still fits on the monitor
              (setq max-emacs-height (/ (x-display-pixel-height)
                                        (frame-char-height) ))
              (if (> kt-emacs-height max-emacs-height)
                  (setq kt-emacs-height (- max-emacs-height 10)))

              ) ; progn
          ) ; endif

        (set-frame-size (selected-frame) kt-emacs-width
                        kt-emacs-height)
        )))
(set-frame-size-according-to-resolution)
(global-set-key [(shift f12)] 'set-frame-size-according-to-resolution)

;; Dired
(setq dired-listing-switches "-alh")

;; CEDET
;; Generate tag files for Fortran: 'gtags --gtagslabel=ctags'
(defvar file-at-root-level-draco "~/.draco_ede")
(defvar file-at-root-level-eap "~/cassio/.eap_ede")
; (draco-start-ecb)

;; Allow 'emacsclient' to connect to running emacs.
(if 'window-system
    (require 'server)
    (progn
      (or (server-running-p) (server-start))
))

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
       (number-sequence 4 80 4))
  (setq indent-tabs-mode nil
        fill-column 80
        truncate-lines t))

(setq cursor-type '(bar . 2))
(setq fill-column 80)
;(setq draco-code-comment-width 132)

;; (add-hook 'c++-mode-hook
;;           (lambda () (modify-syntax-entry ?_ "w")))


(defun draco-dos2unix ()
  "Convert line endings to Unix style, untabify, and indent-region by mode.
http://www.emacswiki.org/emacs/EndOfLineTips
Also C-x <ret> f utf-8-unix <ret>"
    (interactive)
    (set-fill-column 80)
    (progn
      (untabify (point-min) (point-max))
      (indent-region (point-min) (point-max))
      (add-hook 'before-save-hook 'delete-trailing-whitespace)
      (set-buffer-file-coding-system 'iso-latin-1-unix t)
      )
    )
; (define-key global-map [(f12)] 'draco-dos2unix)

;(require 'fill-column-indicator)
; fci-mode

;; clang-format
;;(require 'clang-format)
;;(define-key c++-mode-map [(f12)] 'clang-format-region)
;; See https://www.emacswiki.org/emacs/IndentingC
;; (if (fboundp 'clang-format)
;;     (add-hook 'c++-mode-hook
;;               (lambda ()
;;                 (add-hook 'before-save-hook 'clang-format-buffer)))
;;   )
(add-to-list 'default-frame-alist '(font . "Inconsolata"))
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
 '(draco-code-comment-width 80)
 '(draco-elisp-dir "/home/kellyt/draco/environment/elisp/")
 '(draco-env-dir "/home/kellyt/draco/environment/")
 '(ecb-layout-window-sizes (quote (("ecb-layout-kt" (0.25 . 0.25) (0.15 . 0.25) (0.4 . 0.45) (0.4 . 0.3)))))
 '(ecb-options-version "2.40")
 '(ecb-prescan-directories-for-emptyness nil)
 '(ecb-primary-secondary-mouse-buttons (quote mouse-1--mouse-2))
 '(ecb-vc-supported-backends (quote ((ecb-vc-dir-managed-by-SVN . ecb-vc-state) (ecb-vc-dir-managed-by-CVS . ecb-vc-state) (ecb-vc-dir-managed-by-GIT . ecb-vc-state) (ecb-vc-dir-managed-by-MTN . ecb-vc-state))))
 '(font-lock-maximum-decoration t)
 '(global-font-lock-mode t nil (font-lock))
 '(inhibit-startup-screen t)
 '(scroll-bar-mode (quote right))
 '(show-paren-mode t nil (paren))
 '(text-mode-hook (quote (turn-on-auto-fill text-mode-hook-identify)))
 '(tool-bar-mode nil)
 '(uniquify-buffer-name-style (quote forward) nil (uniquify)))

;; this fails, but 'emacs -fn 6x13' works so create an alias:

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
 '(default ((t (:family "Inconsolata" :foundry "unknown" :slant normal
                        :weight normal :height 90 :width normal
                        :background "mint cream" ))))
 '(font-lock-comment-face ((((class color) (min-colors 88) (background light)) (:foreground "purple"))))
 '(font-lock-constant-face ((((class color) (min-colors 88) (background light)) (:foreground "CadetBlue"))))
 '(font-lock-doc-face ((t (:inherit font-lock-string-face :foreground "bisque3"))))
 '(font-lock-function-name-face ((((class color) (min-colors 88) (background light)) (:foreground "Blue3"))))
 '(font-lock-keyword-face ((((class color) (min-colors 88) (background light)) (:foreground "firebrick2"))))
 '(font-lock-preprocessor-face ((t (:inherit font-lock-builtin-face :foreground "hotpink"))))
 '(font-lock-string-face ((((class color) (min-colors 88) (background light)) (:foreground "orange3"))))
 '(font-lock-variable-name-face ((((class color) (min-colors 88) (background light)) (:foreground "Royalblue"))))
 '(menu ((((type x-toolkit)) (:weight bold :height 0.8 :family "helvetica"))))
 '(mode-line ((t (:background "wheat" :foreground "black" :box (:line-width -1 :style released-button) :weight bold :height 0.9 :width normal :foundry "inconsolata" :family "unknown"))))
 '(mode-line-emphasis ((t (:foreground "red" :weight bold))))
 '(mode-line-inactive ((t (:background "wheat" :family "Inconsolata" :foundry "unknown" :slant normal :weight normal :height 90 :width normal))))
 '(modeline ((t (:family "Inconsolata" :foundry "unknown" :slant normal :weight normal :height 90 :width normal))))
 '(modeline-face ((((class color) (min-colors 88) (background light)) (:background "wheat")))))
(setq x-alt-keysym 'meta)
