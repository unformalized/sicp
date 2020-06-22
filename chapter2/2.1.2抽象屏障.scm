(load "util.scm")

(define (make-rat n d)
  (cons n d)
)

(define (numer x)
  (let ((g (gcd (car x) (cdr x))))
    (/ (car x) g))
)

(define (denom x)
  (let ((g (gcd (car x) (cdr x))))
    (/ (cdr x) g))
)