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

;; Back/forward navigation across buffers (like browser back/forward)
(global-set-key (kbd "C-c <left>") 'pop-global-mark)
(global-set-key (kbd "C-c <right>") 'next-buffer)

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
(global-set-key (kbd "C-c D") 'diff-buffer-with-file)

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



;; ====================
;; ECA PDF CONTEXT HELPERS
;; ====================

;; ====================
;; VC EDIFF WITH REVISION PICKER
;; ====================

(defun my/vc-revision-list (file)
  "Return alist of (DISPLAY . REVISION) for FILE's version history."
  (let ((backend (vc-backend file)))
    (cond
     ((eq backend 'CVS)
      (let ((output (let ((default-directory (file-name-directory file)))
                      (shell-command-to-string
                       (format "cvs log -N %s 2>/dev/null"
                               (shell-quote-argument (file-name-nondirectory file))))))
            result rev date author msg)
        (with-temp-buffer
          (insert output)
          (goto-char (point-min))
          (while (re-search-forward "^revision \\([0-9.]+\\)" nil t)
            (setq rev (match-string 1))
            (setq date "")
            (setq author "")
            (setq msg "")
            (when (re-search-forward
                   "^date: \\([^;]+\\);\\s-+author: \\([^;]+\\)" nil t)
              (setq date (match-string 1))
              (setq author (match-string 2)))
            (forward-line 1)
            (let ((start (point)))
              (if (re-search-forward "^----------------------------$\\|^=====" nil t)
                  (setq msg (string-trim
                             (buffer-substring-no-properties start (match-beginning 0))))
                (setq msg (string-trim
                           (buffer-substring-no-properties start (point-max))))))
            (let ((first-line (car (split-string msg "\n"))))
              (push (cons (format "%-10s  %s  %-12s  %s"
                                  rev date author first-line)
                          rev)
                    result))))
        (nreverse result)))
     ((memq backend '(Git git))
      (let ((output (shell-command-to-string
                     (format "git log --pretty=format:%%H%%x09%%h%%x09%%ai%%x09%%an%%x09%%s -- %s"
                             (shell-quote-argument file))))
            result)
        (dolist (line (split-string output "\n" t))
          (let* ((parts (split-string line "\t"))
                 (full-hash (nth 0 parts))
                 (short-hash (nth 1 parts))
                 (date (nth 2 parts))
                 (author (nth 3 parts))
                 (subject (nth 4 parts)))
            (push (cons (format "%-8s  %s  %-12s  %s"
                                short-hash date author subject)
                        full-hash)
                  result)))
        (nreverse result)))
     (t (error "Unsupported VC backend: %s" backend)))))

(defun my/vc-ediff-revisions ()
  "Pick two revisions from version history and ediff them.
Shows revision log with date/author/message for easy selection."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "Not visiting a file")))
         (candidates (my/vc-revision-list file))
         (pick1 (completing-read "Revision A (older): " candidates nil t))
         (rev1 (cdr (assoc pick1 candidates)))
         (pick2 (completing-read "Revision B (newer): " candidates nil t))
         (rev2 (cdr (assoc pick2 candidates)))
         (buf1 (vc-find-revision file rev1))
         (buf2 (vc-find-revision file rev2)))
    (ediff-buffers buf1 buf2)))

(defun my/vc-ediff-revision-vs-working ()
  "Pick a revision from history and ediff it against the working copy."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "Not visiting a file")))
         (candidates (my/vc-revision-list file))
         (pick (completing-read "Compare working copy against: " candidates nil t))
         (rev (cdr (assoc pick candidates)))
         (rev-buf (vc-find-revision file rev)))
    (ediff-buffers rev-buf (current-buffer))))

(defun my/vc-rollback-to-revision ()
  "Pick a revision from history and replace the current file with it.
Shows revision log for selection, previews in ediff, then asks for confirmation.
For CVS, uses the safe temp-file approach to avoid truncation."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (error "Not visiting a file")))
         (backend (vc-backend file))
         (candidates (my/vc-revision-list file))
         (pick (completing-read "Rollback to revision: " candidates nil t))
         (rev (cdr (assoc pick candidates))))
    (when (yes-or-no-p (format "Replace %s with revision %s? "
                               (file-name-nondirectory file) rev))
      (cond
       ((eq backend 'CVS)
        (let ((tmp (concat file ".tmp")))
          (let ((exit-code (call-process "cvs" nil nil nil
                                         "update" "-p" "-r" rev
                                         (file-name-nondirectory file))))
            ;; call-process with nil output discards; redo with file output
            (with-temp-file tmp
              (call-process "cvs" nil t nil
                            "update" "-p" "-r" rev
                            (file-name-nondirectory file)))
            (rename-file tmp file t))))
       ((memq backend '(Git git))
        (call-process "git" nil nil nil
                      "checkout" rev "--" file))
       (t (error "Unsupported backend: %s" backend)))
      (revert-buffer t t)
      (message "Rolled back %s to revision %s"
               (file-name-nondirectory file) rev))))

