;;; perl-ts-mode.el --- Major mode for editing Perl files using tree-sitter -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Harald Jörg

;; Author: Harald Jörg <haj@posteo.de>
;; Created: February 2022
;; Keywords: languages perl tree-sitter
;; Version: 0.2
;; Package-Requires: ((emacs "29.1"))

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
(require 'cperl-mode)

(defgroup perl-ts nil
  "Major mode for editing Perl code, based on tree-sitter."
  :prefix "perl-ts-"
  :group 'languages)

;; Stuff adapted from tree-sitter-perl's "highlights.scm"
(defvar perl-ts--highlight-keyword-list
  '("use" "no"
    "package"
    "sub"
    "if" "elsif" "else" "unless"
    "while" "until"
    "for" "foreach"
    "do"
    "my" "our" "local"
    "require"
    "last" "next" "redo" "goto"
    "undef")
  "Keywords as defined in highlights.scm of tree-sitter-perl.
This is a list to allow adding more keywords at runtime.")

(defvar perl-ts--highlight-keyword-phaser-list
  '("BEGIN" "INIT" "CHECK" "UNITCHECK" "END")
  "Keywords for phasers as defined in highlights.scm of tree-sitter-perl.
This is a list to allow adding more keywords at runtime.")
  
(defvar perl-ts--highlight-operator-list
  '("or" "and"
    "eq" "ne" "cmp" "lt" "le" "ge" "gt"
    "isa")
  "Alphabetic operators as defined in highlights.scm of
tree-sitter-perl.  This is a list to allow adding more keywords
at runtime.")

(defvar perl-ts--pod-keyword-list
  '((pod_directive)
    (head_directive)
    (over_directive)
    (item_directive)
    (back_directive)
    (encoding_directive)
    (cut_directive))
  "From tree-sitter-pod: The directives processed by the POD parser.")

;;; Faces for POD markup
(defface perl-ts-doc
  '((t :inherit (variable-pitch font-lock-doc-face)))
  "A bold face for Perl's POD syntax"
  )
(defface perl-ts-doc-markup-bold
  '((t :weight bold :inherit perl-ts-doc))
  "A bold face for Perl's B<...> POD syntax"
  )
(defface perl-ts-doc-markup-italic
  '((t :slant italic :inherit perl-ts-doc))
  "A bold face for Perl's I<...> POD syntax"
  )
(defface perl-ts-doc-markup-link
  '((t :inherit link))
  "A face for Perl's L<...> POD syntax"
  )
(defface perl-ts-doc-markup-code
  '((t :inherit (fixed-pitch perl-ts-doc)))
  "A face for Perl's C<...> POD syntax"
  )
(defface perl-ts-doc-markup-file
  '((t :inherit (fixed-pitch perl-ts-doc)))
  "A face for Perl's F<...> POD syntax"
  )

;;; Font-locking based on tree-sitter

(defun perl-ts--fontify-pod-region (node override start end &optional rest)
  "Fontify a POD node identified by the Perl parser"
  (let ((treesit-font-lock-settings perl-ts--pod-font-lock-settings))
    (message "(haj) Calling perl-ts--fontify-pod-region (%s-%s)" start end)
    (treesit-font-lock-fontify-region (treesit-node-start node)
				      (treesit-node-end node))))

(defvar perl-ts--font-lock-settings
  (treesit-font-lock-rules
   ;; Comments and POD
   :language 'perl
   :feature 'comment
   :override t
   '((comment) @font-lock-comment-face
     (pod) @perl-ts--fontify-pod-region
     )
   
   ;; Strings
   :language 'perl
   :feature 'string
   :override t
   '((string_literal) @font-lock-string-face			   ; 'text'
     (string_literal "q" @cperl-nonoverridable-face)		   ; q/text/
     (interpolated_string_literal) @font-lock-string-face	   ; "text"
     (interpolated_string_literal "qq" @cperl-nonoverridable-face) ; qq/text/
     (quoted_word_list "qw" @cperl-nonoverridable-face)		   ; qw/text/
     @font-lock-string-face
     (command_string) @font-lock-string-face			   ; `text`
     (command_string "qx" @cperl-nonoverridable-face)		   ; qx/text/
     @font-lock-string-face
     (heredoc_content) @font-lock-string-face)                     ; << HERE
   ;; Labels
   :language 'perl
   :feature 'string
   :override t
   '([(heredoc_token) (command_heredoc_token) (heredoc_end)]
     @font-lock-constant-face
     (statement_label (identifier)
		      @font-lock-constant-face)
     (loopex_expression (bareword)
			@font-lock-constant-face)
     (goto_expression (bareword)
		      @font-lock-constant-face)
     )
   ;; Keywords
   :language 'perl
   :feature 'function-name
   :override nil
   `((undef_expression "undef" @font-lock-keyword-face)
     (localization_expression "local" @font-lock-keyword-face)
     (subroutine_declaration_statement name: (bareword)
				       @font-lock-function-name-face)
     (attribute_name) @font-lock-constant-face
     (attribute_value) @font-lock-string-face
     (prototype_or_signature) @font-lock-string-face
     ([,@perl-ts--highlight-keyword-list
       ,@perl-ts--highlight-keyword-phaser-list])
     @font-lock-keyword-face
     (require_expression "require"
			 @font-lock-keyword-face)
     (require_expression (bareword)
			 @font-lock-function-name-face)
     (package_statement "package"
			@font-lock-keyword-face)
     (package) @font-lock-function-name-face
     (func0op) @font-lock-type-face
     (func1op) @font-lock-type-face
     (method_call_expression invocant: (bareword)
			     @font-lock-function-name-face)
     )
   ;; Operators
   :language 'perl
   :feature 'function-name
   :override nil
   `(([,@perl-ts--highlight-operator-list])
     @cperl-nonoverridable-face)
   ;; Variables Scalars are a rule of their own so that their
   ;; formatting is kept in @$arrayref
   :language 'perl
   :feature 'variable-name
   :override 'keep
   '((scalar) @font-lock-variable-name-face)
   :language 'perl
   :feature 'variable-name
   :override 'keep
   '((arraylen) @font-lock-variable-name-face
     (array) @cperl-array-face
     (array_deref_expression (["->" "@" "*"]) @cperl-array-face)
     (array_element_expression array: (_)
			       @cperl-array-face)
     (hash) @cperl-hash-face
     (hash_element_expression hash: (_)
			       @cperl-hash-face)
     (hash_deref_expression (["->" "%" "*"]) @cperl-hash-face)
     (hash_element_expression key: (bareword) @font-lock-string-face)
     )
   :language 'perl
   :feature 'variable-name
   :override nil
   '((variable_declaration (scalar) @font-lock-variable-name-face)
     (for_statement my_var: (scalar) @font-lock-variable-name-face)
     )
   ;; Sections
   :language 'perl
   :feature 'comment
   :override t
   '((eof_marker) @font-lock-keyword-face
     (data_section) @font-lock-comment-face
     )
   ;; Errors are explicitly shown when reported by the parser
   :language 'perl
   :feature 'comment
   :override t
   '((ERROR) @font-lock-warning-face)
   )
  "The font-lock rules for Perl, for use by tree-sitter.")

