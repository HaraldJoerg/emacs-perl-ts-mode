;;; perl-ts-mode.el --- Major mode for editing Perl files using tree-sitter -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Harald Jörg

;; Author: Harald Jörg <haj@posteo.de>
;; Created: February 2022
;; Keywords: languages perl tree-sitter
;; Version: 0.2

;; This file is not part of GNU Emacs.

;; perl-ts-mode.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; The Perl programming language is well supported by core Emacs with
;; its major modes `perl-mode' and `cperl-mode'.  The unique feature
;; of `perl-ts-mode' is that it uses a tree-sitter grammar instead of
;; a set of regular expressions to analyze Perl source code.  The
;; tree-sitter grammar, in its current repository, derives directly
;; from Perl's very own syntax declaration perly.y, which makes it
;; well suited to detect the many edge, corner and vertex cases of
;; Perl syntax.

;; The regular expressions, in particular those in `cperl-mode', have
;; been honed over decades.  Therefore it might take some time until
;; `perl-ts-mode' provides an equivalent set of features, and it will
;; co-exist with the other modes for editing Perl files.

(require 'treesit)

(defgroup perl-ts nil
  "Major mode for editing Perl code, based on tree-sitter."
  :prefix "perl-ts-"
  :group 'languages)

(defvar perl-ts--font-lock-settings
  (treesit-font-lock-rules
   :language 'perl
   :feature 'comment
   :override t
   '((comment) @font-lock-comment-face
     (pod) @font-lock-comment-face)
   :language 'perl
   :feature 'string
   :override t
   '((string_literal) @font-lock-string-face)
   :language 'perl
   :feature 'function-name
   :override t
   '((subroutine_declaration_statement "sub" @font-lock-keyword-face)
     (subroutine_declaration_statement name: (bareword) @font-lock-function-name-face)
     (if_statement "if" @font-lock-keyword-face)
     (else "else" @font-lock-keyword-face)
     )
   :language 'perl
   :feature 'variable-name
   '((variable_declaration "my" @font-lock-keyword-face)
     (variable_declaration (scalar) @font-lock-variable-name-face)
     (variable_declaration (array) @cperl-array-face)
     (variable_declaration (hash) @cperl-hash-face)
     (array) @cperl-array-face
     (hash) @cperl-hash-face
     )
   )
  "The font-lock rules for Perl, for use by tree-sitter.")
(defvar perl-ts--font-lock-feature-list
  '((comment string doc)
    (function-name keyword type builtin constant)
    (variable-name string-interpolation key))
  "The list of font-lock levels, for use by tree-sitter.")

(define-derived-mode perl-ts-mode prog-mode "Perl/ts"
  "Major mode for editing Perl code, powered by tree-sitter."
  :group 'perl-ts

  (unless (treesit-ready-p 'perl)
    (error "Tree-sitter is not available for Perl"))
  (setq-local treesit-font-lock-settings
	      perl-ts--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
	      perl-ts--font-lock-feature-list)
  (treesit-major-mode-setup)
  )

(provide 'perl-ts-mode)

;;; perl-ts-mode ends here
