;; Fortunator - A decentralized random giveaway management system
;; Author: Claude
;; Version: 1.0.0

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-GIVEAWAY-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-ENTERED (err u102))
(define-constant ERR-ENTRY-PERIOD-ENDED (err u103))
(define-constant ERR-ENTRY-PERIOD-NOT-ENDED (err u104))
(define-constant ERR-INSUFFICIENT-FUNDS (err u105))
(define-constant ERR-ALREADY-DRAWN (err u106))
(define-constant ERR-INVALID-PARAMS (err u107))
(define-constant ERR-NOT-ENOUGH-PARTICIPANTS (err u108))
(define-constant ERR-MAX-PARTICIPANTS-REACHED (err u109))

;; Data structures
(define-map giveaways
  { giveaway-id: uint }
  {
    creator: principal,
    title: (string-utf8 100),
    description: (string-utf8 500),
    prize-amount: uint,
    max-participants: uint,
    entry-fee: uint,
    entry-end-block: uint,
    winner: (optional principal),
    participant-count: uint,
    is-active: bool
  }
)

(define-map participants
  { giveaway-id: uint, index: uint }
  { participant: principal }
)

(define-map participant-entries
  { giveaway-id: uint, participant: principal }
  { entered: bool, index: uint }
)

(define-data-var giveaway-counter uint u0)

;; Read-only functions
(define-read-only (get-giveaway (giveaway-id uint))
  (map-get? giveaways { giveaway-id: giveaway-id })
)

(define-read-only (get-giveaway-count)
  (var-get giveaway-counter)
)

(define-read-only (has-user-entered (giveaway-id uint) (user principal))
  (default-to
    false
    (get entered (map-get? participant-entries { giveaway-id: giveaway-id, participant: user }))
  )
)

(define-read-only (get-participant-at-index (giveaway-id uint) (index uint))
  (get participant (default-to { participant: tx-sender } 
    (map-get? participants { giveaway-id: giveaway-id, index: index })))
)

(define-read-only (get-participant-count (giveaway-id uint))
  (match (map-get? giveaways { giveaway-id: giveaway-id })
    giveaway (get participant-count giveaway)
    u0
  )
)

;; Public functions
(define-public (create-giveaway 
                (title (string-utf8 100)) 
                (description (string-utf8 500)) 
                (max-participants uint) 
                (entry-fee uint) 
                (entry-period-blocks uint))
  (let
    (
      (giveaway-id (+ (var-get giveaway-counter) u1))
      (creator tx-sender)
      (entry-end-block (+ block-height entry-period-blocks))
    )
    ;; Validate inputs
    (asserts! (> max-participants u1) (err ERR-INVALID-PARAMS))
    (asserts! (> entry-period-blocks u0) (err ERR-INVALID-PARAMS))
    
    ;; Create giveaway (with 0 prize amount - prizes will be handled separately)
    (map-set giveaways
      { giveaway-id: giveaway-id }
      {
        creator: creator,
        title: title,
        description: description,
        prize-amount: u0,
        max-participants: max-participants,
        entry-fee: entry-fee,
        entry-end-block: entry-end-block,
        winner: none,
        participant-count: u0,
        is-active: true
      }
    )
    
    ;; Increment counter
    (var-set giveaway-counter giveaway-id)
    
    (ok giveaway-id)
  )
)

(define-public (fund-giveaway (giveaway-id uint) (amount uint))
  (match (map-get? giveaways { giveaway-id: giveaway-id })
    giveaway
    (begin
      ;; Check if caller is creator
      (asserts! (is-eq tx-sender (get creator giveaway)) (err ERR-NOT-AUTHORIZED))
      
      ;; Check if giveaway is active
      (asserts! (get is-active giveaway) (err ERR-GIVEAWAY-NOT-FOUND))
      
      ;; Check if winner already drawn
      (asserts! (is-none (get winner giveaway)) (err ERR-ALREADY-DRAWN))
      
      ;; Update prize amount
      (map-set giveaways
        { giveaway-id: giveaway-id }
        (merge giveaway { prize-amount: (+ (get prize-amount giveaway) amount) })
      )
      
      (ok true)
    )
    (err ERR-GIVEAWAY-NOT-FOUND)
  )
)