(global-set-key (kbd "C-c v e") 'my/vc-ediff-revisions)
(global-set-key (kbd "C-c v w") 'my/vc-ediff-revision-vs-working)
(global-set-key (kbd "C-c v r") 'my/vc-rollback-to-revision)

;; ====================
;; CVS: REGISTER WITH PARENT DIRECTORIES
;; ====================

(defun my/vc-cvs-register-with-parents ()
  "Register marked files in vc-dir, adding parent directories first.
CVS requires `cvs add dir` before `cvs add dir/file`.  This
function collects all unregistered parent directories of the
marked (or current) files, adds them in depth-first order, then
registers the files themselves."
  (interactive)
  (unless (derived-mode-p 'vc-dir-mode)
    (user-error "Not in a vc-dir buffer"))
  (let* ((root (vc-root-dir))
         ;; Get marked files (or file at point)
         (files (or (vc-dir-marked-files)
                    (list (vc-dir-current-file))))
         (dirs-to-add '()))
    ;; Collect unregistered parent directories
    (dolist (file files)
      (let* ((full (expand-file-name file))
             (rel (file-relative-name full root))
             (dir (file-name-directory rel)))
        (when dir
          ;; Walk up from the file's directory to root, collecting
          ;; any directory that has no CVS/ subdirectory
          (let ((parts (split-string (directory-file-name dir) "/" t)))
            (let ((path ""))
              (dolist (part parts)
                (setq path (if (string= path "") part (concat path "/" part)))
                (let ((abs-dir (expand-file-name path root)))
                  (unless (file-exists-p (expand-file-name "CVS" abs-dir))
                    (cl-pushnew path dirs-to-add :test #'string=)))))))))
    ;; Add directories in order (shallow first)
    (setq dirs-to-add (sort dirs-to-add
                            (lambda (a b) (< (length a) (length b)))))
    (let ((default-directory root))
      (dolist (dir dirs-to-add)
        (message "cvs add %s" dir)
        (let ((exit (call-process "cvs" nil nil nil "add" dir)))
          (unless (zerop exit)
            (error "Failed: cvs add %s" dir)))))
    ;; Now register the files
    (if dirs-to-add
        (progn
          (message "Added %d director%s, now registering files..."
                   (length dirs-to-add)
                   (if (= 1 (length dirs-to-add)) "y" "ies"))
          (vc-dir-refresh)
          ;; Small delay for vc-dir to pick up the new CVS/ dirs
          (run-with-timer 0.5 nil
                          (lambda ()
                            (with-current-buffer (current-buffer)
                              (vc-register)))))
      (vc-register))))

;; ====================
;; ECA PDF CONTEXT HELPERS
;; ====================

(defun my/eca--other-window-buffer ()
  "Return the buffer displayed in the other window (non-ECA window)."
  (let ((eca-win (selected-window)))
    (catch 'found
      (dolist (win (window-list))
        (unless (eq win eca-win)
          (let ((buf (window-buffer win)))
            (when (buffer-file-name buf)
              (throw 'found buf))))))))

(defun my/eca-add-corresponding-pdf ()
  "Add the PDF corresponding to the markdown file in the other window to ECA context.
Looks at the buffer next to the ECA chat, and if it visits a .md file,
adds the .pdf with the same base name to the chat context."
  (interactive)
  (unless (fboundp 'eca-chat--add-context)
    (user-error "ECA is not loaded"))
  (let* ((buf (my/eca--other-window-buffer)))
    (unless buf
      (user-error "No file buffer found in other window"))
    (let ((file (buffer-file-name buf)))
      (unless (string-match-p "\\.md\\'" file)
        (user-error "Other window is not a markdown file: %s"
                    (file-name-nondirectory file)))
      (let ((pdf (concat (file-name-sans-extension file) ".pdf")))
        (unless (file-exists-p pdf)
          (user-error "No corresponding PDF: %s" pdf))
        (eca-chat--add-context (list :type "file" :path pdf))
        (message "Added to ECA context: %s" (file-name-nondirectory pdf))))))

(defun my/eca-add-all-pdfs-in-dir ()
  "Add all PDFs in the directory of the other window's file to ECA context."
  (interactive)
  (unless (fboundp 'eca-chat--add-context)
    (user-error "ECA is not loaded"))
  (let* ((buf (my/eca--other-window-buffer)))
    (unless buf
      (user-error "No file buffer found in other window"))
    (let* ((dir (file-name-directory (buffer-file-name buf)))
           (pdfs (directory-files dir t "\\.pdf\\'")))
      (unless pdfs
        (user-error "No PDFs found in %s" dir))
      (dolist (pdf pdfs)
        (eca-chat--add-context (list :type "file" :path pdf)))
      (message "Added %d PDF(s) from %s to ECA context"
               (length pdfs) (abbreviate-file-name dir)))))