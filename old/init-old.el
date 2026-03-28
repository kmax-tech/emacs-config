;;; init.el --- Init -*- no-byte-compile: t; lexical-binding: t; -*-
;;init to work on

(add-hook 'after-init-hook
         '(lambda () (setq debug-on-error t)))                     


(load-theme 'misterioso t)
(set-face-attribute 'default nil :font "IBM Plex Mono" :height 140)
(setq completions-detailed t) ;; more info in minibuffer


(defun my/load-config-file (file)
  "Load elisp FILE."
  (load (expand-file-name file "~/.emacs.d/")))

(my/load-config-file "init-general")
;; (my/load-config-file "tabline")

;; custom file for settings from graphical customization interface
(setq custom-file "~/.emacs.d/custom-file.el")

;; add paths to emacs configuration
(add-to-list 'exec-path "/opt/homebrew/bin")

;; adjustment for packages

(require 'package)
(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/"))
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
;; Comment/uncomment this line to enable MELPA Stable if desired.  See `package-archive-priorities`
;; and `package-pinned-packages`. Most users will not need or want to do this.
;; (add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(package-initialize)

;;define the use of base package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package-ensure)
(setq use-package-always-ensure t)


(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))
;; daemon version to get zsh configs to emacs
(when (daemonp)
  (exec-path-from-shell-initialize))

;; use right option key for special characters

(when (eq system-type 'darwin)
  ;; Set the left Option key as Meta
  (setq mac-option-key-is-meta t)
  ;; Allow the right Option key to be used for special characters
  (setq mac-right-option-modifier 'none)
  ;; Bind Command + V to paste (yank)
  (global-set-key (kbd "s-v") 'yank)
  (global-set-key (kbd "s-j") 'join-line) ;; for joining lines
)

(use-package which-key
:ensure t
:config
(which-key-mode)
)

(use-package expand-region
:ensure t
:bind (("C-=" . er/expand-region)
       ("C--" . er/contract-region)
))


(use-package undo-tree
  :ensure t
  :config
  (global-undo-tree-mode)
)

(use-package evil
  :ensure t
  :config
  (evil-mode 1)
  (setq evil-undo-system 'undo-tree)
  )


;; variable-pitch-mode leads to proportional fonts
;;(use-package prog-mode
;;  :ensure nil
;;  :hook ((prog-mode . hl--mode)         
;;))


;; enable spell checking and set a variable pitch font in text-mode buffers.
;; variable-pitch-mode leads to proportional fonts
(use-package emacs
  :config (tab-bar-mode)
  (global-visual-line-mode 1)
  )

(add-hook 'text-mode-hook 'turn-on-visual-line-mode)
(global-display-line-numbers-mode)



(use-package helm
  :diminish helm-mode
  :init
  (progn
    (setq helm-candidate-number-limit 100)
    (setq helm-idle-delay 0.03
          helm-input-idle-delay 0.03
          helm-yas-display-key-on-candidate t
          helm-quick-update t 
          helm-M-x-requires-pattern nil))
  :bind (
                    ("C-c ;" . helm-command-prefix)
                    ("C-h a" . helm-apropos)
		                ("C-x C-r" . helm-recentf)
                    ("C-x C-b" . helm-buffers-list)
                    ("C-x b" . helm-buffers-list)
                    ("M-y" . helm-show-kill-ring)
                    ("M-x" . helm-M-x)
                    ("C-x C-f" . helm-find-files)
                    ("C-c h o" . helm-occur) 
                    ("C-c h r" . helm-register)
                    ("C-c h b" . helm-resume)
                    ("M-o" . helm-occur)
                    ;; :map helm-map 
                    ;;       ("TAB" . helm-ff-RET)
                    ;;       ("C-TAB" . helm-select-action)

                          )
;; :custom (helm-M-x-toggle-short-doc) 
  :config
  (setq helm-split-window-in-side-p t
        helm-echo-input-in-header-line t
        ;;helm-autoresize-min-height 25
        helm-autoresize-max-height 25

        helm-move-to-line-cycle-in-source t
        helm-ff-search-library-in-sexp t
        helm-scroll-amount 8
        helm-ff-file-name-history-use-recentf t
        helm-buffer-max-length 20
        helm-M-x-fuzzy-match t)
  (helm-autoresize-mode 1)
  
  ;; (add-hook 'helm-minibuffer-set-up-hook
  ;;           'spacemacs//helm-hide-minibuffer-maybe)
  (helm-mode 1))



;; ;; (use-package helm-swoop
;;   ;; :after helm)

;; (use-package helm-rg
;;   :ensure t
;;   :after helm)




;; ;; ;;(linum-relative-global-mode)
;; ;; ;;(helm-linum-relative-mode 1)

;; (define-key mode-line-buffer-identification-keymap
;;             [mode-line mouse-3]
;;             (lambda (
;;               (interactive)
;;               (display-buffer (list-buffers-noselect nil (buffer-list))))))


;; ;; (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))
;; ;;(use-package pasp-mode)

(use-package multiple-cursors
:bind (("C-S-a C-S-a" . 'mc/edit-lines )))

;; ;; moving of windows
;; (when (fboundp 'windmove-default-keybindings)
;;   (windmove-default-keybindings))

;; ;




(use-package lsp-ui
:after lsp-mode
  )

(use-package helm-lsp :commands helm-lsp-workspace-symbol
:after (lsp-mode, helm)
)

  (setq gc-cons-threshold 100000000)
  (setq read-process-output-max (* 1024 1024)) ;; 1mb


(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")

  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (tex-mode . lsp-deferred)
         (LaTeX-mode . lsp-deferred)
          (bibtex-mode . lsp-deferred)
      ;;  lsp-mode . lsp-enable-which-key-integration)
      )

  ;; :config 
 
   ;; Add Svelte file type support
  ;; (add-to-list 'lsp-language-id-configuration '(".*\\.svelte$" . "svelte"))
  ;; (setq lsp-log-io nil) ;; no logging

  ;; ;;(define-key lsp-mode-map [remap xref-find-apropos] #'helm-lsp-workspace-symbol)

  ;; (let ((lsp-server-path "/Users/max/PycharmProjects/LanguageServerGo/main"))
  ;;   (if (file-exists-p lsp-server-path)
  ;;       (lsp-register-client
  ;;        (make-lsp-client
  ;;        :new-connection (lsp-stdio-connection lsp-server-path)
  ;;         :activation-fn (lsp-activate-on "svelte")
  ;;         :server-id 'educationallsp))
  ;;     (message "LSP server file does not exist at: %s" lsp-server-path)))

  :commands lsp lsp-deferred)


(use-package lsp-latex
  :after lsp-mode
  ;; :ensure t
  :hook ((TeX-mode . (lambda () (electric-indent-local-mode -1)))
         (LaTeX-mode . (lambda () (electric-indent-local-mode -1)))
         (latex-mode . lsp))  ;; Ensure LSP starts in LaTeX buffers
  :bind (
         ("s-b" . lsp-latex-build)
  ))

(my/load-config-file "treemacs-init")

(setq TeX-auto-indent nil)
(setq TeX-newline-function 'newline)  ;; Prevent auto-indenting on Enter


;; (setq lsp-latex-texlab-executable "/opt/homebrew/bin/texlab")
;; (setq lsp-latex-build-args  '("-pdf" "-pv" "-interaction=nonstopmode" "-synctex=1" "%f"))
;; (setq lsp-latex-forward-search-executable "/Applications/Skim.app/Contents/SharedSupport/displayline")
;; (setq lsp-latex-forward-search-args '("%l" "%p" "%f"))

;; ;; configuration for use of sioyek
(setq lsp-latex-forward-search-executable "sioyek")
(setq lsp-latex-forward-search-args '( "--reuse-window" "--execute-command" "toggle_synctex" "--inverse-search" "texlab inverse-search -i %%1 -l %%2" "--forward-search-file" "%f" "--forward-search-line" "%l" "%p"))



(use-package company
  :ensure t
  :init
  (setq company-minimum-prefix-length 3
		company-selection-wrap-around t
		company-tooltip-align-annotations t
		company-tooltip-annotation-padding 2
		company-tooltip-limit 9
      company-idle-delay 0.01
		company-show-quick-access 'left)
   :config
  (global-company-mode))


;; (defun my-get-python-test-file (impl-file-path)

;;   "Return the corresponding test file directory for IMPL-FILE-PATH"
  
;;   (message "Executing my-get-python-test-file. The value of dir is: %s" impl-file-path)

;;   (let* ((rel-path (f-relative impl-file-path (projectile-project-root)))
;;          (src-dir (car (f-split rel-path))))

;;     (cond ((f-exists-p (f-join (projectile-project-root) "test"))
;;            (projectile-complementary-dir impl-file-path src-dir "test"))
;;           ((f-exists-p (f-join (projectile-project-root) "tests"))
;;            (projectile-complementary-dir impl-file-path src-dir "tests"))
;;           (t (error "Could not locate a test file for %s!" impl-file-path)))))



;; (defun projectile-my-webis-projects (&optional dir)
;;   "Check if a project contains a .NET project marker.
;; When DIR is specified it checks DIR's project, otherwise
;; it acts on the current project."
;;       (message "Executing projectile-my-webis-projects. The value of dir is: %s" dir)

;;       ( projectile-verify-file-wildcard "?*.frame.tex" dir))

;;; projectile and projectile configuration
(use-package projectile
  :ensure t
  :init (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("s-p" . projectile-command-map)
              ("C-c p" . projectile-command-map))
  :config  
  ;;(setq projectile-switch-project-action #'projectile-dired)
  ;; Optional: Set projectile settings before loading
  (setq projectile-enable-caching t)
  (setq projectile-completion-system 'auto)  ;; Use default completion system
(setq projectile-require-project-root nil)
(projectile-mode)
)

;; (setq helm-projectile-fuzzy-match nil)
;; (use-package helm-projectile
;;   :after projectile
;;   :config
;; (helm-projectile-on))


;; set up commenting
(use-package evil-nerd-commenter
  :bind ("M-;" . evilnc-comment-or-uncomment-lines))

(use-package vterm
    :ensure t)


;; ;; org mode configuration
;; (setq python-indent-offset 4)

;; (org-babel-do-load-languages
;;  'org-babel-load-languages
;;  '((emacs-lisp . t)
;;    (python . t)
;;  ))
;; (setq org-startup-with-inline-images t)

;; org overview
;; enable preview of latex in org mode
;; (setq org-highlight-latex-and-related '(latex))
;; (setq org-id-link-to-org-use-id t)
;; (setq org-preview-latex-default-process 'imagemagick) ;; latex processor
;; (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.4)) ;; adjust scale


;; handle pdf tools and pdf annotation
(use-package pdf-tools
  :mode
  (("\\.pdf$" . pdf-view-mode))

  :custom
  (setq pdf-annot-activate-created-annotations t)
  (setq pdf-view-resize-factor 1.1)

  :config
  (pdf-tools-install)
  (setq pdf-view-use-scaling t)
  ;;(setq-default pdf-view-display-size 'fit-page))
  (define-key pdf-view-mode-map (kbd "h") 'pdf-annot-add-highlight-markup-annotation)
  )

(use-package org-noter
  :ensure t
  :config
  (setq org-noter-highlight-selected-text t))


;; ;; testing of own defined variables
;; (defun my-process-region (start end)
;;   "Process the region from START to END and print the result in the minibuffer."
;;   (interactive "r") ;; Use "r" to pass the region's start and end positions.
;;   (let ((region-text (buffer-substring-no-properties start end)))
;;     ;; Process the region text here. Example: Convert to uppercase.
;;     (message "Region text: %s" (upcase region-text))))


;;; dired configuration
(setq dired-mouse-drag-files t)


;; ;;; save mode for desktop

;; (desktop-save-mode 1)

;; ;; Optional settings
;; (setq desktop-path '("~/.emacs.d/desktop/")
;;       desktop-dirname "~/.emacs.d/desktop/"
;;       desktop-base-file-name "emacs-desktop")

;; ;; Restore frames and windows exactly as they were
;; (setq desktop-restore-frames t)


;; ripgrep as grep
(setq grep-command "rg -nS --no-heading "
      grep-use-null-device nil)






(defun copy-file-path-to-clipboard ()
  "Copy the current buffer file path to the clipboard."
  (interactive)
  (let ((file-path (or (buffer-file-name) default-directory)))
    (when file-path
      (kill-new file-path)
      (message "Copied file path: %s" file-path))))


(use-package paren
:config
(setq show-paren-style 'expression)
(setq show-paren-when-point-in-periphery t)
(setq show-paren-when-point-inside-paren nil)
:hook (after-init-hook . show-paren-mode))





;; set variables as safe
(add-to-list 'safe-local-variable-values
             '(buffer-file-coding-system . iso-latin-1))
