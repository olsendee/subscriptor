;; Contract Name: Subscriptor
;; A decentralized subscription service in Clarity
;; Users lock STX for N months
;; Service providers auto-claim monthly payments
;; Refunds if subscription is canceled before term ends

(define-data-var sub-id uint u0)
(define-data-var current-height uint u0)

;; Subscription struct: id, subscriber, provider, amount-per-month, start-height, duration (months), claimed-months, active?
(define-map subs
  {id: uint}
  {subscriber: principal, provider: principal, amount: uint, start: uint, duration: uint, claimed: uint, active: bool})

;; Errors
(define-constant ERR-NO-SUCH-SUB (err u100))
(define-constant ERR-NOT-PROVIDER (err u101))
(define-constant ERR-NOT-SUBSCRIBER (err u102))
(define-constant ERR-NOT-ACTIVE (err u103))
(define-constant ERR-NO-PAYMENT-DUE (err u104))

;; Create subscription: subscriber locks (amount * duration) STX
(define-public (create-sub (provider principal) (amount uint) (duration uint))
  (if (or (<= amount u0) (<= duration u0))
      (err u200)
      (let ((total (* amount duration)))
        (let ((this-contract (as-contract tx-sender)))
          (let ((height (var-get current-height)))
            (let ((transfer (stx-transfer? total tx-sender this-contract)))
              (match transfer
                success
                  (let ((id (+ u1 (var-get sub-id))))
                    (var-set sub-id id)
                    (var-set current-height (+ height u1))
                    (map-set subs {id: id} {
                      subscriber: tx-sender,
                      provider: provider,
                      amount: amount,
                      start: height,
                      duration: duration,
                      claimed: u0,
                      active: true
                    })
                    (ok id))
                failure (err u201))))))))

;; Provider claims monthly payment if due
(define-public (claim (id uint))
  (match (map-get? subs {id: id}) entry-or-none
    (let ((some-sub entry-or-none))
      (if (not (is-eq (get provider some-sub) tx-sender))
        ERR-NOT-PROVIDER
        (if (not (get active some-sub))
          ERR-NOT-ACTIVE
          (let ((height (var-get current-height)))
            (let ((months-elapsed (/ (- height (get start some-sub)) u21000)))
              (let ((claimable (- months-elapsed (get claimed some-sub))))
                (if (<= claimable u0)
                  ERR-NO-PAYMENT-DUE
                  (let ((payout (* claimable (get amount some-sub))))
                    (let ((this-contract (as-contract tx-sender)))
                      (let ((transfer (stx-transfer? payout this-contract (get provider some-sub))))
                        (match transfer
                          success
                            (begin 
                              (var-set current-height (+ height u1))
                              (map-set subs {id: id} {
                                subscriber: (get subscriber some-sub),
                                provider: (get provider some-sub),
                                amount: (get amount some-sub),
                                start: (get start some-sub),
                                duration: (get duration some-sub),
                                claimed: (+ (get claimed some-sub) claimable),
                                active: (get active some-sub)
                              })
                              (ok claimable))
                          failure (err u202))))))))))))
    ERR-NO-SUCH-SUB))

;; Subscriber cancels subscription, refund unused months
(define-public (cancel (id uint))
  (match (map-get? subs {id: id}) entry-or-none
    (let ((some-sub entry-or-none))
      (if (not (is-eq (get subscriber some-sub) tx-sender))
        ERR-NOT-SUBSCRIBER
        (if (not (get active some-sub))
          ERR-NOT-ACTIVE
          (let ((height (var-get current-height)))
            (let ((months-elapsed (/ (- height (get start some-sub)) u21000)))
              (let ((unused (if (> (get duration some-sub) months-elapsed)
                            (- (get duration some-sub) months-elapsed)
                            u0)))
                (if (<= unused u0)
                  (begin
                    (var-set current-height (+ height u1))
                    (map-set subs {id: id} {
                      subscriber: (get subscriber some-sub),
                      provider: (get provider some-sub),
                      amount: (get amount some-sub),
                      start: (get start some-sub),
                      duration: (get duration some-sub),
                      claimed: (get claimed some-sub),
                      active: false
                    })
                    (ok u0))
                  (let ((refund (* unused (get amount some-sub))))
                    (let ((this-contract (as-contract tx-sender)))
                      (let ((transfer (stx-transfer? refund this-contract tx-sender)))
                        (match transfer
                          success
                            (begin
                              (var-set current-height (+ height u1))
                              (map-set subs {id: id} {
                                subscriber: (get subscriber some-sub),
                                provider: (get provider some-sub),
                                amount: (get amount some-sub),
                                start: (get start some-sub),
                                duration: (get duration some-sub),
                                claimed: (get claimed some-sub),
                                active: false
                              })
                              (ok refund))
                          failure (err u203))))))))))))
    ERR-NO-SUCH-SUB))

;; View subscription
(define-read-only (get-sub (id uint))
  (map-get? subs {id: id}))