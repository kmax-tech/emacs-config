;; ~/.emacs.d/init.el - Minimal, elegant Emacs configuration

;; If there are problems and errors run these commands
;; emacs --debug-init --eval "(setq debug-on-error t)"
;; emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")"

;; ====================
;; PACKAGE MANAGEMENT
;; ====================

;; Set up package repositories
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")))
(package-initialize)

;; Refresh package contents on first run or if archives are empty
(unless package-archive-contents
  (package-refresh-contents))

;; Install use-package if not already installed
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;; Always load source file, never compiled version (useful during development)
(setq load-prefer-newer t)

;; ====================
;; BASIC SETTINGS
;; ====================

;; macOS modifier keys setup
(setq mac-command-modifier 'super)   ; Command key is Super (s)
(setq mac-option-modifier 'meta)     ; Option key is Meta (M)
(setq mac-control-modifier 'control) ; Control key stays Control

;; Remove clutter
(setq inhibit-startup-message t)
(tool-bar-mode -1)
(menu-bar-mode -1)
(scroll-bar-mode -1)

;; Show line numbers
(global-display-line-numbers-mode 1)

;; Highlight current line
(global-hl-line-mode 1)

;; Show matching parentheses
(show-paren-mode 1)

;; Better scrolling
(setq scroll-conservatively 100)

;; Line wrapping
(global-visual-line-mode 1)              ; Soft wrap lines at word boundaries
(setq-default fill-column 80)            ; Wrap at 80 characters for hard breaks

;; UTF-8 encoding
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)

;; ====================
;; FILE HANDLING
;; ====================

;; Auto-refresh files when changed externally
(global-auto-revert-mode 1)
;; Also auto-refresh dired buffers
(setq global-auto-revert-non-file-buffers t)
;; Be quiet about reverts (don't spam messages)
(setq auto-revert-verbose nil)
;; Enable auto-revert for remote files (TRAMP)
(setq auto-revert-remote-files t)
;; Check less frequently for remote files (every 10 seconds instead of 5)
(setq auto-revert-interval 10)

;; Remember recent files
(recentf-mode 1)
(setq recentf-max-saved-items 50)

;; Save place in files
(save-place-mode 1)

;; Automatically save customizations (like safe local variables)
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;; Backup files in one place
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))

;; ====================
;; BOOKMARKS
;; ====================

;; Bookmark settings
(setq bookmark-default-file (expand-file-name "bookmarks" user-emacs-directory))
(setq bookmark-save-flag 1)  ; Save bookmarks after every change

;; Set up your favorite directories as bookmarks
(defun setup-favorite-bookmarks ()
  "Set up frequently-used directory bookmarks."
  (interactive)
  (require 'bookmark)
  ;; Define bookmark-exists-p if it doesn't exist (Emacs < 28.1)
  (unless (fboundp 'bookmark-exists-p)
    (defalias 'bookmark-exists-p
      (lambda (name) (assoc name bookmark-alist))))
  
  (dolist (bm '(("projects" . "~/projects")
                ("cvsrepo" . "~/cvsrepo")
                ("bibliographies" . "~/cvsrepo/bibliographies")
                ("home" . "~")
                ("emacs-config" . "~/.emacs.d")))
    (unless (bookmark-exists-p (car bm))
      (bookmark-store
       (car bm)
       `((filename . ,(expand-file-name (cdr bm)))
         (handler . bookmark-jump))
       nil)))
  (bookmark-save))



;; Set up bookmarks after Emacs is fully ready
(add-hook 'emacs-startup-hook 'setup-favorite-bookmarks)


;; ====================
;; COMPLETION
;; ====================

;; consult-dir enables recursive minibuffers locally when needed
(setq enable-recursive-minibuffers nil)

;; Better minibuffer completion
(use-package vertico
  :init
  (vertico-mode)
  (setq vertico-cycle t)
  :bind (:map vertico-map
              ("C-l" . vertico-directory-up)
              ("s-<up>" . vertico-directory-up)
                ("C-j" . vertico-exit-input)       ;; Submit exact minibuffer text
            ("RET" . vertico-directory-enter))  ;; Enter dir or open file
)

;; Save minibuffer history
(use-package savehist
  :init
  (savehist-mode))

;; Rich annotations in minibuffer
(use-package marginalia
  :init
  (marginalia-mode)
  :bind (:map minibuffer-local-map
         ("M-A" . marginalia-cycle))  ; Cycle through annotation levels
  :custom
  (marginalia-align 'right))  ; Align annotations to the right

;; Better search/filter
(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

;; In-buffer completion
(use-package company
  :config
  (global-company-mode)
  (setq company-idle-delay 0.2)
  (setq company-minimum-prefix-length 2)
  ;; Don't activate in minibuffer
  (setq company-global-modes '(not minibuffer-mode minibuffer-inactive-mode)))

;; Better JSON viewing and editing
(use-package json-mode
  :config
  (setq js-indent-level 2))

;; Navigate and fold JSON structures
(use-package json-navigator
  :after json-mode)

;; Markdown mode with live preview
(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :config
  ;; Try to find an available markdown processor
  (cond
   ((executable-find "pandoc")
    (setq markdown-command "pandoc -f markdown -t html"))
   ((executable-find "markdown")
    (setq markdown-command "markdown"))
(t
 (message "No Markdown processor found; preview disabled"))
  ;; Use visual-line-mode for better reading
  (add-hook 'markdown-mode-hook 'visual-line-mode)
  ;; Auto-format on save (optional)
  (add-hook 'markdown-mode-hook
            (lambda ()
              (setq-local fill-column 80)))))

;; Live Markdown preview in browser
(use-package markdown-preview-mode
  :after markdown-mode
  :config
  (setq markdown-preview-stylesheets
        (list "https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.1.0/github-markdown.min.css")))

;; Dired filtering
(use-package dired-narrow
  :after dired
  :bind (:map dired-mode-map
              ("/" . dired-narrow-fuzzy)))

;; vterm as terminal emulator
(use-package vterm
  :ensure 
  :config
  (setq vterm-max-scrollback 10000)
  (setq vterm-shell "/bin/zsh"))








;; ====================
;; KEYBINDINGS
;; ====================

;; Esc exits recursive edits (ESC ESC ESC to get out of anything)
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

;; macOS standard keybindings
(global-set-key (kbd "s-x") 'kill-region)        ; Cmd-X = Cut
(global-set-key (kbd "s-c") 'kill-ring-save)     ; Cmd-C = Copy
(global-set-key (kbd "s-v") 'yank)               ; Cmd-V = Paste
(global-set-key (kbd "s-a") 'mark-whole-buffer)  ; Cmd-A = Select all
(global-set-key (kbd "s-z") 'undo)               ; Cmd-Z = Undo
(global-set-key (kbd "s-s") (lambda () (interactive) (save-buffer))) ; Cmd-S = Save
(global-set-key (kbd "s-w") (lambda () (interactive)  ; Cmd-W = Smart close
                               (if (> (length (window-list)) 1)
                                   (kill-buffer-and-window)
                                 (kill-buffer))))
(global-set-key (kbd "s-q") 'save-buffers-kill-terminal) ; Cmd-Q = Quit
(global-set-key (kbd "s-/") 'comment-line)       ; Cmd-/ = Comment/uncomment line

;; Quick access to recent files
(global-set-key (kbd "C-x C-r") 'consult-recent-file)

;; Quick directory browsing
;; (global-set-key (kbd "C-x C-d") 'dired)

;; Buffer switching - use default with Vertico
(global-set-key (kbd "C-x b") 'switch-to-buffer)

;; Bookmark keybindings
(global-set-key (kbd "C-x r m") 'bookmark-set)        ; Set bookmark
(global-set-key (kbd "C-x r b") 'consult-bookmark)    ; Jump to bookmark
(global-set-key (kbd "C-x r l") 'bookmark-bmenu-list) ; List all bookmarks
(global-set-key (kbd "C-x r d") 'bookmark-delete)     ; Delete bookmark

;; Helpful keybinding discovery
(global-set-key (kbd "C-h B") 'describe-bindings)  ; Capital B for better bindings view

;; Quick shell access
(global-set-key (kbd "C-c t") 'vterm)              ; Fast terminal
(global-set-key (kbd "C-c s s") #'shell)           ; Simple shell

;; ====================
;; APPEARANCE
;; ====================

;; Font configuration
(set-face-attribute 'default nil
                    :family "JetBrainsMono Nerd Font"
                    :height 140  ; Font size (140 = 14pt)
                    :weight 'normal)

;; Fallback fonts if JetBrains Mono isn't installed
(set-fontset-font t 'unicode "SF Mono" nil 'prepend)

;; Theme
(use-package catppuccin-theme
  :config
  (setq catppuccin-flavor 'latte)  ; Options: latte, frappe, macchiato, mocha
  (load-theme 'catppuccin :no-confirm))

;; Smoother font rendering
(setq-default line-spacing 0.2)

;; Column number in mode line
(column-number-mode 1)

;; File size in mode line
(size-indication-mode 1)

;; ============================================
;; Kubel - Kubernetes in Emacs
;; ============================================

(use-package kubel
  :ensure t
  :commands (kubel)
  :config
  (setq kubel-use-namespace-list 'on)
  
  ;; Show namespace in modeline
  (add-to-list 'mode-line-misc-info
               '(:eval (when (boundp 'kubel-namespace)
                        (format " [k8s:%s] " kubel-namespace))))
  
  ;; Load last namespace from file
  (defun load-kubel-namespace-from-shell ()
    "Load namespace from ~/.kube_last_namespace"
    (let ((ns-file (expand-file-name "~/.kube_last_namespace")))
      (when (file-exists-p ns-file)
        (with-temp-buffer
          (insert-file-contents ns-file)
          (setq kubel-namespace (string-trim (buffer-string)))))))
  
  ;; Save namespace to file when changed
  (defun sync-kubel-namespace-to-shell ()
    "Write current kubel namespace to ~/.kube_last_namespace"
    (when (boundp 'kubel-namespace)
      (with-temp-file (expand-file-name "~/.kube_last_namespace")
        (insert kubel-namespace))))
  
  ;; Hook it up
  (add-hook 'kubel-mode-hook
            (lambda ()
              (load-kubel-namespace-from-shell)
              (add-hook 'kubel-namespace-changed-hook
                        #'sync-kubel-namespace-to-shell nil t))))


;; Keybindings
(global-set-key (kbd "C-c k") 'kubel)   ;; Open kubel
(global-set-key (kbd "C-c t") 'vterm)   ;; Open terminal


;; ====================
;; TRAMP (Remote File Access)
;; ====================

;; Copy environment from shell (fixes PATH and other env vars on macOS)
;; (use-package exec-path-from-shell
;;   :if (memq window-system '(mac ns))
;;   :config
;;   (exec-path-from-shell-initialize)
;;   (exec-path-from-shell-copy-env "SSH_AUTH_SOCK"))
;; Copy environment from shell (fixes PATH and other env vars on macOS)
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :demand t
  :config
  (setq exec-path-from-shell-arguments '("-l"))  ; login shell to read ~/.zprofile (avoids noisy interactive plugins)
  (setq exec-path-from-shell-variables '("PATH" "MANPATH" "SSH_AUTH_SOCK"))
  (setq exec-path-from-shell-check-startup-files nil)
  (exec-path-from-shell-initialize))


;; macOS SSH agent support
;; (when (eq system-type 'darwin)
;;   ;; Use macOS keychain for SSH
;;   (setenv "SSH_AUTH_SOCK" 
;;           (string-trim 
;;            (shell-command-to-string "find /private/tmp/com.apple.launchd.*/Listeners -name 'ssh' 2>/dev/null | head -n 1")))
  
  ;; ;; Alternative: if using ssh-agent started in shell
  ;; (let ((ssh-auth-sock (getenv "SSH_AUTH_SOCK")))
  ;;   (when (not ssh-auth-sock)
  ;;     (setenv "SSH_AUTH_SOCK" 
  ;;             (concat (getenv "HOME") "/.ssh/agent.sock")))))


;; TRAMP settings for SSH connections
(setq tramp-default-method "ssh")
(setq tramp-use-ssh-controlmaster-options nil)

;; Copy remote file to local directory (keeps same filename)
(defun copy-remote-file-to-local ()
  "Copy current remote file to a local directory (creates directory if needed)."
  (interactive)
  (let* ((remote-file (buffer-file-name))
         (filename (file-name-nondirectory remote-file))
         (local-dir (read-directory-name "Copy to local directory: " "~/"))
         (local-path (expand-file-name filename local-dir)))
    (unless (file-directory-p local-dir)
      (make-directory local-dir t))
    (copy-file remote-file local-path t)
    (message "Copied to %s" local-path)
    (when (y-or-n-p "Open local file? ")
      (find-file local-path))))

(global-set-key (kbd "C-c C-l") 'copy-remote-file-to-local)



;; ====================
;; Spell Checking
;; ====================
(setq ispell-program-name "hunspell")
(setq ispell-dictionary "en_US")
(setenv "DICPATH" "/Users/max/.emacs.d/spelling")  ; adjust path if needed

(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'latex-mode-hook #'flyspell-mode)
(add-hook 'latex-mode-hook
          (lambda ()
            (setq-local flyspell-generic-check-word-predicate
                        #'texmathp)))
(use-package consult-flyspell
  :after (consult flyspell))
(global-set-key (kbd "C-c s f") #'flyspell-mode)

;; ====================
;; QUALITY OF LIFE
;; ====================

;; Ask before narrowing region
(put 'narrow-to-region 'disabled t)

;; Auto-format Lisp code as you type
(use-package aggressive-indent
  :hook ((emacs-lisp-mode . aggressive-indent-mode)
         (lisp-mode . aggressive-indent-mode)
         (scheme-mode . aggressive-indent-mode)))



;; German input method
(setq default-input-method "german-postfix")
;; Show current input method in mode line more prominently
(setq current-input-method-title "DE")

;; Auto-close brackets
(electric-pair-mode 1)

;; Remember window configuration
(winner-mode 1)

;; VC/CVS hydra - press ? in vc-dir to see all commands
(defhydra hydra-vc-dir (:hint nil :color pink :foreign-keys run)
  "
 ^Navigation^         ^Mark^               ^Actions^             ^View^
 ^^^^^^^^──────────────────────────────────────────────────────────────────
 _n_/_p_: next/prev     _m_: mark            _v_: next action      _=_: diff
 _RET_: open file      _u_: unmark          _a_: add file         _l_: log history
 ^^                   _M_: mark all        _c_: commit (checkin)  _g_: refresh (cvs up)
 ^^                   _U_: unmark all      _D_: delete file
 ^^
 ^State reference^
 ^^^^^^^^──────────────────────────────────────────────────────────────────
 up-to-date = clean    edited = modified    added = staged
 removed = to delete   unregistered = new (use _a_ to add)
 ^^
 _q_: quit hydra       _?_: describe mode
"
  ;; Navigation
  ("n" vc-dir-next-line)
  ("p" vc-dir-previous-line)
  ("RET" vc-dir-find-file :color blue)
  ;; Mark
  ("m" vc-dir-mark)
  ("u" vc-dir-unmark)
  ("M" vc-dir-mark-all-files)
  ("U" vc-dir-unmark-all-files)
  ;; Actions
  ("v" vc-next-action :color blue)
  ("a" vc-dir-register :color blue)
  ("c" vc-next-action :color blue)
  ("D" vc-dir-delete-file :color blue)
  ;; View
  ("=" vc-diff)
  ("l" vc-print-log :color blue)
  ("g" vc-dir-refresh)
  ;; Help / quit
  ("?" describe-mode :color blue)
  ("q" nil :color blue))

(add-hook 'vc-dir-mode-hook
          (lambda ()
            (define-key vc-dir-mode-map (kbd "?") #'hydra-vc-dir/body)))

;; Window management hydra - press C-c w to manage splits
(defhydra hydra-window (:hint nil :color pink :foreign-keys warn)
  "
 ^Move^             ^Resize^              ^Split^              ^Layout^
 ^^^^^^^^──────────────────────────────────────────────────────────────────
 _h_/_l_: left/right  _H_/_L_: shrink/grow w  _v_: split vertical    _u_: undo layout
 _j_/_k_: down/up     _J_/_K_: shrink/grow h  _s_: split horizontal  _U_: redo layout
 ^^                  _=_: balance all       _c_: close window      _o_: only this window
 ^^                  ^^                    ^^                    _S_: swap windows
 ^^
 ^Buffer^
 ^^^^^^^^──────────────────────────────────────────────────────────────────
 _b_: switch buffer  _f_: find file         _d_: dired
 ^^
 _q_: quit
"
  ;; Move between windows
  ("h" windmove-left)
  ("l" windmove-right)
  ("j" windmove-down)
  ("k" windmove-up)
  ;; Resize
  ("H" shrink-window-horizontally)
  ("L" enlarge-window-horizontally)
  ("K" shrink-window)
  ("J" enlarge-window)
  ("=" balance-windows)
  ;; Split
  ("v" split-window-right)
  ("s" split-window-below)
  ("c" delete-window)
  ("o" delete-other-windows :color blue)
  ;; Layout
  ("u" winner-undo)
  ("U" winner-redo)
  ("S" window-swap-states)
  ;; Buffer
  ("b" switch-to-buffer :color blue)
  ("f" find-file :color blue)
  ("d" dired :color blue)
  ;; Quit
  ("q" nil :color blue))

(global-set-key (kbd "C-c w") 'hydra-window/body)

;; Better Viewing of PDFs
(use-package pdf-tools
  :config
  (pdf-tools-install))
(add-hook 'pdf-view-mode-hook (lambda () (display-line-numbers-mode -1)))


;; no whitespaces in ediff
(setq ediff-ignore-whitespace 'all)

;; selectio is deleted when new content is pasted
(delete-selection-mode 1)

;; Confirm before quitting
;; (setq confirm-kill-emacs 'y-or-n-p)

;; Replace yes/no with y/n
(defalias 'yes-or-no-p 'y-or-n-p)

;; Load custom plugins
(load-file "~/.emacs.d/plugins-dev/typesense-search.el")
(load-file "~/.emacs.d/plugins-dev/latex.el")
(load-file "~/.emacs.d/plugins-dev/consult.el")
(load-file "~/.emacs.d/plugins-dev/directory.el")
(load-file "~/.emacs.d/plugins-dev/own-functions.el")


;; Verify it loaded
(message "Typesense loaded: %s" (featurep 'typesense-search))

;; Set keybindings explicitly
;; (global-set-key (kbd "C-c s t") 'typesense-search)
;; (global-set-key (kbd "C-c s b") 'typesense-search-buffer)
;; (global-set-key (kbd "C-c s F") 'typesense-search-and-open-finder)
;; (global-set-key (kbd "C-c s p") 'typesense-search-pdf)
;; (global-set-key (kbd "C-c s o") 'typesense-search-org)
;; (global-set-key (kbd "C-c s r") 'typesense-rebuild-index)
;; (global-set-key (kbd "C-c s s") 'typesense-server-status)


;; Auto-reload on save
(defun my/auto-reload-typesense ()
  "Reload typesense-search.el after saving it."
  (when (and buffer-file-name
             (string-match-p "typesense-search\\.el$" buffer-file-name))
    (load-file buffer-file-name)
    (message "✓ Reloaded typesense-search.el")))


(global-set-key (kbd "s-e") 'select-token-at-point)

(add-hook 'after-save-hook #'my/auto-reload-typesense)


(setq select-enable-primary nil)
(setq select-enable-clipboard t)

;; Column (rectangle) selection with Option+mouse drag
(global-set-key [M-down-mouse-1] #'mouse-drag-region-rectangle)
(global-set-key [M-drag-mouse-1] #'mouse-drag-region-rectangle)

(setq lock-file-name-transforms
      '((".*" "/tmp/emacs-locks/" t)))