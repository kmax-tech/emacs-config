;; ====================
;; SECOND BRAIN / KNOWLEDGE MANAGEMENT
;; ====================

(defvar my/inbox-directory "~/work/inbox/"
  "Directory for weekly inbox markdown files.")

(defun my/inbox-week-file ()
  "Return the path for this week's inbox file (e.g. 2026-W14.md)."
  (let ((week-string (format-time-string "%G-W%V")))
    (expand-file-name (concat week-string ".md") my/inbox-directory)))

(defun my/open-weekly-inbox ()
  "Open (or create) this week's inbox markdown file in ~/work/inbox/.
The file is named by ISO week, e.g. 2026-W14.md."
  (interactive)
  (let ((file (my/inbox-week-file)))
    (unless (file-directory-p my/inbox-directory)
      (make-directory my/inbox-directory t))
    (find-file file)
    (when (= (buffer-size) 0)
      (insert (format "# Inbox — %s\n\n" (format-time-string "%G-W%V")))
      (insert (format "Week of %s\n\n" (format-time-string "%B %d, %Y")))
      (insert "## Notes\n\n- "))
    (goto-char (point-max))))

(defun my/copy-corresponding-pdf-path ()
  "Copy the path of the PDF corresponding to the current markdown file.
Expects a .pdf file with the same base name in the same directory."
  (interactive)
  (let* ((md-file (buffer-file-name)))
    (unless md-file
      (user-error "Buffer is not visiting a file"))
    (unless (string-match-p "\\.md\\'" md-file)
      (user-error "Current file is not a markdown file"))
    (let ((pdf-file (concat (file-name-sans-extension md-file) ".pdf")))
      (unless (file-exists-p pdf-file)
        (user-error "No corresponding PDF found: %s" pdf-file))
      (kill-new pdf-file)
      (message "Copied to clipboard: %s" pdf-file))))

(defun my/copy-file-path ()
  "Copy the full path of the current buffer's file to the clipboard."
  (interactive)
  (let ((file (buffer-file-name)))
    (unless file
      (user-error "Buffer is not visiting a file"))
    (kill-new file)
    (message "Copied: %s" file)))

(defun remark-create-note (title)
  "Create a note via remark-refs socket server."
  (interactive "sNote title: ")
  (let* ((json (format "{\"command\":\"create\",\"title\":\"%s\"}" title))
         (raw (shell-command-to-string
               (format "echo '%s' | nc -U /tmp/remark-refs.sock" json)))
         (resp (json-parse-string raw :object-type 'alist))
         (content (alist-get 'content resp))
         (filename (concat (replace-regexp-in-string "[^a-z0-9]+" "-" (downcase title)) ".md"))
         (filepath (expand-file-name filename "~/notes/")))
    (find-file filepath)
    (insert content)
    (save-buffer)))

;; Available via Second Brain hydra (C-c a): i=inbox, c=copy PDF path, f=copy file path
