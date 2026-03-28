;; Fast file search with live preview and bookmark integration
(use-package consult
  :bind (("C-x b"   . consult-buffer)
         ("C-x C-r" . consult-recent-file)
         ("M-s f"   . consult-fd-preview)
         ("M-s g"   . consult-grep)
         ("M-s r"   . consult-ripgrep)
         ("C-s"     . consult-line)
         ("C-x r b" . consult-bookmark)
         ("M-s ."   . my/consult-line-dwim)
         ("M-s M-." . my/consult-line-symbol-at-point))
         
  :config
  ;; Enable automatic preview with slight delay to avoid lag
  (setq consult-preview-key '(:debounce 0.2 any))

  ;; Include bookmarks in buffer switching
  (setq consult-buffer-sources
        '(consult-source-hidden-buffer
          consult-source-modified-buffer
          consult-source-buffer
          consult-source-recent-file
          consult-source-bookmark
          consult-source-project-buffer-hidden
          consult-source-project-recent-file-hidden)))

(with-eval-after-load 'consult
  ;; ====================
  ;; CONSULT SEARCH (DWIM + symbol)
  ;; ====================

  ;; DWIM: region → symbol → empty
  (defun my/consult-line-dwim ()
    "Search with consult-line using region or symbol at point."
    (interactive)
    (consult-line
     (or (and (use-region-p)
              (buffer-substring-no-properties
               (region-beginning) (region-end)))
         (thing-at-point 'symbol))))

  ;; Symbol-only (classic behavior)
  (defun my/consult-line-symbol-at-point ()
    "Search for symbol at point using consult-line."
    (interactive)
    (consult-line (thing-at-point 'symbol)))

  ;; ====================
  ;; FILE SEARCH WITH PREVIEW
  ;; ====================

  (defun consult-fd-preview (&optional dir initial)
    "Find file with fd and live preview."
    (interactive "P")
    (pcase-let* ((`(,prompt ,paths ,dir)
                  (consult--directory-prompt "Fd" dir))
                 (default-directory dir)
                 (builder (consult--fd-make-builder paths)))
      (find-file
       (consult--read
        (consult--process-collection builder
          :transform (consult--async-map
                      (lambda (x) (string-remove-prefix "./" x)))
          :highlight t
          :file-handler t)
        :prompt prompt
        :sort nil
        :require-match t
        :initial initial
        :category 'file
        :history '(:input consult-fd-history)
        :state (consult--file-preview)))))


  (defun consult-find-preview (&optional dir initial)
    "Find file with live preview."
    (interactive "P")
    (pcase-let* ((`(,prompt ,paths ,dir)
                  (consult--directory-prompt "Find" dir))
                 (default-directory dir)
                 (builder (consult--find-make-builder paths)))
      (find-file
       (consult--read
        (consult--process-collection builder
          :transform (consult--async-map
                      (lambda (x) (string-remove-prefix "./" x)))
          :highlight t
          :file-handler t)
        :prompt prompt
        :sort nil
        :require-match t
        :initial initial
        :category 'file
        :history '(:input consult--find-history)
        :state (consult--file-preview))))))


;; Show available keybindings
(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.2)            ; Show after 0.2 seconds
  (setq which-key-popup-type 'side-window)   ; Show in side window
  (setq which-key-side-window-location 'bottom)
  (setq which-key-show-major-mode t))        ; Show major mode bindings prominently

;; Embark - contextual actions on completions
(use-package embark
  :bind (("C-." . embark-act)         ; Context actions
         ("C-;" . embark-dwim)        ; Do what I mean
         ("C-h B" . embark-bindings)) ; Alternative for `describe-bindings'
  :config
  
  ;; Make C-. work in minibuffer too
  (define-key minibuffer-local-map (kbd "C-.") #'embark-act)
  
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Embark + Consult integration
(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; macOS Finder integration with Embark
(when (eq system-type 'darwin)
  (defun my-macos-reveal-in-finder (file)
    "Reveal FILE in macOS Finder."
    (interactive "fFile: ")
    (start-process "finder-reveal" nil "open" "-R" (expand-file-name file))
    (message "Revealed in Finder: %s" file))
  
  (defun my-macos-open-externally (file)
    "Open FILE with macOS default application."
    (interactive "fFile: ")
    (start-process "macos-open" nil "open" (expand-file-name file))
    (message "Opened externally: %s" file))
  
  (with-eval-after-load 'embark
    (define-key embark-file-map (kbd "F") #'my-macos-reveal-in-finder)
    (define-key embark-file-map (kbd "O") #'my-macos-open-externally)))


(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)
         :map minibuffer-local-completion-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file))
  :config
  (setq consult-dir-shadow-filenames nil)  ; replace path cleanly instead of shadowing
  ;; Enable recentf for recent directories
  (recentf-mode 1)
  
  ;; Optionally customize sources
  (setq consult-dir-sources
        '(consult-dir--source-bookmark
          consult-dir--source-default
          consult-dir--source-project
          consult-dir--source-recentf
          consult-dir--source-tramp-ssh)))

(defvar my/consult-dir--source-recent-ssh
  `(:name "Recent SSH"
    :narrow ?r
    :category file
    :face consult-file
    :history file-name-history
    :items ,(lambda ()
              (cl-remove-if-not
               (lambda (f) (string-prefix-p "/ssh:" f))
               recentf-list)))
  "Recently visited SSH paths for consult-dir.")

(defun my/find-file-ssh ()
  "Pick an SSH host via consult-dir and open find-file there."
  (interactive)
  (let ((consult-dir-sources '(my/consult-dir--source-recent-ssh
                               consult-dir--source-tramp-ssh)))
    (consult-dir)))

(global-set-key (kbd "C-c f s") #'my/find-file-ssh)

;; ====================
;; TREEMACS - File tree sidebar
;; ====================
(use-package treemacs
  :bind (("C-c d" . treemacs)              ; Toggle sidebar
         ("C-c f t" . treemacs-select-window)) ; Jump to sidebar
  :config
  (treemacs-follow-mode 1)  ; Auto-sync sidebar with current buffer
  (setq treemacs-width 40
        treemacs-is-never-other-window nil
        treemacs-show-hidden-files t
        treemacs-width-is-initially-locked nil)  ; Allow resizing with mouse

  ;; Truncate long filenames only when treemacs window is narrow (< 40 chars)
  (setq treemacs-file-name-transformer
        (lambda (name)
          (let* ((win (treemacs-get-local-window))
                 (width (if win (window-width win) 40))
                 (max-len (- width 8)))  ; account for icons/indent
            (if (and (< width 40) (> (length name) max-len))
                (let* ((ext (file-name-extension name t))
                       (base (file-name-sans-extension name))
                       (max-base (- max-len (length ext) 3))
                       (front (substring base 0 (/ max-base 2)))
                       (back (substring base (- (length base) (/ max-base 2)))))
                  (concat front "..." back ext))
              name)))))

  ;; Auto-refresh treemacs when window is resized so filenames re-truncate
  (add-hook 'window-size-change-functions
            (lambda (_frame)
              (when (treemacs-get-local-window)
                (treemacs-run-in-every-buffer
                 (treemacs--do-refresh (current-buffer))))))

;; ====================
;; PROJECT FILE SWITCHING
;; ====================

;; Recognize CVS directories as projects
(defun my/project-try-cvs (dir)
  "Detect a CVS project by looking for a CVS/ subdirectory."
  (let ((cvs-dir (locate-dominating-file dir "CVS")))
    (when cvs-dir
      (cons 'transient cvs-dir))))

(add-hook 'project-find-functions #'my/project-try-cvs)

;; Quick switch between project files (e.g. part3.tex ↔ part4.tex)
(global-set-key (kbd "C-c f f") #'project-find-file)   ; Find file in project
(global-set-key (kbd "C-c f b") #'consult-project-buffer) ; Switch project buffers

