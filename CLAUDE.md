# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Personal Emacs configuration for macOS (emacs-mac port). Uses `use-package` with MELPA/GNU ELPA for package management. The config targets daily workflows: LaTeX writing, Python development, Kubernetes ops, remote file editing via TRAMP/SSH, and a "second brain" knowledge system.

## Debugging & Testing

```bash
# Debug startup errors
emacs --debug-init --eval "(setq debug-on-error t)"

# Byte-compile check (catches undefined vars, missing requires)
emacs --batch --eval "(byte-compile-file \"~/.emacs.d/init.el\")"

# Batch-load a single plugin file to check for errors
emacs --batch -l ~/.emacs.d/init.el -l ~/.emacs.d/plugins-dev/FILENAME.el
```

There are no automated tests. Verify changes by restarting Emacs or evaluating with `M-x eval-buffer`.

## Architecture

**`init.el`** — Main entry point. Loads in order:
1. Package management (MELPA/GNU ELPA, use-package)
2. Basic settings (macOS modifiers, appearance, encoding)
3. File handling (auto-revert, recentf, backups)
4. Completion stack: Vertico + Orderless + Marginalia + Company
5. Major mode configs (JSON, Markdown, Kubel)
6. TRAMP/SSH remote access
7. Spell checking (hunspell)
8. Python/LSP (tree-sitter, Eglot + pyright, ruff format-on-save)
9. Loads all `plugins-dev/*.el` files explicitly via `load-file`
10. Global keybindings

**`plugins-dev/`** — Custom elisp modules loaded by init.el:
- `hydras.el` — Master hydra menu (`C-c h`) with sub-hydras for navigate, search, edit, git, window, kubernetes, remote, second-brain. Also context hydras for vc-dir (`?`), diff (`?`), dired (`?`), kubel (`?`).
- `consult.el` — Consult/Embark/which-key setup, `consult-fd-preview`, DWIM search, consult-dir with SSH sources, treemacs sidebar, CVS project detection.
- `directory.el` — Dired enhancements: nerd-icons, dual-pane mode, sorting hydra, rsync integration, copy-to-bookmark, GNU ls (`gls`) on macOS.
- `own-functions.el` — Utility functions: rename-current-file, VC ediff with revision picker (supports both Git and CVS), rollback-to-revision, ECA PDF context helpers, XLSX search via external Python script.
- `second-brain.el` — Weekly inbox files (`~/work/inbox/YYYY-WNN.md`), PDF path helpers, remark-create-note.
- `typesense-search.el` — Consult-based search against a local Typesense RPC server for file indexing.
- `latex.el` — AUCTeX with latexmk, Sioyek PDF viewer, auto-detect master file (`*frame.tex` or `*.slides.tex`).

**`eca-emacs/`** — Git-cloned AI code assistant (ECA). Loaded as a use-package from local path. Not user-authored; do not modify.

**`eca/`** — ECA binary distribution. Not user-authored; do not modify.

## Key Conventions

- **Hydra-based command discovery**: The master hydra (`C-c h`) is the primary discoverability mechanism. New commands should be added to the appropriate sub-hydra rather than given standalone keybindings.
- **Plugins go in `plugins-dev/`**: New functionality should be a new file or added to an existing file in `plugins-dev/`. Then add a `load-file` call in init.el.
- **Both Git and CVS**: The VC functions support both backends. When writing VC-related code, handle both.
- **macOS assumptions**: Config assumes macOS (Command=Super, Option=Meta, `gls` for dired, JetBrainsMono Nerd Font, Sioyek PDF viewer, hunspell dictionaries in `~/.emacs.d/spelling/`).
- **No `require`/`provide` in plugins-dev**: These files are loaded via `load-file`, not `require`. They can reference symbols from init.el and each other (loaded in order).
- **`setq load-prefer-newer t`**: Always loads source `.el` over compiled `.elc` — safe to edit and reload without recompiling.
