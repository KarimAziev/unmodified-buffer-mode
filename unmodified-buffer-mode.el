;;; unmodified-buffer-mode.el --- Auto revert modified buffers on window change -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/unmodified-buffer-mode
;; Version: 0.1.0
;; Keywords: convenience
;; Package-Requires: ((emacs "24.4"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Mode that unset modified flag for buffers which are identical to the file on disk.

;;; Code:

(defcustom unmodified-buffer-mode-verbose nil
  "Whether to show message when buffer before reverting a buffer's state."
  :type 'boolean
  :group 'convenience)

(defcustom unmodified-buffer-mode-debounce-delay 1
  "How many seconds to wait before checking buffers modified status."
  :type 'interger
  :group 'convenience)

(require 'diff)


(defun unmodified-buffer-mode-current-buffer-matches-file-p ()
	"Return t if the current buffer is identical to its associated file."
	(when (and buffer-file-name
						 (file-exists-p buffer-file-name))
    (diff-no-select buffer-file-name (current-buffer) nil 'noasync)
    (with-current-buffer "*Diff*"
      (and (search-forward-regexp
            "^Diff finished \(no differences\)\."
            (point-max) 'noerror) t))))


(defun unmodified-buffer-mode-check-buffers (&rest _)
  "Unset modified flag for buffers which are identical to the file on disk."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name (buffer-modified-p))
        (when (unmodified-buffer-mode-current-buffer-matches-file-p)
          (when unmodified-buffer-mode-verbose
            (message "unmodified-buffer-mode: reverting %s" buf))
          (set-buffer-modified-p nil))))))

(defvar unmodified-buffer-mode-timer nil)

(defun unmodified-buffer-mode-check-buffers-debounced (&rest _)
  "Unset modified flag for buffers which are identical to the file on disk."
  (when (timerp unmodified-buffer-mode-timer)
    (cancel-timer unmodified-buffer-mode-timer))
  (setq unmodified-buffer-mode-timer (run-with-timer
                                      unmodified-buffer-mode-debounce-delay
                                      nil
                                      #'unmodified-buffer-mode-check-buffers)))

;;;###autoload
(define-minor-mode unmodified-buffer-mode
  "Revert buffers which are identical to the file on disk on window change."
  :group 'convenience
  :global t
  (advice-remove 'save-buffers-kill-emacs
                 #'unmodified-buffer-mode-check-buffers)
  (advice-remove 'save-some-buffers
                 #'unmodified-buffer-mode-check-buffers)
  (when unmodified-buffer-mode
    (advice-add 'save-buffers-kill-emacs :before
                #'unmodified-buffer-mode-check-buffers)
    (advice-add 'save-some-buffers :before
                #'unmodified-buffer-mode-check-buffers)))

(provide 'unmodified-buffer-mode)
;;; unmodified-buffer-mode.el ends here