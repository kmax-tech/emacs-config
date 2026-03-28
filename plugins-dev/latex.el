;; ====================
;; TEX
;; ====================

;; Add TeX binaries to exec-path
;; (add-to-list 'exec-path "/Library/TeX/texbin")

(use-package tex
  :ensure auctex
  :defer t
  :config
  ;; Use latexmk for everything
  (setq TeX-command-default "LatexMk")

  ;; Do NOT ask before saving
  (setq TeX-save-query nil)

  ;; Let AUCTeX parse files to detect packages (natbib, etc.) for highlighting
  (setq TeX-auto-save nil
        TeX-parse-self t
        TeX-electric-math nil
        TeX-electric-sub-and-superscript nil)

  (add-to-list 'TeX-command-list
               '("LatexMk" "latexmk -pdf -synctex=1 -interaction=nonstopmode %s"
                 TeX-run-TeX nil t))

  ;; Error navigation
  (setq TeX-error-overview-open-after-TeX-run t)

  ;; Always use PDF mode
  (setq TeX-PDF-mode t)

  (setq TeX-view-program-selection '((output-pdf "Sioyek")))

  (setq TeX-view-program-list
        '(("Sioyek"
           "sioyek --reuse-window --forward-search-file %b --forward-search-line %n %o"))))


(defun my-latex-detect-master ()
  "Heuristically determine the LaTeX master file.

Preference order:
1. *frame.tex
2. *.slides.tex
3. current file"
  (let* ((dir (file-name-directory (buffer-file-name)))
         (candidates
          (append
           (file-expand-wildcards (concat dir "*frame.tex"))
           (file-expand-wildcards (concat dir "*.slides.tex")))))
    (cond
     (candidates
      (file-name-nondirectory (car candidates)))
     (t
      t)))) ;; `t` means “this file is the master”

(add-hook 'LaTeX-mode-hook
          (lambda ()
            (setq-local TeX-master (my-latex-detect-master))))