(defvar perl-ts--pod-font-lock-settings
  (treesit-font-lock-rules
   :language 'pod
   :feature 'doc
   :override t
   `([,@perl-ts--pod-keyword-list] @font-lock-doc-markup-face
     (head_paragraph (content) @font-lock-variable-name-face)
     (interior_sequence (sequence_letter)
			@font-lock-doc-markup-face)
     (interior_sequence (sequence_letter) @letter (:match "B" @letter) (content)
			@perl-ts-doc-markup-bold)
     (interior_sequence (sequence_letter) @letter (:match "I" @letter) (content)
			@perl-ts-doc-markup-italic)
     (interior_sequence (sequence_letter) @letter (:match "L" @letter) (content)
			@perl-ts-doc-markup-link)
     (interior_sequence (sequence_letter) @letter (:match "C" @letter) (content)
			@perl-ts-doc-markup-code)
     (interior_sequence (sequence_letter) @letter (:match "F" @letter) (content)
			@perl-ts-doc-markup-file)
     (pod (_) @perl-ts-doc)
     )
   )
  "The font-lock rules for embedded POD in Perl, for use by tree-sitter.")

(defvar perl-ts--font-lock-feature-list
  '((comment string doc)
    (function-name keyword type builtin constant declaration)
    (variable-name string-interpolation key))
  "The list of font-lock levels, for use by tree-sitter.")

(defun perl-ts--function-name (node)
  "Return the name of the function definition in NODE."
  (treesit-node-text (treesit-node-child-by-field-name node "name")))

(defun perl-ts--heading-text (node)
  "Return the name of a Plain Old Documentation heading in NODE."
  (treesit-node-text child))


;;;###autoload
(define-derived-mode perl-ts-mode prog-mode "Perl/ts"
  "Major mode for editing Perl code, powered by tree-sitter."
  :group 'perl-ts

  (unless (treesit-ready-p 'perl)
    (error "Tree-sitter is not available for Perl"))
  ;; tree-sitter specifics
  (setq-local treesit-font-lock-settings
	      perl-ts--font-lock-settings)
  (setq-local treesit-font-lock-feature-list
	      perl-ts--font-lock-feature-list)
  (setq-local treesit-range-settings
	      (treesit-range-rules
	       :embed 'pod
	       :host 'perl
	       '((pod) @capture)))
  (setq-local treesit-simple-imenu-settings
	      `(("Class/Package" ,(rx "package_statement")
		 nil perl-ts--function-name)
		("Function" ,(rx "subroutine_declaration_statement")
		 nil perl-ts--function-name)
		))
  (treesit-major-mode-setup)

  ;; general setup
  (setq-local comment-start "# ")
  (imenu-add-menubar-index)
  )

(provide 'perl-ts-mode)

;;; perl-ts-mode ends here
