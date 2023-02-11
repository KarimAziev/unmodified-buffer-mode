;;; unmodified-buffer-mode.el --- Auto revert modified buffers on window change -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Karim Aziiev <karim.aziiev@gmail.com>

;; Author: Karim Aziiev <karim.aziiev@gmail.com>
;; URL: https://github.com/KarimAziev/unmodified-buffer-mode
;; Version: 0.1.0
;; Keywords: convenience
;; Package-Requires: ((emacs "24.1"))

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

(require 'diff)

(defun unmodified-buffer-mode-current-buffer-matches-file-p ()
  "Return t if the current buffer is identical to its associated file."
  (when buffer-file-name
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

;;;###autoload
(define-minor-mode unmodified-buffer-mode
  "Revert buffers which are identical to the file on disk on window change."
  :group 'convenience
  :global t
  (remove-hook 'window-buffer-change-functions
               #'unmodified-buffer-mode-check-buffers)
  (remove-hook 'window-selection-change-functions
               #'unmodified-buffer-mode-check-buffers)
  (when unmodified-buffer-mode
    (add-hook 'window-buffer-change-functions
              #'unmodified-buffer-mode-check-buffers)
    (add-hook 'window-selection-change-functions
              #'unmodified-buffer-mode-check-buffers)))

(provide 'unmodified-buffer-mode)
;;; unmodified-buffer-mode.el ends here