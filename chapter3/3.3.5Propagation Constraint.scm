;; implementing the constraint system
;; constraint
(define (adder a1 a2 sum)
  (define (process-new-value)
    (cond ((and (has-value? a1) (has-value? a2))
           (set-value! sum
                       (+ (get-value! a1) (get-value! a2))
                       me))
          ((and (has-value? a1) (has-value? sum))
           (set-value! a2
                       (- (get-value! sum) (get-value! a1))
                       me))
          ((and (has-value? a2) (has-value? sum))
           (set-value! a1
                       (- (get-value! sum) (get-value! a2))
                       me))))
  (define (process-forget-value)
    (forget-value! sum me)
    (forget-value! a1 me)
    (forget-value! a2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value) (process-new-value))
          ((eq? request 'I-lost-my-value) (process-forget-value))
          (else
           (error "Unknown Request: Adder" request))))
  (connect a1 me)
  (connect a2 me)
  (connect sum me)
  me)

(define (inform-about-value constraint)
  (constraint 'I-have-a-value))


(define (inform-about-no-value constraint)
  (constraint 'I-lost-my-value))


(define (multiplier m1 m2 product)
  (define (process-new-value)
    (cond ((or (and (has-value? m1) (= (get-value! m1) 0))
               (and (has-value? m2) (= (get-value! m2) 0)))
           (set-value! product 0 me))
          ((and (has-value? m1) (has-value? m2))
           (set-value! product
                       (* (get-value! m1) (get-value! m2))
                       me))
          ((and (has-value? product) (has-value? m1))
           (set-value! m2
                       (/ (get-value! product) (get-value! m1))
                       me))
          ((and (has-value? product) (has-value? m2))
           (set-value! m1
                       (/ (get-value! product) (get-value! m2))
                       me))))
  (define (process-forget-value)
    (forget-value! product me)
    (forget-value! m1 me)
    (forget-value! m2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value) (process-new-value))
          ((eq? request 'I-lost-my-value) (process-forget-value))
          (else
           (error "Unknown Request: Multiplier" request))))
  (connect m1 me)
  (connect m2 me)
  (connect product me)
  me)

(define (constant value connector)
  (define (me request)
    (error "Unknown Request: CONSTANT" request))
  (connect connector me)
  (set-value! connector value me)
  me)

(define (probe name connector)
  (define (print-probe value)
    (newline) (display "Probo: ") (display name)
    (display " = ") (display value))
  (define (process-new-value)
    (print-probe (get-value! connector)))
  (define (process-forget-value)
    (print-probe "?"))
  (define (me request)
    (cond ((eq? request 'I-have-a-value) (process-new-value))
          ((eq? request 'I-lost-my-value) (process-forget-value))
          (else
           (error "Unknown Request: Probe" request))))
  (connect connector me)
  me)


;;

(define (make-connector)
  (let ((value false)
        (informant false)
        (constraints '()))
    (define (set-my-value newval setter)
      (cond ((not (has-value? me))
             (set! value newval)
             (set! informant setter)
             (for-each-expect setter
                              inform-about-value
                              constraints))
            ((not (= value newval))
             (error "Contradication" (list value newval)))
            (else
             'ignored)))
    (define (forget-my-value retractor)
      (if (eq? retractor informant)
          (begin (set! informant false)
                 (for-each-expect retractor
                                  inform-about-no-value
                                  constraints))
          'ignored))
    (define (connect new-constraint)
      (if (not (memq new-constraint constraints))
          (set! constraints
                (cons new-constraint constraints)))
      (if (has-value? me)
          (inform-about-value new-constraint))
      'done)
    (define (me request)
      (cond ((eq? request 'has-value?)
             (if informant true false))
            ((eq? request 'get-value!) value)
            ((eq? request 'set-value!) set-my-value)
            ((eq? request 'forget-value!) forget-my-value)
            ((eq? request 'connect) connect)
            (else
             (error "Unknown operation: CONNECTOR" request))))
    me))



(define (for-each-expect exception procedure list)
  (define (loop items)
    (cond ((null? items) 'done)
          ((eq? (car items) exception) (loop (cdr items)))
          (else
           (procedure (car items))
           (loop (cdr items)))))
  (loop list))

(define (has-value? connector)
  (connector 'has-value?))

(define (get-value! connector)
  (connector 'get-value!))

(define (set-value! connector new-value informant)
  ((connector 'set-value!) new-value informant))

(define (forget-value! connector retractor)
  ((connector 'forget-value!) retractor))

(define (connect connector new-constraint)
  ((connector 'connect) new-constraint))


;; create C, F connector
(define C (make-connector))
(define F (make-connector))

;; create
(define (celsius-fahrenheit-conveter c f)
  (let ((u (make-connector))
        (v (make-connector))
        (w (make-connector))
        (x (make-connector))
        (y (make-connector)))
    (multiplier c w u)
    (multiplier v x u)
    (adder v y f)
    (constant 9 w)
    (constant 5 x)
    (constant 32 y)
    'ok))

;; link C, F in an appropriate network
(celsius-fahrenheit-conveter C F)

;; Placing a probo on a connector will cause a message to be printed whenever the connector is given a value;
(probe "Celsius temp" C)
(probe "Fahrenheit temp" F)


;; The third argument to set-value! tells C that this directive comes from the user
(set-value! C 25 'user)


;; ERROR contradiction
(set-value! F 211 'user)

(forget-value! C 'user)
;; Probe: Celsius temp = ?
;; Probo: Fahrenheit temp = ?

(set-value! F 212 'user)

