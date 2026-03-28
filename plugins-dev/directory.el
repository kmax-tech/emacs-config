;; ====================
;; DIRECTORY NAVIGATION
;; ====================

(use-package hydra :ensure t)

;; File icons in dired (requires JetBrainsMono Nerd Font)
(use-package nerd-icons-dired
  :hook (dired-mode . nerd-icons-dired-mode))

;; Dired (directory editor) improvements
(setq dired-listing-switches "-alhgo")  ; Hide owner/group for cleaner view

;; Toggle between minimal and detailed dired listing
(defun dired-toggle-details-listing ()
  "Toggle dired between minimal (-alhgo) and detailed (-alh) listing."
  (interactive)
  (if (string-match-p "go" dired-actual-switches)
      (setq dired-actual-switches "-alh")
    (setq dired-actual-switches "-alhgo"))
  (revert-buffer))
(setq dired-dwim-target t)            ; Smart copy/move between two dired windows
(setq dired-create-destination-dirs 'ask) ; Ask before creating missing directories

(setq dired-mouse-drag-files t)
(setq mouse-drag-and-drop-region-cross-program t)


;; Fix for macOS ls not supporting --dired
(when (eq system-type 'darwin)
  (setq dired-use-ls-dired nil))

;; Enable dired-x for extra features
(require 'dired-x)

;; Auto-load dired-x when entering dired
(add-hook 'dired-mode-hook
          (lambda ()
            (dired-omit-mode 1)  ; Start with omit mode on
            (define-key dired-mode-map (kbd ")") #'dired-toggle-details-listing)))

;; Configure what to omit (hide dotfiles by default)
(setq dired-omit-files "^\\..*")

;; Quick copy from dired starting with a bookmarked location
(defun dired-copy-to-bookmark ()
  "Copy marked files in dired, starting path selection from a bookmarked location.
Asks before creating directories if they don't exist."
  (interactive)
  (let* ((bookmark-name (completing-read "Start from bookmark: " 
                                          (bookmark-all-names)))
         (bookmark-path (bookmark-get-filename bookmark-name))
         (default-directory (if (file-directory-p bookmark-path)
                                bookmark-path
                              (file-name-directory bookmark-path))))
    (call-interactively 'dired-do-copy)))

;; Keep track of last copy destination
(defvar dired-last-copy-destination nil
  "Last destination used in dired copy operations.")

;; Advice to remember last copy destination
(defun dired-remember-copy-destination (orig-fun &rest args)
  "Remember the destination directory for quick repeat copies."
  (let ((result (apply orig-fun args)))
    ;; Capture the destination from the minibuffer history
    (when (and (boundp 'minibuffer-history)
               minibuffer-history)
      (setq dired-last-copy-destination (car minibuffer-history)))
    result))

(advice-add 'dired-do-copy :around #'dired-remember-copy-destination)

;; Quick copy to last destination
(defun dired-copy-to-last-destination ()
  "Copy marked files to the last used destination directory."
  (interactive)
  (if dired-last-copy-destination
      (let ((dest dired-last-copy-destination))
        ;; Create directory if it doesn't exist
        (unless (file-directory-p dest)
          (when (y-or-n-p (format "Create directory %s? " dest))
            (make-directory dest t)))
        ;; Perform the copy
        (dired-do-copy-regexp ".*" dest))
    (message "No previous copy destination. Use C or B first.")))


(defun dired-rsync-to-local ()
  "Rsync marked files to a local directory.
Handles both remote and local sources. Batches all files into
a single rsync call. Shows progress in a dedicated buffer."
  (interactive)
  (let* ((files (dired-get-marked-files nil nil))
         (dest-dir (expand-file-name
                    (read-directory-name
                     "Rsync destination: "
                     (when (boundp 'dired-last-copy-destination)
                       dired-last-copy-destination))))
         (timestamp (format-time-string "%H:%M:%S"))
         (buffer-name (format "*rsync[%s]*" timestamp))
         (remote-files '())
         (local-files '()))

    ;; Validate destination
    (unless (file-directory-p dest-dir)
      (if (y-or-n-p (format "Create directory %s? " dest-dir))
          (make-directory dest-dir t)
        (user-error "Aborted: destination does not exist")))

    ;; Split files into remote and local
    (dolist (file files)
      (if (file-remote-p file)
          (push file remote-files)
        (push file local-files)))

    ;; Warn if mixing remote and local (rsync handles differently)
    (when (and remote-files local-files)
      (unless (y-or-n-p "Mix of local and remote files — continue?")
        (user-error "Aborted")))

    ;; Handle local files (plain rsync, no SSH)
    (when local-files
      (dired--rsync-run local-files dest-dir buffer-name nil))

    ;; Handle remote files — group by host for efficiency
    (when remote-files
      (let ((by-host (make-hash-table :test 'equal)))
        (dolist (file remote-files)
          (let ((host (format "%s%s"
                              (or (concat (file-remote-p file 'user) "@") "")
                              (file-remote-p file 'host))))
            (puthash host
                     (cons file (gethash host by-host '()))
                     by-host)))
        ;; One rsync call per host
        (maphash (lambda (host files)
                   (dired--rsync-run files dest-dir
                                     (format "*rsync[%s → %s]*" host timestamp)
                                     host))
                 by-host)))

    ;; Remember destination
    (setq dired-last-copy-destination dest-dir)))


(defun dired--rsync-run (files dest-dir buffer-name &optional remote-host)
  "Run rsync for FILES to DEST-DIR, output to BUFFER-NAME.
REMOTE-HOST is host string like 'user@host' for remote sources, nil for local."
  (let* ((srcs (mapconcat
                (lambda (f)
                  (shell-quote-argument
                   (if remote-host
                       (file-remote-p f 'localname)  ; strip tramp prefix
                     f)))
                files " "))
         (cmd (if remote-host
                  (format "rsync -avP --stats -e ssh %s:%s %s"
                          remote-host srcs
                          (shell-quote-argument dest-dir))
                (format "rsync -avP --stats %s %s"
                        srcs
                        (shell-quote-argument dest-dir))))
         (buf (get-buffer-create buffer-name)))

    (message "Starting rsync → %s" dest-dir)

    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (format "CMD: %s\n\n" cmd))
      (setq buffer-read-only t))

    (let ((proc (start-process-shell-command "rsync" buf cmd)))
      (set-process-sentinel
       proc
       (lambda (process event)
         (let ((ok (string= event "finished\n")))
           (with-current-buffer (process-buffer process)
             (setq buffer-read-only nil)
             (goto-char (point-max))
             (insert (format "\n[%s] %s"
                             (format-time-string "%H:%M:%S")
                             (if ok "✓ Done" (concat "✗ Failed: " event))))
             (setq buffer-read-only t))
           (if ok
               (message "✓ Rsync to %s complete" dest-dir)
             (message "✗ Rsync failed — see %s" buffer-name)))))

      (display-buffer buf '(display-buffer-in-side-window
                            (side . bottom)
                            (window-height . 0.25))))))

;; Better Dired keybindings
(eval-after-load 'dired
  '(progn
     ;; Much easier parent directory navigation
     (define-key dired-mode-map (kbd "C-c u") 'dired-up-directory)
     (define-key dired-mode-map (kbd "M-<up>") 'dired-up-directory)
     (define-key dired-mode-map (kbd "s-<up>") 'dired-up-directory) ; Cmd-Up like Finder
     ;; Easy toggle for hidden files
     (define-key dired-mode-map (kbd "H") 'dired-omit-mode)
     ;; Filtering with /
     (define-key dired-mode-map (kbd "/") 'dired-narrow-fuzzy)
     ;; Make M-s f filter in Dired instead of opening consult-find
     (define-key dired-mode-map (kbd "M-s f") 'dired-narrow-fuzzy)
     ;; Copy to bookmarked location
     (define-key dired-mode-map (kbd "B") 'dired-copy-to-bookmark)
    ;;  ;; Rsync to bookmarked location (better for large files)
    ;;  (define-key dired-mode-map (kbd "R") 'dired-rsync-to-local)
     ;; Quick copy to last destination
     (define-key dired-mode-map (kbd "L") 'dired-copy-to-last-destination)
     ;; Hydra help menu
     (define-key dired-mode-map (kbd "?") 'hydra-dired/body)))

;; Dired hydra - press ? in dired to see all commands
(defhydra hydra-dired (:hint nil :color pink :foreign-keys run)
  "
 ^Navigation^          ^Mark^               ^Actions^            ^View^
 ^^^^^^^^─────────────────────────────────────────────────────────────────
 _n_/_p_: next/prev      _m_: mark            _C_: copy            _)_: toggle details
 _^_: up directory      _u_: unmark          _R_: rename/move     _H_: show/hide dotfiles
 _RET_: open            _U_: unmark all      _D_: delete          _/_: filter (narrow)
 _o_: open other win    _t_: toggle marks    _+_: create dir      _s_: sort (name/date)
 ^^^^^^^^                                   _M_: chmod
 ^Copy shortcuts^       ^Rsync^              ^Other^
 ^^^^^^^^─────────────────────────────────────────────────────────────────
 _B_: copy to bookmark  _r_: rsync to local  _w_: copy filename
 _L_: copy to last dest ^^                   _W_: copy full path
 ^^
 _q_: quit hydra        _?_: Emacs dired help
"
  ("n" dired-next-line)
  ("p" dired-previous-line)
  ("^" dired-up-directory)
  ("RET" dired-find-file :color blue)
  ("o" dired-find-file-other-window :color blue)
  ("m" dired-mark)
  ("u" dired-unmark)
  ("U" dired-unmark-all-marks)
  ("t" dired-toggle-marks)
  ("C" dired-do-copy :color blue)
  ("R" dired-do-rename :color blue)
  ("D" dired-do-delete :color blue)
  ("+" dired-create-directory :color blue)
  ("M" dired-do-chmod :color blue)
  (")" dired-toggle-details-listing)
  ("H" dired-omit-mode)
  ("/" dired-narrow-fuzzy :color blue)
  ("s" dired-sort-toggle-or-edit)
  ("B" dired-copy-to-bookmark :color blue)
  ("L" dired-copy-to-last-destination :color blue)
  ("r" dired-rsync-to-local :color blue)
  ("w" dired-copy-filename-as-kill)
  ("W" (dired-copy-filename-as-kill 0))
  ("?" describe-mode :color blue)
  ("q" nil :color blue))


;; Launch Dired in dual-pane mode
(defun dired-dual-pane (&optional dir1 dir2)
  "Open Dired in dual-pane mode. 
DIR1 defaults to current directory, DIR2 to home."
  (interactive)
  (let ((d1 (or dir1 default-directory))
        (d2 (or dir2 "~/")))
    (delete-other-windows)
    (dired d1)
    (split-window-right)
    (other-window 1)
    (dired d2)
    (other-window 1)))  ; Focus left pane

;; Optional: bind it
(global-set-key (kbd "C-c d") 'dired-dual-pane)

(defun my/dired-sync-other-window ()
  "Sync the other window's Dired to the current directory."
  (interactive)
  (let ((dir (dired-current-directory)))
    (other-window 1)
    (dired dir)
    (other-window -1)))