(define-public (enter-giveaway (giveaway-id uint))
  (let
    (
      (participant tx-sender)
    )
    (match (map-get? giveaways { giveaway-id: giveaway-id })
      giveaway
      (begin
        ;; Validate giveaway is active and entry period hasn't ended
        (asserts! (get is-active giveaway) (err ERR-GIVEAWAY-NOT-FOUND))
        (asserts! (<= block-height (get entry-end-block giveaway)) (err ERR-ENTRY-PERIOD-ENDED))
        (asserts! (is-none (get winner giveaway)) (err ERR-ALREADY-DRAWN))
        
        ;; Check if max participants reached
        (asserts! (< (get participant-count giveaway) (get max-participants giveaway)) (err ERR-MAX-PARTICIPANTS-REACHED))
        
        ;; Check if user already entered
        (asserts! (not (has-user-entered giveaway-id participant)) (err ERR-ALREADY-ENTERED))
        
        (let
          (
            (participant-index (get participant-count giveaway))
          )
          ;; Store participant at the next index
          (map-set participants
            { giveaway-id: giveaway-id, index: participant-index }
            { participant: participant }
          )
          
          ;; Mark user as entered with their index
          (map-set participant-entries
            { giveaway-id: giveaway-id, participant: participant }
            { entered: true, index: participant-index }
          )
          
          ;; Update participant count
          (map-set giveaways
            { giveaway-id: giveaway-id }
            (merge giveaway { participant-count: (+ (get participant-count giveaway) u1) })
          )
          
          (ok true)
        )
      )
      (err ERR-GIVEAWAY-NOT-FOUND)
    )
  )
)

(define-public (draw-winner (giveaway-id uint))
  (let
    (
      (seed (get-random-seed))
    )
    (match (map-get? giveaways { giveaway-id: giveaway-id })
      giveaway
      (begin
        ;; Check if caller is creator
        (asserts! (is-eq tx-sender (get creator giveaway)) (err ERR-NOT-AUTHORIZED))
        
        ;; Check if giveaway is active
        (asserts! (get is-active giveaway) (err ERR-GIVEAWAY-NOT-FOUND))
        
        ;; Check if entry period has ended
        (asserts! (> block-height (get entry-end-block giveaway)) (err ERR-ENTRY-PERIOD-NOT-ENDED))
        
        ;; Check if winner already drawn
        (asserts! (is-none (get winner giveaway)) (err ERR-ALREADY-DRAWN))
        
        ;; Check if there are participants
        (asserts! (> (get participant-count giveaway) u0) (err ERR-NOT-ENOUGH-PARTICIPANTS))
        
        ;; Select random winner
        (let
          (
            (participant-count (get participant-count giveaway))
            (winner-index (mod seed participant-count))
            (winner (get-participant-at-index giveaway-id winner-index))
          )
          
          ;; Update giveaway with winner
          (map-set giveaways
            { giveaway-id: giveaway-id }
            (merge giveaway { winner: (some winner), is-active: false })
          )
          
          (ok winner)
        )
      )
      (err ERR-GIVEAWAY-NOT-FOUND)
    )
  )
)

(define-public (cancel-giveaway (giveaway-id uint))
  (match (map-get? giveaways { giveaway-id: giveaway-id })
    giveaway
    (begin
      ;; Check if caller is creator
      (asserts! (is-eq tx-sender (get creator giveaway)) (err ERR-NOT-AUTHORIZED))
      
      ;; Check if giveaway is active
      (asserts! (get is-active giveaway) (err ERR-GIVEAWAY-NOT-FOUND))
      
      ;; Check if winner already drawn
      (asserts! (is-none (get winner giveaway)) (err ERR-ALREADY-DRAWN))
      
      ;; Mark giveaway as inactive
      (map-set giveaways
        { giveaway-id: giveaway-id }
        (merge giveaway { is-active: false })
      )
      
      (ok true)
    )
    (err ERR-GIVEAWAY-NOT-FOUND)
  )
)

;; Helper functions
(define-data-var random-seed uint u0)

(define-private (get-random-seed)
  (let
    (
      (current-seed (var-get random-seed))
      (new-seed (+ u1 (xor current-seed (xor block-height burn-block-height))))
    )
    (var-set random-seed new-seed)
    new-seed
  )
)