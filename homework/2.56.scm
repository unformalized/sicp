(load "util.scm")

(define (exponentiation? exp) (and (pair? exp) (eq? (car exp) '** )))

(define (make-exponentiation base exponent)
  (cond ((=number? base 1) 1)
        ((=number? exponent 1) base)
        ((=number? exponent 0) 1)
        (else
          (list '** base exponent))))

(define (base exp) (cadr exp))
(define (exponent exp) (caddr exp))


(define (deriv exp var)
  (cond ((number? exp) 0)
        ((variable? exp)
         (if (same-variable? exp var) 1 0))
        ((sum? exp)
         (make-sum (deriv (addend exp) var)
                   (deriv (augend exp) var)))
        ((product? exp)
         (make-sum
           (make-product (multiplier exp)
                         (deriv (multiplicand exp) var))
           (make-product (multiplicand exp)
                         (deriv (multiplier exp) var))))
        ((exponentiation? exp)
         (make-product
           (make-product
             (exponent exp) (make-exponentiation (base exp) (- (exponent exp) 1)))
           (deriv (base exp) var)))
        (else
          (error "unknown expression type -- DERIV" exp))))

(deriv (list '** 'x 2)  'x )


