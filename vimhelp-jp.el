;;; vimhelp-jp.el --- vimhelp-jp from Emacs

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-vimhelp-jp
;; Version: 0.01
;; Package-Requires: ((request-deferred "0.2.0") (cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'request-deferred)

(defvar vimhelp-jp--buffer "*vimhelp-jp*")
(defvar vimhelp-jp--tags nil)
(defvar vimhelp-jp--history nil)

(defun vimhelp-jp--collect-tags ()
  (request
   "http://vim-help-jp.herokuapp.com/api/tags/json"
   :parser 'json-read
   :sync t
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (setq vimhelp-jp--tags
                     (cl-loop for tag across data
                              collect tag))))))

(defun vimhelp-jp--query ()
  (unless vimhelp-jp--tags
    (vimhelp-jp--collect-tags))
  (completing-read ":help " vimhelp-jp--tags nil t nil 'vimhelp-jp--history))

;;;###autoload
(defun vimhelp-jp (query)
  "Search query from http://vim-help-jp.herokuapp.com/."
  (interactive
   (list (vimhelp-jp--query)))
  (deferred:$
    (request-deferred "http://vim-help-jp.herokuapp.com/api/search/json/"
                      :parser 'json-read :params `(("query" . ,query)))
    (deferred:nextc it
      (lambda (response)
        (let ((data (request-response-data response)))
          (with-current-buffer (get-buffer-create vimhelp-jp--buffer)
            (setq buffer-read-only nil)
            (erase-buffer)
            (insert (concat "URL: " (assoc-default 'vimdoc_url data) "\n\n"))
            (insert (assoc-default 'text data))
            (setq buffer-read-only t)
            (goto-char (point-min))
            (pop-to-buffer (current-buffer))))))))

(provide 'vimhelp-jp)

;;; vimhelp-jp.el ends here
