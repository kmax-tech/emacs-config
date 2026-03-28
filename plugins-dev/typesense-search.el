;;; typesense-search.el --- Typesense + Consult search -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'json)
(require 'consult)
(require 'subr-x)
(require 'url)
(require 'tabulated-list)

(defvar typesense-rpc-url "http://localhost:5000"
  "URL of the Typesense RPC server.")

;; Buffer-mode filters (persist across searches in results buffer)
(defvar typesense-buffer-file-extension nil
  "File extension filter for buffer mode.")

(defvar typesense-buffer-path-filter nil
  "Path filter for buffer mode.")

(defvar typesense-max-results 100
  "Number of results to return.")

(defvar typesense-fields '("name" "path")
  "Fields to search in.")

(defvar typesense-search-history nil
  "Input history for Typesense search.")

(defvar typesense-last-results nil
  "Last search results for the results buffer.")

(defvar typesense-last-query nil
  "Last search query.")

(defvar typesense-all-entries nil
  "Backup of all entries before narrowing.")

(defvar typesense-narrow-filter nil
  "Current narrow filter string.")

(defvar typesense-favorite-paths nil
  "Cached favorite paths from server.")

;; ============================================================
;; RPC Communication
;; ============================================================

(defun typesense-rpc-call (method params)
  "Call RPC METHOD with PARAMS, return result or signal error."
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/json")))
         (request `((jsonrpc . "2.0")
                    (id . 1)
                    (method . ,method)
                    (params . ,(or params (make-hash-table)))))
         (url-request-data (encode-coding-string (json-encode request) 'utf-8))
         (response-buffer (url-retrieve-synchronously typesense-rpc-url t)))
    (if (not response-buffer)
        (error "Failed to connect to RPC server at %s" typesense-rpc-url)
      (with-current-buffer response-buffer
        (goto-char (point-min))
        (re-search-forward "^$")
        (let* ((json-object-type 'alist)
               (json-array-type 'list)
               (json-key-type 'symbol)
               (json-false nil)
               (json (json-read)))
          (kill-buffer)
          (if-let ((error-data (cdr (assoc 'error json))))
              (error "RPC Error: %s" (cdr (assoc 'message error-data)))
            (cdr (assoc 'result json))))))))

(defun typesense-get-favorite-paths ()
  "Fetch favorite paths from server and cache them."
  (unless typesense-favorite-paths
    (setq typesense-favorite-paths
          (typesense-rpc-call "get_favorite_paths" (make-hash-table))))
  typesense-favorite-paths)

(defun typesense-select-favorite-path ()
  "Prompt user to select a favorite path or enter custom path."
  (let* ((favorites (typesense-get-favorite-paths))
         (choices (mapcar (lambda (fav)
                           (let ((key (symbol-name (car fav)))
                                 (path (cdr fav)))
                             (cons (format "%s (%s)" key path) key)))
                         favorites))
         (all-choices (append '(("Clear path filter" . "clear"))
                             choices
                             '(("Custom path..." . "custom"))))
         (selection (completing-read "Select path: " 
                                    (mapcar #'car all-choices)
                                    nil t)))
    (let ((key (cdr (assoc selection all-choices))))
      (cond
       ((string= key "clear") nil)  ; Return nil to clear filter
       ((string= key "custom") (read-directory-name "Custom path: "))
       (t key)))))

(defun typesense-rpc-search (query &optional file-ext path-list)
  "Call the RPC server search method.
Uses provided filters or nil (no filters for quick search).
Sorting is done client-side in Emacs."
  (let ((params `((query . ,query)
                  (nbr . ,typesense-max-results)
                  ,@(when file-ext
                      `((file_extension . ,file-ext)))
                  ,@(when path-list
                      `((path . ,path-list))))))
    (typesense-rpc-call "search" params)))

;; ============================================================
;; Consult Integration (quick search - NO persistent filters)
;; ============================================================

(defun typesense--format-hit (hit idx)
  "Turn HIT plist into a Consult candidate string."
  (let* ((file (plist-get hit :file))
         (title (or (plist-get hit :title)
                    (and file (file-name-nondirectory file))
                    "Result"))
         (is-dir (plist-get hit :is-dir))
         (cand (concat title (if is-dir "/" ""))))
    (setq cand (consult--tofu-append cand idx))
    (add-text-properties
     0 1
     `(typesense-file ,file
                      typesense-ext ,(plist-get hit :ext)
                      typesense-mtime ,(plist-get hit :mtime)
                      typesense-is-dir ,is-dir)
     cand)
    cand))

(defun typesense--annotate (cand)
  "Annotate CAND with file info and modification time."
  (let ((file (get-text-property 0 'typesense-file cand))
        (ext (get-text-property 0 'typesense-ext cand))
        (mtime (get-text-property 0 'typesense-mtime cand)))
    (concat
     (when ext
       (format " .%s" (propertize ext 'face 'font-lock-type-face)))
     (when file
       (format "  %s"
               (propertize (abbreviate-file-name (file-name-directory file))
                           'face 'consult-file)))
     (when mtime
       (format "  %s"
               (propertize
                (format-time-string "%Y-%m-%d %H:%M"
                                    (seconds-to-time (/ mtime 1000)))
                'face 'font-lock-comment-face))))))

(defun typesense--state ()
  "State function for preview and jump."
  (let ((open (consult--temporary-files))
        (jump (consult--jump-state)))
    (lambda (action cand)
      (unless cand
        (funcall open))
      (funcall jump action
               (when cand
                 (let ((file (get-text-property 0 'typesense-file cand)))
                   (when file
                     (consult--marker-from-line-column
                      (funcall (if (eq action 'return)
                                   #'consult--file-action
                                 open)
                               file)
                      1 0))))))))

(defun typesense--candidates (input)
  "Compute candidates for INPUT. No persistent filters."
  (let ((query (string-trim input)))
    (when (not (string-empty-p query))
      (condition-case err
          (let* ((response (typesense-rpc-search query nil nil))
                 (hits (cdr (assoc 'hits response))))
            (cl-loop for hit in hits
                     for idx from 0
                     collect (typesense--format-hit
                              (list :file (cdr (assoc 'path hit))
                                    :title (cdr (assoc 'name hit))
                                    :ext (cdr (assoc 'file_extension hit))
                                    :mtime (cdr (assoc 'modified_time hit))
                                    :is-dir (cdr (assoc 'is_dir hit)))
                              idx)))
        (error
         (message "Typesense search error: %s" err)
         nil)))))

;;;###autoload
(defun typesense-search (&optional initial)
  "Quick search with Consult (no persistent filters).
Optional INITIAL is inserted into the minibuffer as initial input."
  (interactive
   (list (if (use-region-p)
             (buffer-substring-no-properties (region-beginning) (region-end))
           nil)))
  (typesense-ensure-server)  
  (consult--read
   (consult--dynamic-collection #'typesense--candidates)
   :prompt "Typesense: "
   :initial initial
   :sort nil
   :require-match t
   :category 'file
   :lookup #'consult--lookup-member
   :annotate #'typesense--annotate
   :state (typesense--state)
   :history '(:input typesense-search-history)))

;; ============================================================
;; Results Buffer (Dired-like interface with persistent filters)
;; ============================================================

(defvar typesense-results-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'typesense-results-open-file)
    (define-key map (kbd "o") 'typesense-results-open-file-other-window)
    (define-key map (kbd "g") 'typesense-results-refresh)
    (define-key map (kbd "s") 'typesense-results-new-search)
    (define-key map (kbd "f") 'typesense-results-filter)
    (define-key map (kbd "c") 'typesense-results-clear-filters)
    (define-key map (kbd "P") 'typesense-results-set-path)  ; Capital P
    (define-key map (kbd "/") 'typesense-results-narrow)
    (define-key map (kbd "\\") 'typesense-results-widen)
    (define-key map (kbd "F") 'typesense-results-open-in-finder)
    (define-key map (kbd "n") 'next-line)
    (define-key map (kbd "p") 'previous-line)  ; Lowercase p for previous
    (define-key map (kbd "q") 'quit-window)
    (define-key map (kbd "r") 'typesense-results-reveal-in-finder)
    map)
  "Keymap for `typesense-results-mode'.")

(define-derived-mode typesense-results-mode tabulated-list-mode "Typesense"
  "Major mode for browsing Typesense search results.

\\{typesense-results-mode-map}"
  (setq tabulated-list-format
        [("Name" 40 t)
         ("Size" 10 t :right-align t)
         ("Modified" 20 t)
         ("Path" 0 t)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "Modified" t))
  (tabulated-list-init-header))

(defun typesense-results--format-size (bytes)
  "Format BYTES as human-readable size."
  (cond
   ((< bytes 1024) (format "%dB" bytes))
   ((< bytes (* 1024 1024)) (format "%.1fK" (/ bytes 1024.0)))
   ((< bytes (* 1024 1024 1024)) (format "%.1fM" (/ bytes 1024.0 1024.0)))
   (t (format "%.1fG" (/ bytes 1024.0 1024.0 1024.0)))))

(defun typesense-results--populate ()
  "Populate the results buffer with current search results."
  (let ((hits (cdr (assoc 'hits typesense-last-results)))
        (entries '()))
    (dolist (hit hits)
      (let* ((path (cdr (assoc 'path hit)))
             (name (cdr (assoc 'name hit)))
             (mtime (cdr (assoc 'modified_time hit)))
             (is-dir (cdr (assoc 'is_dir hit)))
             (size-bytes (or (and (file-exists-p path) 
                                 (file-attribute-size (file-attributes path))) 0))
             (display-name (concat name (if is-dir "/" "")))
             (display-size (if is-dir "-" (typesense-results--format-size size-bytes)))
             (display-mtime (if mtime
                                (format-time-string "%Y-%m-%d %H:%M"
                                                  (seconds-to-time (/ mtime 1000)))
                              "unknown"))
             (display-path (abbreviate-file-name (file-name-directory path))))
        (push (list path
                    (vector display-name
                            display-size
                            display-mtime
                            display-path))
              entries)))
    (setq tabulated-list-entries (nreverse entries))
    (setq typesense-all-entries tabulated-list-entries)
    (tabulated-list-print t)))

(defun typesense-results--format-filter-string ()
  "Format current filters for display in header."
  (let ((parts '()))
    (when typesense-buffer-file-extension
      (push (format "ext:%s" typesense-buffer-file-extension) parts))
    (when typesense-buffer-path-filter
      (push (format "path:%s" (car typesense-buffer-path-filter)) parts))
    (when typesense-narrow-filter
      (push (format "narrow:%s" typesense-narrow-filter) parts))
    (if parts
        (concat " | Filters: " (string-join parts ", "))
      "")))

(defun typesense-results--entry-matches-p (entry filter)
  "Return non-nil if ENTRY matches FILTER string."
  (let* ((path (car entry))
         (data (cadr entry))
         (name (aref data 0))
         (dir-path (aref data 3))
         (search-text (downcase (concat name " " path " " dir-path)))
         (filter-words (split-string (downcase filter) nil t)))
    (cl-every (lambda (word) (string-match-p (regexp-quote word) search-text))
              filter-words)))

(defun typesense-results-narrow (filter)
  "Narrow results buffer to entries matching FILTER.
FILTER is a space-separated list of words. All words must match."
  (interactive "sNarrow (space-separated words): ")
  (if (string-empty-p filter)
      (typesense-results-widen)
    (setq typesense-narrow-filter filter)
    (let ((filtered-entries
           (cl-remove-if-not
            (lambda (entry) (typesense-results--entry-matches-p entry filter))
            typesense-all-entries)))
      (setq tabulated-list-entries filtered-entries)
      (tabulated-list-print t)
      (goto-char (point-min))
      (message "Narrowed to %d/%d results" 
               (length filtered-entries) 
               (length typesense-all-entries)))
    (typesense-results--update-header)))

(defun typesense-results-widen ()
  "Remove narrowing and show all results."
  (interactive)
  (setq typesense-narrow-filter nil)
  (setq tabulated-list-entries typesense-all-entries)
  (tabulated-list-print t)
  (goto-char (point-min))
  (message "Showing all %d results" (length typesense-all-entries))
  (typesense-results--update-header))

(defun typesense-results--update-header ()
  "Update header line with current filter info."
  (when typesense-last-query
    (let ((total (cdr (assoc 'total_hits typesense-last-results)))
          (time-ms (cdr (assoc 'processing_time_ms typesense-last-results)))
          (shown (length tabulated-list-entries)))
      (setq header-line-format
            (format "Search: %s | Showing %d/%d | %dms%s | [g]refresh [s]search [P]ath [f]ilter [/]narrow [\\]widen [c]lear [F]inder [q]uit"
                    typesense-last-query shown total time-ms
                    (typesense-results--format-filter-string))))))

(defun typesense-results-open-file ()
  "Open file at point."
  (interactive)
  (when-let ((path (tabulated-list-get-id)))
    (find-file path)))

(defun typesense-results-open-file-other-window ()
  "Open file at point in other window."
  (interactive)
  (when-let ((path (tabulated-list-get-id)))
    (find-file-other-window path)))

(defun typesense-results-refresh ()
  "Re-run the last search query."
  (interactive)
  (when typesense-last-query
    (setq typesense-narrow-filter nil)
    (message "Refreshing search for: %s..." typesense-last-query)
    (typesense-results-do-search typesense-last-query)))

(defun typesense-results-new-search (query)
  "Run a new search from the results buffer."
  (interactive "sNew search: ")
  (setq typesense-narrow-filter nil)
  (typesense-results-do-search query))

(defun typesense-results-set-path ()
  "Set path filter using favorite paths."
  (interactive)
  (let ((path (typesense-select-favorite-path)))
    (if path
        (progn
          (setq typesense-buffer-path-filter (list path))
          (setq typesense-narrow-filter nil)
          (when typesense-last-query
            (message "Applying path filter: %s..." path)
            (typesense-results-do-search typesense-last-query)))
      ;; Clear path filter
      (setq typesense-buffer-path-filter nil)
      (setq typesense-narrow-filter nil)
      (when typesense-last-query
        (message "Path filter cleared")
        (typesense-results-do-search typesense-last-query)))))

(defun typesense-results-filter ()
  "Add/modify filters for current search."
  (interactive)
  (let ((ext (read-string "Extension (empty for none): " 
                          typesense-buffer-file-extension)))
    (setq typesense-buffer-file-extension (if (string-empty-p ext) nil ext))
    (setq typesense-narrow-filter nil)
    (when typesense-last-query
      (message "Applying filters...")
      (typesense-results-do-search typesense-last-query))))

(defun typesense-results-clear-filters ()
  "Clear all filters and re-run search."
  (interactive)
  (setq typesense-buffer-file-extension nil
        typesense-buffer-path-filter nil
        typesense-narrow-filter nil)
  (when typesense-last-query
    (message "Filters cleared")
    (typesense-results-do-search typesense-last-query)))

(defun typesense-results-open-in-finder ()
  "Create Finder aliases for currently visible search results.
If narrowed, only creates aliases for the narrowed selection."
  (interactive)
  (when (not typesense-last-results)
    (user-error "No search results available"))
  
  (let* ((visible-entries (or tabulated-list-entries typesense-all-entries))
         (file-paths (mapcar #'car visible-entries))
         (count (length file-paths))
         (total (length typesense-all-entries))
         (is-narrowed (< count total)))
    
    (when (y-or-n-p 
           (if is-narrowed
               (format "Create Finder aliases for %d narrowed files (of %d total)? " 
                       count total)
             (format "Create Finder aliases for %d files? " count)))
      (message "Creating aliases...")
      (condition-case err
          (let* ((folder-name (format "Search_%s%s"
                                     (replace-regexp-in-string
                                      "[^a-zA-Z0-9_-]" "_"
                                      (or typesense-last-query "results"))
                                     (if is-narrowed
                                         (format "_%s" 
                                                (replace-regexp-in-string
                                                 "[^a-zA-Z0-9_-]" "_"
                                                 typesense-narrow-filter))
                                       "")))
                 (params `((file_paths . ,file-paths)
                          (folder_name . ,folder-name)))
                 (result (typesense-rpc-call "create_aliases" params))
                 (folder (cdr (assoc 'folder_path result)))
                 (file-count (cdr (assoc 'file_count result))))
            (message "✓ Created %d aliases in: %s" file-count folder))
        (error
         (message "✗ Failed to create aliases: %s" (error-message-string err)))))))

(defun typesense-results-reveal-in-finder ()
  "Reveal the file at point in macOS Finder."
  (interactive)
  (when-let ((path (tabulated-list-get-id)))
    (if (file-exists-p path)
        (call-process "open" nil 0 nil "-R" path)
      (message "File not found: %s" path))))

(defun typesense-results-do-search (query)
  "Execute search for QUERY using buffer-mode filters."
  (typesense-ensure-server)   
  (condition-case err
      (let ((response (typesense-rpc-search 
                      query 
                      typesense-buffer-file-extension
                      typesense-buffer-path-filter)))
        (setq typesense-last-results response)
        (setq typesense-last-query query)
        (let ((total (cdr (assoc 'total_hits response)))
              (time-ms (cdr (assoc 'processing_time_ms response))))
          (with-current-buffer (get-buffer-create "*Typesense Results*")
            (typesense-results-mode)
            (setq header-line-format
                  (format "Search: %s | %d results | %dms%s | [g]refresh [s]search [P]ath [f]ilter [/]narrow [\\]widen [c]lear [F]inder [q]uit"
                          query total time-ms
                          (typesense-results--format-filter-string)))
            (typesense-results--populate)
            (goto-char (point-min)))
          (switch-to-buffer "*Typesense Results*")))
    (error
     (message "Search failed: %s" (error-message-string err))
     (let ((buf (get-buffer "*Typesense Errors*")))
       (when buf (kill-buffer buf)))
     (with-current-buffer (get-buffer-create "*Typesense Errors*")
       (erase-buffer)
       (insert (format "Error: %s\n\n" (error-message-string err)))
       (insert "This usually means:\n")
       (insert "1. RPC server is not running (try: python main_rpc.py serve)\n")
       (insert "2. Server returned an error\n")
       (insert "3. Network/connection issue\n\n")
       (insert (format "RPC URL: %s\n" typesense-rpc-url))
       (special-mode))
     (display-buffer "*Typesense Errors*"))))

;;;###autoload
(defun typesense-search-buffer (query)
  "Search files and display results in a dedicated buffer.
QUERY is the search string. Filters persist in buffer mode."
  (interactive "sSearch: ")
  (typesense-results-do-search query))

;;;###autoload
(defun typesense-search-in-path (path)
  "Search in a specific favorite path."
  (interactive (list (typesense-select-favorite-path)))
  (setq typesense-buffer-path-filter (list path))
  (call-interactively 'typesense-search-buffer))

;; ============================================================
;; Finder Integration - Quick Commands
;; ============================================================

(defun typesense-search-and-open-finder (query)
  "Search and immediately open all results in Finder."
  (interactive "sSearch for Finder: ")
  (condition-case err
      (let* ((folder-name (format "Search_%s"
                                 (replace-regexp-in-string
                                  "[^a-zA-Z0-9_-]" "_" query)))
             (params `((query . ,query)
                      (file_extension . ,typesense-buffer-file-extension)
                      (folder_name . ,folder-name)))
             (result (typesense-rpc-call "create_aliases" params))
             (folder (cdr (assoc 'folder_path result)))
             (count (cdr (assoc 'file_count result))))
        (message "✓ Opened %d files in Finder: %s" count folder))
    (error
     (message "✗ Search failed: %s" (error-message-string err)))))

;; ============================================================
;; Server Management
;; ============================================================

(defun typesense-rebuild-index ()
  "Trigger a full reindex via RPC."
  (interactive)
  (message "Rebuilding index...")
  (condition-case err
      (let* ((result (typesense-rpc-call "rebuild_index" (make-hash-table)))
             (time-ms (cdr (assoc 'time_ms result))))
        (message "✓ Index rebuilt successfully! Time: %.1fms" (or time-ms 0)))
    (error
     (message "✗ Rebuild failed: %s" (error-message-string err)))))


(defvar typesense-start-script "/Users/max/projects/typesense-search/start_rpc.sh"
  "Path to the shell script that starts the Typesense RPC server.")

(defun typesense--server-running-p ()
  "Return non-nil if the RPC server is reachable."
  (condition-case nil
      (progn (typesense-rpc-call "docker_status" (make-hash-table)) t)
    (error nil)))

(defun typesense--start-server ()
  "Start the RPC server via `typesense-start-script' in the background."
  (cond
   ((typesense--server-running-p)
    (message "✓ Typesense RPC server is already running"))
   ((and (get-process "typesense-rpc")
         (process-live-p (get-process "typesense-rpc")))
    (message "Typesense RPC server is already starting..."))
   ((not (file-executable-p typesense-start-script))
    (error "Start script not found or not executable: %s" typesense-start-script))
   (t
    (message "Starting Typesense RPC server...")
    (start-process "typesense-rpc" "*Typesense RPC*" typesense-start-script)
    (let ((attempts 0)
          (max-attempts 10))
      (while (and (< attempts max-attempts)
                  (not (typesense--server-running-p)))
        (sleep-for 0.5)
        (cl-incf attempts))
      (if (typesense--server-running-p)
          (message "✓ Typesense RPC server started successfully")
        (error "✗ Server did not respond after %.1fs — check *Typesense RPC* buffer"
               (* max-attempts 0.5)))))))

(defun typesense-server-status ()
  "Check server status, offering to start it if not running."
  (interactive)
  (if (typesense--server-running-p)
      (message "✓ RPC server is running at %s" typesense-rpc-url)
    (if (y-or-n-p "Typesense RPC server is not running. Start it now? ")
        (typesense--start-server)
      (message "Server not started"))))

(defun typesense-ensure-server ()
  "Ensure the RPC server is running, starting it automatically if needed.
Call this from search commands to auto-start on first use."
  (unless (typesense--server-running-p)
    (message "Typesense server not running, starting...")
    (typesense--start-server)))

;; ============================================================
;; Convenience Functions (set filter then call buffer mode)
;; ============================================================

(defun typesense-search-pdf ()
  "Search only PDF files in buffer mode."
  (interactive)
  (setq typesense-buffer-file-extension "pdf")
  (call-interactively 'typesense-search-buffer))

(defun typesense-search-org ()
  "Search only Org files in buffer mode."
  (interactive)
  (setq typesense-buffer-file-extension "org")
  (call-interactively 'typesense-search-buffer))

(provide 'typesense-search)
;;; typesense-search.el ends here