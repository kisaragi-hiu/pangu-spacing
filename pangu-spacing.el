;;; pangu-spacing.el --- Minor-mode to add space between Chinese and English characters.

;; Copyright (C) 2013, 2014 Yen-Chin, Lee.

;; Author: coldnew <coldnew.tw@gmail.com>
;; Kyewords: converience
;; Version: 0.4
;; X-URL: http://github.com/coldnew/pangu-spacing
;; Package-Requires: ((emacs "24.1"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;; [![MELPA](http://melpa.org/packages/pangu-spacing-badge.svg)](http://melpa.org/#/pangu-spacing)
;; [![MELPA Stable](http://stable.melpa.org/packages/pangu-spacing-badge.svg)](http://stable.melpa.org/#/pangu-spacing)

;;; Screenshot:
;; ![Screenshot](https://github.com/coldnew/pangu-spacing/raw/master/screenshot/screenshot.gif)

;;; Commentary (English):
;; pangu-spacing-mode is an minor-mode to auto add `space' between Chinese
;; and English characters. Note that these white-space characters are not really
;; added to the contents, it just like to do so.

;; Take following sentance for example:
;;
;;      你好，我是coldnew，我喜歡使用emacs。
;;
;; After you use pangu-spacing-mdoe, you will see
;;
;;      你好，我是 coldnew，我喜歡使用 emacs。
;;
;; But the text doesn't be modify by this mode, after disable
;; pangu-spacing-mode or use other text eidtor to open the file, you
;; will still see:
;;
;;      你好，我是coldnew，我喜歡使用emacs。

;; pangu-spacing is named from [pangu.js](https://github.com/vinta/pangu.js)'s README.
;;
;;      Translation of pangu.js's README [1]
;;
;;      If you are the one who feel quiet ill when see Chinese,
;;      English and digits characters squeezed together and
;;      want to add whitespace to separate them. This plugin (support
;;      Chrome and Firefox) is what you need when surfing the
;;      internet, it will add whitespace between Chinese,
;;      half-width English, digits and symbols automatically.

;;      These spaces between English and Chinese characters are called
;;      pangu-spacing by sinologist, since it separate the cobnfusion
;;      between full-width and half-width characters.
;;      Studies showed that who dislike to add whitespace between
;;      English and Chinese characters also have relationship problem.
;;      Almost 70 percent of them will get married to the one they
;;      don't love, the rest only can left the heritage to their cat.
;;      Indeed, love and writing need some space in good time.

;;      Let's go for it.

;;      [1] https://github.com/vinta/pangu.js

;;; Commentary (Chinese):

;; pangu-spacing-mode 是一個可以自動幫你將中文與英文之間加上`空白'作為分隔的 minor-mode, 他的名稱來自於 [pangu.js](https://github.com/vinta/pangu.js) 上的 README。
;;
;;      引述自 pangu.js README [1]
;;
;;      如果你跟我一樣，每次看到網頁上的中文字和英文、數字、符號擠在一塊，就會
;;      坐立難安，忍不住想在它們之間加個空格。這個外掛（支援 Chrome 和 Firefox）
;;      正是你在網路世界走跳所需要的東西，它會自動替你在網頁中所有的中文字和半
;;      形的英文、數字、符號之間插入空白。
;;
;;      漢學家稱這個空白字元為「盤古之白」，因為它劈開了全形字和半形字之間的混
;;      沌。另有研究顯示，打字的時候不喜歡在中文和英文之間加空格的人，感情路都
;;      走得很辛苦，有七成的比例會在 34 歲的時候跟自己不愛的人結婚，而其餘三成
;;      的人最後只能把遺產留給自己的貓。畢竟愛情跟書寫都需要適時地留白。
;;
;;      與大家共勉之。

;;      [1] https://github.com/vinta/pangu.js

;;; Installation:

;; If you have `melpa` and `emacs24` installed, simply type:
;;
;;      M-x package-install pangu-spacing
;;

;; For `cask' user, just add following lines in your `Cask' file
;;
;;      (source melpa)
;;
;;      (depends-on "pangu-spacing")
;;

;;; Configuration

;; In your .emacs
;;
;;      (require 'pangu-spacing)
;;      (global-pangu-spacing-mode 1)
;;
;; pangu-spacing-mode do not really insert space between English and
;; Chinese by defaut, you should enable this option manually.
;;
;;      (setq pangu-spacing-real-insert-separator t)
;;
;; After you enable this, space will be inserted before you save file.
;;
;; If you only want to insert whitespace in some specific mode, but just add
;; virtual space in other mode, you can use following code to achive
;; this: (take org-mode as example)
;;
;;      (add-hook 'org-mode-hook
;;                '(lambda ()
;;                 (set (make-local-variable 'pangu-spacing-real-insert-separator) t)))
;;

;;; Code:

(defgroup pangu-spacing nil
  "Add space between Chinese and English characters automatically."
  :group 'convenience
  :link '(url-link :tag "Github" "https://github.com/coldnew/pangu-spacing"))

;;;; Custom Variables

(defcustom pangu-disabled-modes '(eshell-mode shell-mode term-mode)
  "List of major modes where `pangu-mode' should not be active."
  :group 'pangu-spacing
  :type '(repeat symbol))

;; NOTE:
;; We use `chinse-two-byte' instead of `chinese-two-byte', since there
;; are some typo in emacs version 21.1-24.3. For more information,
;; see:
;;
;;   [Emacs-diffs] trunk r115873: Fix misspelling of 'chinese' in rx.
;;
;; Url: http://lists.gnu.org/archive/html/emacs-diffs/2014-01/msg00049.html

(defconst pangu-spacing-include-regexp
  ;; we didn't add korean because korean-hangul-two-byte is not implemented
  (rx (or (and (or (group-n 3 (any "。，！？；：「」（）、"))
                   (group-n 1 (or (category chinse-two-byte)
                                  (category japanese-hiragana-two-byte)
                                  (category japanese-katakana-two-byte))))
               (group-n 2 (in "a-zA-Z0-9")))
          (and (group-n 1 (in "a-zA-Z0-9"))
               (or (group-n 3 (any "。，！？；：「」（）、"))
                   (group-n 2 (or (category chinse-two-byte)
                                  (category japanese-hiragana-two-byte)
                                  (category japanese-katakana-two-byte)))))))
  "Regexp to find Chinese character before English character.

Group 1 contains the character before the potential pangu
spacing, and group 2 the character after that. A space is needed
when both group 1 and group 2 are non-nil. Group 3 exists as a
workaround for excluded characters. Since rx does not support
matching text that satisfy two regexp at the same time (we want
to match all Chinese two byte characters, but not punctuations),
we first try to match excluded characters, then the characters
that need pangu-spacing. The excluded characters will be matched
to group 3, and shortcut the matching for Chinese characters.
Thus group 1 and group 2 will both be non nil when a pangu space
is needed.")

;;;; Functions

(declare-function org-element-at-point "org-element")
(declare-function org-element-type "org-element")
(declare-function org-element-context "org-element")
(defun pangu-spacing-org-mode-at-special-region ()
  "Return whether we should skip this match."
  (let ((element (org-element-at-point)))
    (or (member (org-element-type element)
                '(src-block keyword example-block export-block
                            latex-environment planning
                            keyword))
        (member (car (org-element-context element))
                '(inline-src-block timestamp link code verbatim)))))

(defvar pangu-skip-match-function-alist
  '((org-mode . pangu-spacing-org-mode-at-special-region))
  "Alist mapping major modes to functions that determine whether a match should be skipped.")

(defun pangu-buffer (&optional buf)
  "Apply pangu spacing on BUF.

BUF defaults to the current buffer."
  (let ((at-special-region-func (cdr (assq major-mode
                                           pangu-skip-match-function-alist))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward pangu-spacing-include-regexp nil t)
        (when (and (match-beginning 1)
                   (match-beginning 2))
          (unless (and at-special-region-func
                       (save-match-data (funcall at-special-region-func)))
            ;; This is where we add the space
            (replace-match "\\1 \\2" nil nil))
          (backward-char))))))

(defun pangu-region (start end)
  "Apply pangu between START and END in the current buffer."
  (interactive "r")
  (save-restriction
    (narrow-to-region start end)
    (pangu-buffer)))

(defun pangu (str)
  "Apply pangu spacing on STR."
  (with-temp-buffer
    (insert str)
    (pangu-buffer)
    (buffer-string)))

;;;###autoload
(define-minor-mode pangu-mode
  "WIP: Apply pangu on the current buffer on save."
  :group 'pangu-spacing
  :global nil
  :init-value nil
  :lighter " Ρ"
  (unless (or (member major-mode pangu-disabled-modes)
              (minibufferp))
    (save-restriction
      (widen)
      (if pangu-mode
          (add-hook 'before-save-hook #'pangu-buffer nil t)
        (progn
          (remove-hook 'before-save-hook #'pangu-buffer t)))))
  pangu-mode)

;; (define-globalized-minor-mode global-pangu-mode
;;   pangu-mode pangu-mode)

(provide 'pangu-spacing)
;;; pangu-spacing.el ends here
