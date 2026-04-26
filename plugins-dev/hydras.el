;; All hydra definitions

;; Master hydra menu - press C-c h to pick a hydra
(defhydra hydra-master (:hint nil :color blue :foreign-keys warn)
  "
 ^Hydra Menu^
 ^^^^^^^^──────────────────────────────────
 _n_: navigate        _g_: git
 _s_: search          _w_: window
 _e_: edit            _a_: second brain
 _k_: kubernetes      _r_: remote/SSH
 _t_: LaTeX           _q_: quit
"
  ("n" hydra-navigate/body)
  ("s" hydra-search/body)
  ("e" hydra-edit/body)
  ("g" hydra-git/body)
  ("w" hydra-window/body)
  ("a" hydra-second-brain/body)
  ("k" hydra-kubernetes/body)
  ("r" hydra-remote/body)
  ("t" hydra-latex/body)
  ("q" nil))

(global-set-key (kbd "C-c h") 'hydra-master/body)

;; Navigation hydra - press C-c n to navigate
(defhydra hydra-navigate (:hint nil :color pink :foreign-keys warn)
  "
 ^Buffers^                                ^Lines^                  ^Jump^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────
 _n_: next-buffer (C-x <right>)           _j_: next-line           _g_: goto-line (M-g g)
 _p_: previous-buffer (C-x <left>)        _k_: previous-line       _i_: consult-imenu
 _b_: consult-buffer (C-x b)              _f_: forward-word        _m_: consult-bookmark (C-x r b)
 ^^                                        _w_: backward-word       _o_: consult-outline
 ^^
 ^Code^                                   ^Sexp^                   ^Structure^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────
 _._: xref-find-definitions (M-.)          _F_: forward-sexp (C-M-f)   _a_: beginning-of-defun (C-M-a)
 _,_: xref-go-back (M-,)                  _W_: backward-sexp (C-M-b)  _e_: end-of-defun (C-M-e)
 _?_: xref-find-references (M-?)          _u_: backward-up-list (C-M-u)
 ^^
 _q_: quit
"
  ("n" next-buffer)
  ("p" previous-buffer)
  ("b" consult-buffer :color blue)
  ("j" next-line)
  ("k" previous-line)
  ("f" forward-word)
  ("w" backward-word)
  ("g" goto-line :color blue)
  ("i" consult-imenu :color blue)
  ("m" consult-bookmark :color blue)
  ("o" consult-outline :color blue)
  ("." xref-find-definitions :color blue)
  ("," xref-go-back :color blue)
  ("?" xref-find-references :color blue)
  ("F" forward-sexp)
  ("W" backward-sexp)
  ("u" backward-up-list)
  ("a" beginning-of-defun)
  ("e" end-of-defun)
  ("q" nil :color blue))

(global-set-key (kbd "C-c n") 'hydra-navigate/body)

;; Search hydra - press C-c s to search
(defhydra hydra-search (:hint nil :color blue :foreign-keys warn)
  "
 ^Buffer^                                           ^Files^                                        ^Replace^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────────
 _s_: consult-line (C-s)                             _g_: consult-grep (M-s g)                      _r_: query-replace
 _S_: my/consult-line-symbol-at-point (M-s M-.)      _G_: consult-ripgrep (M-s r)                   _R_: query-replace-regexp
 _._: my/consult-line-dwim (M-s .)                   _f_: consult-fd-preview (M-s f)                _o_: occur
 ^^                                                   _F_: consult-recent-file (C-x C-r)
 ^Navigate^                                          ^Buffers^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────────
 _d_: consult-dir (C-x C-d)                          _b_: consult-buffer (C-x b)
 _i_: consult-imenu                                   _B_: consult-project-buffer (C-c f b)
 _l_: consult-outline                                 _m_: consult-bookmark (C-x r b)
 ^^
 _q_: quit
"
  ("s" consult-line)
  ("S" my/consult-line-symbol-at-point)
  ("." my/consult-line-dwim)
  ("o" occur)
  ("r" query-replace)
  ("R" query-replace-regexp)
  ("g" consult-grep)
  ("G" consult-ripgrep)
  ("f" consult-fd-preview)
  ("F" consult-recent-file)
  ("d" consult-dir)
  ("b" consult-buffer)
  ("B" consult-project-buffer)
  ("i" consult-imenu)
  ("l" consult-outline)
  ("m" consult-bookmark)
  ("q" nil))

(global-set-key (kbd "C-c s") 'hydra-search/body)

;; Editing hydra - press C-c e to edit
(defhydra hydra-edit (:hint nil :color pink :foreign-keys warn)
  "
 ^Text Scale^                      ^Undo^                          ^Case^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────
 _+_: text-scale-increase           _u_: undo (C-/)                 _c_: capitalize-word (M-c)
 _-_: text-scale-decrease           _r_: undo-redo (C-?)            _l_: downcase-word (M-l)
 _0_: text-scale-set 0             ^^                               _U_: upcase-word (M-u)
 ^^
 ^Lines^                                                          ^Diff^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────
 _d_: duplicate-line                _s_: sort-lines                  _D_: diff-buffer-with-autosave (C-c d)
 ^^                                 _a_: align-regexp                _F_: diff-buffer-with-file (C-c D)
 _q_: quit
"
  ("+" text-scale-increase)
  ("-" text-scale-decrease)
  ("0" (text-scale-set 0))
  ("u" undo)
  ("r" undo-redo)
  ("c" capitalize-word)
  ("l" downcase-word)
  ("U" upcase-word)
  ("d" duplicate-line)
  ("s" sort-lines :color blue)
  ("a" align-regexp :color blue)
  ("D" diff-buffer-with-autosave :color blue)
  ("F" diff-buffer-with-file :color blue)
  ("q" nil :color blue))

(global-set-key (kbd "C-c e") 'hydra-edit/body)

;; Git hydra - press C-c g for version control
(defhydra hydra-git (:hint nil :color blue :foreign-keys warn)
  "
 ^Status^                               ^Actions^                              ^Navigate^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────
 _s_: vc-dir (C-x v d)                  _c_: vc-next-action (C-x v v)          _n_: vc-next-action
 _d_: vc-diff (C-x v =)                 _l_: vc-print-log (C-x v l)            _b_: vc-annotate (C-x v g)
 _D_: vc-root-diff                       _L_: vc-print-root-log                 _a_: vc-annotate
 ^^                                      _p_: vc-push (C-x v P)                _=_: ediff-current-file
 _~_: vc-revision-other-window (C-x v ~) _r_: vc-revert (C-x v u)
 ^^                                      _E_: ediff-revision
 ^^
 _q_: quit
"
  ("s" vc-dir)
  ("d" vc-diff)
  ("D" vc-root-diff)
  ("c" vc-next-action)
  ("n" vc-next-action)
  ("l" vc-print-log)
  ("L" vc-print-root-log)
  ("b" vc-annotate)
  ("a" vc-annotate)
  ("p" vc-push)
  ("=" ediff-current-file)
  ("E" ediff-revision)
  ("~" vc-revision-other-window)
  ("r" vc-revert)
  ("q" nil))

(global-set-key (kbd "C-c g") 'hydra-git/body)

;; Window management hydra - press C-c w to manage splits
(defhydra hydra-window (:hint nil :color pink :foreign-keys warn)
  "
 ^Move^                              ^Resize^                          ^Split^                         ^Layout^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────────
 _h_/_l_: windmove-left/right         _H_/_L_: shrink/enlarge-window-h   _v_: split-window-right (C-x 3)  _u_: winner-undo
 _j_/_k_: windmove-down/up            _J_/_K_: enlarge/shrink-window     _s_: split-window-below (C-x 2)  _U_: winner-redo
 ^^                                   _=_: balance-windows               _c_: delete-window (C-x 0)       _o_: delete-other-windows (C-x 1)
 ^^                                   ^^                                ^^                                _S_: window-swap-states
 ^^
 ^Buffer^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────────
 _b_: switch-to-buffer (C-x b)       _f_: find-file (C-x C-f)          _d_: dired (C-x d)
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

;; Second Brain hydra - press C-c a for knowledge & AI context
(defhydra hydra-second-brain (:hint nil :color blue :foreign-keys warn)
  "
 ^ECA Context^                              ^Knowledge^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────
 _p_: my/eca-add-corresponding-pdf          _i_: my/open-weekly-inbox
 _P_: my/eca-add-all-pdfs-in-dir            _c_: my/copy-corresponding-pdf-path
 ^^                                          _f_: my/copy-file-path
 ^^                                          _n_: remark-create-note
 ^^
 _q_: quit
"
  ("p" my/eca-add-corresponding-pdf)
  ("P" my/eca-add-all-pdfs-in-dir)
  ("i" my/open-weekly-inbox)
  ("c" my/copy-corresponding-pdf-path)
  ("f" my/copy-file-path)
  ("n" remark-create-note)
  ("q" nil))

(global-set-key (kbd "C-c a") 'hydra-second-brain/body)

;; VC/CVS hydra - press ? in vc-dir to see all commands
(defhydra hydra-vc-dir (:hint nil :color pink :foreign-keys run)
  "
 ^Navigation^                    ^Mark^                        ^Actions^                      ^View^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────
 _n_/_p_: vc-dir-next/prev-line   _m_: vc-dir-mark              _v_: vc-next-action             _=_: vc-diff
 _RET_: vc-dir-find-file          _u_: vc-dir-unmark            _a_: vc-dir-register            _l_: vc-print-log
 ^^                               _M_: vc-dir-mark-all-files    _c_: vc-next-action (commit)    _g_: vc-dir-refresh
 ^^                               _U_: vc-dir-unmark-all-files  _D_: vc-dir-delete-file
 ^^                               ^^                            _A_: register+parents (CVS)
 ^^
 ^Compare/Rollback^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────
 _e_: ediff two revisions         _E_: ediff revision vs working copy        _r_: rollback to revision
 ^^
 ^State reference^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────
 up-to-date = clean    edited = modified    added = staged
 removed = to delete   unregistered = new (use _a_ to add)
 ^^
 _w_: hydra-window    _q_: quit hydra       _?_: describe-mode
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
  ("A" my/vc-cvs-register-with-parents :color blue)
  ("c" vc-next-action :color blue)
  ("D" vc-dir-delete-file :color blue)
  ;; View
  ("=" vc-diff)
  ("l" vc-print-log :color blue)
  ("g" vc-dir-refresh)
  ;; Compare / Rollback
  ("e" my/vc-ediff-revisions :color blue)
  ("E" my/vc-ediff-revision-vs-working :color blue)
  ("r" my/vc-rollback-to-revision :color blue)
  ;; Window / Help / quit
  ("w" hydra-window/body :color blue)
  ("?" describe-mode :color blue)
  ("q" nil :color blue))

;; Diff hydra - press ? in diff buffers to navigate hunks
(defhydra hydra-diff (:hint nil :color pink :foreign-keys run)
  "
 ^Hunk^                        ^File^                        ^Actions^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────
 _n_: diff-hunk-next            _N_: diff-file-next           _a_: diff-apply-hunk
 _p_: diff-hunk-prev            _P_: diff-file-prev           _RET_: diff-goto-source
 ^^                             ^^                            _r_: diff-reverse-direction
 ^^                             ^^                            _e_: diff-ediff-patch
 ^^
 _w_: hydra-window              _q_: quit hydra
"
  ("n" diff-hunk-next)
  ("p" diff-hunk-prev)
  ("N" diff-file-next)
  ("P" diff-file-prev)
  ("a" diff-apply-hunk :color blue)
  ("r" diff-reverse-direction)
  ("e" diff-ediff-patch :color blue)
  ("RET" diff-goto-source :color blue)
  ("w" hydra-window/body :color blue)
  ("q" nil :color blue))

(add-hook 'diff-mode-hook
          (lambda ()
            (define-key diff-mode-map (kbd "?") #'hydra-diff/body)))

(add-hook 'vc-dir-mode-hook
          (lambda ()
            (define-key vc-dir-mode-map (kbd "?") #'hydra-vc-dir/body)))

;; Kubernetes hydra - press C-c h k or ? in kubel buffer
(defhydra hydra-kubernetes (:hint nil :color blue :foreign-keys warn)
  "
 ^Context^                                  ^View^                                  ^Actions^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────
 _N_: kubel-set-namespace                    _d_: kubel-get-resource-details          _l_: kubel-get-pod-logs
 _C_: kubel-set-context                      _R_: kubel-set-resource                  _e_: kubel-exec-vterm-pod
 _s_: kubel                                  _f_: kubel-set-filter                    _p_: kubel-port-forward-pod
 ^^                                          _g_: kubel-refresh                       _D_: kubel-delete-resource
 ^Copy^                                      ^^                                      _S_: kubel-scale-replicas
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────────────────
 _y_: kubel-copy-resource-name               _E_: kubel-quick-edit                    _a_: kubel-apply
 _Y_: kubel-copy-last-command                _h_: kubel-rollout-history               _r_: kubel-rollout-restart
 ^^
 _q_: quit
"
  ("s" kubel)
  ("N" kubel-set-namespace)
  ("C" kubel-set-context)
  ("R" kubel-set-resource)
  ("d" kubel-get-resource-details)
  ("l" kubel-get-pod-logs)
  ("e" kubel-exec-vterm-pod)
  ("p" kubel-port-forward-pod)
  ("D" kubel-delete-resource)
  ("S" kubel-scale-replicas)
  ("f" kubel-set-filter)
  ("g" kubel-refresh)
  ("y" kubel-copy-resource-name)
  ("Y" kubel-copy-last-command)
  ("E" kubel-quick-edit)
  ("h" kubel-rollout-history)
  ("r" kubel-rollout-restart)
  ("a" kubel-apply)
  ("q" nil))

(with-eval-after-load 'kubel
  (define-key kubel-mode-map (kbd "?") #'hydra-kubernetes/body))

;; Remote/SSH hydra - press C-c h r
(defhydra hydra-remote (:hint nil :color blue :foreign-keys warn)
  "
 ^Connect^                                ^Navigate^                              ^Files^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────
 _s_: my/ssh-vterm                         _f_: find-file (C-x C-f)                _c_: copy-remote-file-to-local
 _b_: my/find-file-ssh (C-c f s)           _j_: dired-jump (C-x C-j)               _d_: consult-dir (C-x C-d)
 ^^                                        _h_: dired home dir
 ^^
 _q_: quit
"
  ("s" my/ssh-vterm)
  ("b" my/find-file-ssh)
  ("f" find-file)
  ("j" dired-jump)
  ("h" (lambda () (interactive) (dired default-directory)))
  ("c" copy-remote-file-to-local)
  ("d" consult-dir)
  ("q" nil))

;; LaTeX hydra - press C-c h t or C-c t in LaTeX buffers
(defhydra hydra-latex (:hint nil :color blue :foreign-keys warn)
  "
 ^Build^                              ^View^                               ^Navigate^
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────
 _c_: compile (C-c C-c)               _v_: view PDF (C-c C-v)              _e_: next error (C-c `)
 _b_: compile buffer                  _V_: view output log                 _E_: error overview
 _a_: compile all (master)            ^^                                   _=_: TOC (reftex)
 ^^                                   ^^                                   _(_: beginning of env
 ^Insert^                             ^Mark/Select^                        _)_: end of env
 ^^^^^^^^──────────────────────────────────────────────────────────────────────────────────────────
 _n_: environment (C-c C-e)           _._: mark environment                _m_: set master file
 _s_: section (C-c C-s)               _*_: mark section                    _p_: project files (C-c f f)
 _]_: close environment (C-c ])       ^^                                   _f_: fold/unfold (C-c C-o C-o)
 _\\_: macro (C-c RET)                ^^
 ^^
 _w_: hydra-window                    _q_: quit
"
  ;; Build
  ("c" TeX-command-master)
  ("b" TeX-command-buffer)
  ("a" (lambda () (interactive) (TeX-command "LatexMk" 'TeX-master-file)))
  ;; View
  ("v" TeX-view)
  ("V" TeX-recenter-output-buffer)
  ;; Navigate
  ("e" TeX-next-error)
  ("E" TeX-error-overview)
  ("=" reftex-toc)
  ("(" LaTeX-find-matching-begin)
  (")" LaTeX-find-matching-end)
  ;; Insert
  ("n" LaTeX-environment)
  ("s" LaTeX-section)
  ("]" LaTeX-close-environment)
  ("\\" TeX-insert-macro)
  ;; Mark
  ("." LaTeX-mark-environment)
  ("*" LaTeX-mark-section)
  ;; Other
  ("m" (lambda () (interactive)
         (setq-local TeX-master
                     (read-file-name "Master file: " nil nil t))
         (message "Master set to: %s" TeX-master)))
  ("p" project-find-file)
  ("f" TeX-fold-dwim)
  ;; Window / quit
  ("w" hydra-window/body)
  ("q" nil))

(add-hook 'LaTeX-mode-hook
          (lambda ()
            (define-key LaTeX-mode-map (kbd "C-c h") #'hydra-master/body)
            (define-key LaTeX-mode-map (kbd "?") nil)))
