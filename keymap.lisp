(in-package :gollum)

(defun key->hash (state keysym)
  (+ (ash state 32) (or keysym 0)))

(defun hash->key (key)
  (values (ash key -32)
	  (logand key #xffffffff)))

(defun make-key-mod-map (xdisplay)
  (multiple-value-bind (shift-keycodes lock-keycodes control-keycodes mod1-keycodes mod2-keycodes mod3-keycodes mod4-keycodes mod5-keycodes) (xlib:modifier-mapping xdisplay)
    (labels ((mod-keycode->mod (keycode)
	       (let ((keysym (xlib:keycode->keysym xdisplay keycode 0)))
		 (when (zerop keysym)
		     (setf keysym (xlib:keycode->keysym xdisplay keycode 1)))
		 (keysym->keysym-name keysym)))
	     (names-in-mod-p (names mod)
	       (loop for name in names
		    thereis (find name mod :test #'string=))))
      (let ((mods (mapcar (lambda (codes) (mapcar #'mod-keycode->mod codes))
			  (list shift-keycodes lock-keycodes control-keycodes mod1-keycodes mod2-keycodes mod3-keycodes mod4-keycodes mod5-keycodes)))
	    map)
	(dolist (key '((:alt "Alt_L" "Alt_R") (:meta "Meta_L" "Meta_R") (:super "Super_L" "Super_R") (:hyper "Hyper_L" "Hyper_R") (:num-lock "Num_Lock")))
	  (cond
	    ((names-in-mod-p (cdr key) (first mods)) (push (cons (car key) nil) map))
	    ((names-in-mod-p (cdr key) (second mods)) (push (cons (car key) nil) map))
	    ((names-in-mod-p (cdr key) (third mods)) (push (cons (car key) nil) map))
	    ((names-in-mod-p (cdr key) (fourth mods)) (push (cons (car key) :mod-1) map))
	    ((names-in-mod-p (cdr key) (fifth mods)) (push (cons (car key) :mod-2) map))
	    ((names-in-mod-p (cdr key) (sixth mods)) (push (cons (car key) :mod-3) map))
	    ((names-in-mod-p (cdr key) (seventh mods)) (push (cons (car key) :mod-4) map))
	    ((names-in-mod-p (cdr key) (eighth mods)) (push (cons (car key) :mod-5) map))))
	(values map mods (append shift-keycodes lock-keycodes control-keycodes mod1-keycodes mod2-keycodes mod3-keycodes mod4-keycodes mod5-keycodes ))))))

(defun abbr->mod (abbr key-mod-map)
  "ABBR may be S(super),A(alt),C(control),H(hyper),M(meta)"
  (labels ((key->mod (key)
	     (cdr (assoc key key-mod-map))))
    (case abbr
      (#\A (key->mod :alt))
      (#\C :control)
      (#\S (key->mod :super))
      (#\H (key->mod :hyper))
      (#\M (key->mod :meta)))))

(defun key-name->keysym-name (key-name)
  (cond
    ((string= key-name "!") "exclam")
    ((string= key-name "\"") "quotedbl")
    ((string= key-name "#") "numbersign")
    ((string= key-name "$") "dollar")
    ((string= key-name "%") "percent")
    ((string= key-name "&") "ampersand")
    ((string= key-name "'") "apostrophe")
    ((string= key-name "(") "parenleft")
    ((string= key-name ")") "parenright")
    ((string= key-name "*") "asterisk")
    ((string= key-name "+") "plus")
    ((string= key-name ",") "comma")
    ((string= key-name "-") "minus")
    ((string= key-name ".") "period")
    ((string= key-name "/") "slash")
    ((string= key-name ":") "colon")
    ((string= key-name ";") "semicolon")
    ((string= key-name "<") "less")
    ((string= key-name "=") "equal")
    ((string= key-name ">") "greater")
    ((string= key-name "?") "question")
    ((string= key-name "@") "at")
    ((string= key-name "[") "bracketleft")
    ((string= key-name "\\") "backslash")
    ((string= key-name "]") "bracketright")
    ((string= key-name "^") "asciicircum")
    ((string= key-name "_") "underscore")
    ((string= key-name "`") "grave")
    ((string= key-name "{") "braceleft")
    ((string= key-name "|") "bar")
    ((string= key-name "}") "braceright")
    ((string= key-name "~") "asciitilde")
    (t key-name)))

(defun kbd-internal (key-desc key-mod-map)
  "STRING should be description of single key event.
modifiers as:A for alt,C for control,
S for super,H for hyper,M for meta,while the last character
should be printable key,like number,alphabet,etc.
example:\"C-t\""
  (let* ((keys (reverse (split-string key-desc "-")))
	 (keysym (keysym-name->keysym (key-name->keysym-name (string-trim " " (car keys))))))
    (key->hash (apply #'xlib:make-state-mask
		      (mapcar (lambda (modifier) (abbr->mod (char (string-trim " " modifier) 0) key-mod-map)) (cdr keys))) keysym)))
