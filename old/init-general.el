

(setq ring-bell-function 'ignore)



;; Resolve symlinks when opening files, so that any operations are conducted
;; from the file's true directory (like `find-file').
(setq find-file-visit-truename t
      vc-follow-symlinks t)


;; Display the current column number in the mode line, and display line numbers on all buffers.

(column-number-mode 1)

(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook))
    (add-hook hook 'display-line-numbers-mode))


;; Automatically add the closing pair when you type a parenthesis or bracket. Disable strange auto-indentation behavior. Insert spaces instead of tabs. Set tab width to two spaces.

;;(electric-pair-mode 1)
;;(electric-indent-mode -1)
(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)
;; (setq-default indent-line-function 'insert-tab) ;; might cause issues



;; access to recently opened file
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(setq recentf-max-saved-items 25)

;; overwrite marked regions

(delete-selection-mode 1)

;; no lock files
(setq create-lockfiles nil) 

;; Have Emacs maintain a history of mini buffer commands and opened files. This will make it easier to get back to things you were doing.

(savehist-mode 1)

;; Disable lock file creation, and send backups to a designated directory. This will prevent Emacs from cluttering your file system.


;;; disable cluttering in directories, while editing files
(defvar init-backup-dir (concat user-emacs-directory "backups/")) ;; define corresponding backup directories
(defvar init-auto-saves-dir (concat user-emacs-directory "auto-saves/"))
 (dolist (dir (list init-backup-dir init-auto-saves-dir))
    (when (not (file-directory-p dir))
      (make-directory dir t)))


;; backup configuration
(setq backup-directory-alist `(("." . ,init-backup-dir)))

;; (setq backup-directory-alist '(("." . "~/MyEmacsBackups")))

;; (setq tramp-backup-directory-alist backup-directory-alist)
(setq make-backup-files t)        ; backup of a file the first time it is saved.

;; (setq backup-by-copying-when-linked t) ; not needed
(setq backup-by-copying t)  ; Backup by copying rather renaming
(setq delete-old-versions t)  ; Delete excess backup versions silently
(setq version-control t)  ; Use version numbers for backup files
(setq kept-new-versions 5) ; oldest versions to keep when a new numbered backup is made (default: 2)
(setq kept-old-versions 5) ; newest versions to keep when a new numbered backup is made (default: 2)
(setq vc-make-backup-files nil)  ; Do not backup version controlled files
(setq delete-old-versions t) ;; delete excess backup files silently
(setq create-lockfiles nil)
 
 
(setq auto-save-file-name-transforms `((".*" , init-auto-saves-dir t)))
(setq auto-save-list-file-prefix (concat init-auto-saves-dir "saves-"))
;; tramp-backup-directory-alist `((".*" . ,backup-dir))
;; tramp-auto-save-directory auto-saves-dir
      ;;  auto-save-default t               ; auto-save every buffer that visits a file
      ;; auto-save-timeout 20              ; number of seconds idle time before auto-save (default: 30)
      ;; auto-save-interval 200            ; number of keystrokes between auto-saves (default: 300)



(setq delete-by-moving-to-trash t)


;; Mouse wheel scroll can be unwieldy. Emacs also loves to make large and jarring jumps as you scroll. Set these to make it more natural.

(setq mouse-wheel-progressive-speed nil)
(setq scroll-conservatively 101)

;;Taking certain actions in Emacs will prompt for a yes or no answer. The first variable will permit answers with a simple y or n. The second will disable a dialog box which would appear if you took the action using the mouse (such as closing an unsaved buffer with the mouse). The keyboard prompt is given instead.

(setq use-short-answers t)
(setq use-dialog-box nil)


;; You will still be left with a scratch buffer which cannot be disabled. You can set its initial content to a string, or nil if you want it to be empty. Also set it to fundemental-mode to disable elisp syntax highlighting.

(setq initial-scratch-message nil)
(setq initial-major-mode 'fundamental-mode)
(global-auto-revert-mode 1)

;; enable recent files, is already implemented by helm

;;(recentf-mode 1)
;;(setq recentf-max-menu-items 25)
;;(setq recentf-max-saved-items 25)
;;global-set-key "\C-x\ \C-r" 'recentf-open-files)


(defun my/copy-file-only-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode)
                      default-directory
                    (buffer-name))))
    (when filename
      (kill-new filename))
    (message filename)))



(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let* ((name (buffer-name))
        (filename (buffer-file-name))
        (basename (file-name-nondirectory filename)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " (file-name-directory filename) basename nil basename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))
