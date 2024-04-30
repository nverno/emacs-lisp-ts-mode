;;; emacs-lisp-ts-mode.el --- Tree-sitter support for emacs lisp -*- lexical-binding: t; -*-

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/emacs-lisp-ts-mode
;; Version: 0.0.1
;; Package-Requires: ((emacs "29.1"))
;; Created: 29 April 2024
;; Keywords:

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This mode is compatible with the tree-sitter grammar from
;; https://github.com/Wilfred/tree-sitter-elisp.
;;
;;; Code:

(require 'treesit)


(defvar emacs-lisp-ts-mode--keywords
  '("defun" "defsubst" "defmacro"
    ;; Special forms
    "and" "catch" "cond" "condition-case" "defconst" "defvar" "function"
    "if" "interactive" "lambda" "let" "let*" "or" "prog1" "prog2"
    "progn" "quote" "save-current-buffer" "save-excursion"
    "save-restriction" "setq" "setq-default" "unwind-protect" "while"))

(defvar emacs-lisp-ts-mode--builtins
  '("require" "provide"
    "when" "unless"
    "defcustom" "defface" "defvar-keymap" "define-derived-mode"
    "setq-local"
    "pcase" "pcase-dolist"
    "with-eval-after-load" "eval-when-compile" "eval-and-compile"))

(defvar emacs-lisp-ts-mode--operators
  '("*" "/" "+" "-"
    "/=" "="))

(defun emacs-lisp-ts-mode--fontify-parameters (node override start end &rest _)
  (treesit-fontify-with-override
   (treesit-node-start node)
   (treesit-node-end node)
   (if (string-prefix-p "&" (treesit-node-text node))
       'font-lock-type-face
     'font-lock-variable-name-face)
   override start end))

(defvar emacs-lisp-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'elisp
   :feature 'comment
   '((comment) @font-lock-comment-face)
   
   :language 'elisp
   :feature 'string
   '((string) @font-lock-string-face)
   
   :language 'elisp
   :feature 'number
   '([(integer) (float)] @font-lock-number-face)
   
   :language 'elisp
   :feature 'keyword
   `([,@emacs-lisp-ts-mode--keywords] @font-lock-keyword-face

     (quote ["`" "'" "#'"] @font-lock-keyword-face)
     (list (quote
            "`" (list (unquote_splice ",@" @font-lock-keyword-face))))
     (list (quote
            "`" (list (unquote "," @font-lock-keyword-face)))))
     
   :language 'elisp
   :feature 'definition
   `((special_form
      _ "defvar" (symbol) @font-lock-variable-name-face)

     (function_definition
      name: (symbol) @font-lock-function-name-face
      parameters: (list _ (symbol) @emacs-lisp-ts-mode--fontify-parameters :*))

     (macro_definition
      name: (symbol) @font-lock-function-name-face
      parameters: (list _ (symbol) @emacs-lisp-ts-mode--fontify-parameters :*)))

   :language 'elisp
   :feature 'builtin
   `((list _ ((symbol) @font-lock-keyword-face
              (:match ,(rx-to-string
                        `(seq bol
                              (or ,@emacs-lisp-ts-mode--builtins)
                              eol))
                      @font-lock-keyword-face))))
   
   :language 'elisp
   :feature 'constant
   '(["t" "nil"] @font-lock-constant-face
     (char) @font-lock-constant-face)
   
   :language 'elisp
   :feature 'property
   `(((symbol) @font-lock-builtin-face
      (:match ,(rx bol ":") @font-lock-builtin-face)))

   :language 'elisp
   :feature 'quoted
   '((quote (symbol) @font-lock-constant-face))

   :language 'elisp
   :feature 'bracket
   '(["(" ")" "[" "]" "#[" "#("] @font-lock-bracket-face)

   :language 'elisp
   :feature 'operator
   `(((symbol) @font-lock-operator-face
      (:match ,(rx-to-string
                `(seq bol
                      (or ,@emacs-lisp-ts-mode--operators)
                      eol))
              @font-lock-operator-face)))))

(defvar emacs-lisp-ts-mode-feature-list
  '(( comment)
    ( keyword string definition)
    ( builtin constant property)
    ( bracket number operator quoted)))

;;;###autoload
(define-derived-mode emacs-lisp-ts-mode prog-mode "ELisp"
  "Major mode for editing Emacs Lisp code using tree-sitter.

Commands:
\\<emacs-lisp-ts-mode-map>"
  (when (treesit-ready-p 'elisp)
    (treesit-parser-create 'elisp)

    (setq-local treesit-font-lock-settings
                emacs-lisp-ts-mode--font-lock-settings)
    (setq-local treesit-font-lock-feature-list
                emacs-lisp-ts-mode-feature-list)

    (treesit-major-mode-setup)))

(derived-mode-add-parents 'emacs-lisp-ts-mode '(emacs-lisp-mode))

(provide 'emacs-lisp-ts-mode)
;; Local Variables:
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:
;;; emacs-lisp-ts-mode.el ends here
