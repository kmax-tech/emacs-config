;; Rename current file and buffer
(defun rename-current-file ()
  "Rename current buffer and file it's visiting."
  (interactive)
  (let* ((name (buffer-name))
         (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "Renamed to '%s'" (file-name-nondirectory new-name)))))))

(global-set-key (kbd "C-c r") 'rename-current-file)

;; Compare current file with auto-save version
(defun diff-buffer-with-autosave ()
  "Compare current buffer with its auto-save file using ediff."
  (interactive)
  (let* ((filename (buffer-file-name))
         (auto-save-file (make-auto-save-file-name)))
    (if (not filename)
        (message "Buffer is not visiting a file")
      (if (not (file-exists-p auto-save-file))
          (message "No auto-save file exists for this buffer")
        (ediff-files filename auto-save-file)))))

(global-set-key (kbd "C-c d") 'diff-buffer-with-autosave)

;; Clean up auto-save files
(defun clean-auto-save-files ()
  "Delete all auto-save files."
  (interactive)
  (when (y-or-n-p "Delete all auto-save files? ")
    (let ((count 0))
      (dolist (file (directory-files "~/.emacs.d/auto-save-list/" t "^#.*#$"))
        (delete-file file)
        (setq count (1+ count)))
      (message "Deleted %d auto-save file(s)" count))))

(defun my/dired-dump-tree-to-buffer ()
  "Dump all file contents under current Dired directory into a single buffer,
overwriting its contents. Ignores VCS, virtualenvs, and common junk."
  (interactive)
  (let* ((dir (file-truename (dired-current-directory)))
         (ignore-regexp
          (regexp-opt
           '("/.git/"
             "/CVS/"
             "/venv/"
             "/.venv/"
             "/__pycache__/"
             ".gitignore"
             ".cvsignore"
             ".DS_Store")))
         (buf (get-buffer-create "*dired-dump*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "### Dump of %s\n\n" dir))
        (dolist (file (directory-files-recursively dir ".*" t))
          (let ((truename (file-truename file)))
            (when (and (file-regular-p truename)
                       (not (string-match-p ignore-regexp truename)))
              (let ((rel (file-relative-name truename dir)))
                (insert (format ">>> %s\n" rel))
                (insert-file-contents truename)
                (goto-char (point-max))
                (insert "\n\n")))))))
    (pop-to-buffer buf)))


(defun select-token-at-point ()
  "Select the contiguous non-whitespace text around point."
  (interactive)
  (skip-syntax-backward "^ ")
  (set-mark (point))
  (skip-syntax-forward "^ ")
  (exchange-point-and-mark))




(defvar my/consult-xlsx-python
  "/Users/max/projects/helpers_utils/.venv/bin/python"
  "Python interpreter used for XLSX search.")

(defvar my/consult-xlsx-script
  "/Users/max/projects/helpers_utils/search_xlsx_emacs.py"
  "Python script that searches inside XLSX files.")


(defun my/consult-xlsx ()
  "Async XLSX search using consult."
  (interactive)
  (unless (and (file-executable-p my/consult-xlsx-python)
               (file-exists-p my/consult-xlsx-script))
    (user-error "XLSX search: Python or script not found"))
  (let ((default-directory (consult-dir--pick "XLSX directory: ")))
    (consult--read
     (consult--async-command
      (lambda (input)
        (if (>= (length input) 2)
            (list my/consult-xlsx-python
                  my/consult-xlsx-script
                  input
                  default-directory)
          '(""))))
     :prompt "XLSX search: "
     :category 'file
     :require-match t
     :sort nil
     :state nil)))