(use-modules (system foreign))

(define binds (dynamic-link "binds.so"))

; the integer pseudoregister for the function return value
(define rret (foreign-ref (dynamic-pointer "reg_ret" int binds)))

; three caller-save integer registers
(define r0 (foreign-ref (dynamic-pointer "reg_r0" int binds)))
(define r1 (foreign-ref (dynamic-pointer "reg_r1" int binds)))
(define r2 (foreign-ref (dynamic-pointer "reg_r2" int binds)))

; three callee-save integer registers
(define v0 (foreign-ref (dynamic-pointer "reg_v0" int binds)))
(define v1 (foreign-ref (dynamic-pointer "reg_v1" int binds)))
(define v2 (foreign-ref (dynamic-pointer "reg_v2" int binds)))

; six caller-save floating-point registers
(define fpr0 (foreign-ref (dynamic-pointer "reg_fpr0" int binds)))
(define fpr1 (foreign-ref (dynamic-pointer "reg_fpr1" int binds)))
(define fpr2 (foreign-ref (dynamic-pointer "reg_fpr2" int binds)))
(define fpr3 (foreign-ref (dynamic-pointer "reg_fpr3" int binds)))
(define fpr4 (foreign-ref (dynamic-pointer "reg_fpr4" int binds)))
(define fpr5 (foreign-ref (dynamic-pointer "reg_fpr5" int binds)))

; and a floating-point return register. the documentation doesn't make
; clear whether this is a pseudoregister or not, so you'd better
; assume it is
; commented out because gcc didn't like the definition in the binding
;(define fpret (dynamic-pointer "reg_fpret" int binds))

(define make-instruction-array
  (make-foreign-function '*
                         (dynamic-func "make_instruction_array" binds)
                         (list int)))

(define begin-function-in-buffer
  (make-foreign-function '*
                         (dynamic-func "begin_function_in_buffer" binds)
                         (list '*)))

(define declare-leaf-function
  (make-foreign-function void
                         (dynamic-func "declare_leaf_function" binds)
                         (list int)))

(define make-int-argument
  (make-foreign-function int
                         (dynamic-func "make_int_argument" binds)
                         (list)))

(define retrieve-int-argument
  (make-foreign-function void
                         (dynamic-func "retrieve_int_argument" binds)
                         (list int int)))

(define move-integer-between-regs
  (make-foreign-function void
                         (dynamic-func "move_integer_between_regs" binds)
                         (list int int)))

(define make-return
  (make-foreign-function void
                         (dynamic-func "make_return" binds)
                         '()))

(define flush-instruction-buffer
  (make-foreign-function void
                         (dynamic-func "flush_instruction_buffer" binds)
                         (list '*)))

; end GNU lightning wrapper functions, start tests


; syntax-rules is so ugly.
(define-syntax proc
  (syntax-rules (<-)
    ((_ var <- exp rest rest* ...) (let ((var exp)) (proc rest rest* ...)))
    ((_ var <- exp) exp)
    ((_ exp rest rest* ...) (begin exp (proc rest rest* ...)))
    ((_ exp) exp)
    ((_) (begin))))

; the version without 'proc has some strange bug that probably
; involves internal defines expanding into letrec and such. Any
; program using Lightning is going to be doing this sort of thing a
; lot, so I'd rather just use the proc macro.
(define (make-integer-id-function)
  (proc
   insn-buffer <- (make-instruction-array 1024)
   pointer-to-beginning <- (begin-function-in-buffer insn-buffer)
   (declare-leaf-function 1)
   arg <- (make-int-argument)
   (retrieve-int-argument r0 arg)
   (move-integer-between-regs rret r0)
   (make-return)
   (flush-instruction-buffer insn-buffer)
   (make-foreign-function int
                          pointer-to-beginning
                          (list int))))

(if (not (eq? ((make-integer-id-function) 42) 42))
    (error "make-integer-id-function failed")
    (display "make-integer-id-function succeeded\n"))

;; (define (make-integer-id-function)
;;   (define insn-buffer (make-instruction-array 1024))
;;   (define pointer-to-beginning (begin-function-in-buffer insn-buffer))
;;   (declare-leaf-function 1)
;;   (define arg (make-int-argument))
;;   (retrieve-int-argument r0 arg)
;;   (move-integer-between-regs rret r0)
;;   (make-return)
;;   (flush-instruction-buffer insn-buffer)
;;   (make-foreign-function int
;;                          pointer-to-beginning
;;                          (list int)))
