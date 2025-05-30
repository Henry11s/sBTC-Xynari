
;; sBTC-Xynari
;; Define constants
(define-constant contract-administrator tx-sender)
(define-constant minimum-stake-amount u100000) ;; Minimum stake amount (100,000 microSTX)
(define-constant platform-fee-percentage u2) ;; 2% platform fee
(define-constant max-market-id u1000000) ;; Maximum market ID

;; Define error constants in uppercase
(define-constant ERROR_UNAUTHORIZED (err u100))
(define-constant ERROR_MARKET_ALREADY_RESOLVED (err u101))
(define-constant ERROR_MARKET_NOT_RESOLVED (err u102))
(define-constant ERROR_INVALID_STAKE_AMOUNT (err u103))
(define-constant ERROR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERROR_MARKET_CANCELLED (err u105))
(define-constant ERROR_INVALID_OPTION (err u106))
(define-constant ERROR_INVALID_MARKET_ID (err u107))
(define-constant ERROR_INVALID_END_BLOCK (err u108))
(define-constant ERROR_INVALID_QUESTION (err u109))
(define-constant ERROR_INVALID_DESCRIPTION (err u110))

;; Define data maps
(define-map market-registry
  { market-id: uint }
  {
    market-question: (string-ascii 256),
    market-description: (string-ascii 1024),
    market-end-block: uint,
    winning-option: (optional uint),
    option-stake-totals: (list 20 uint),
    market-is-resolved: bool,
    market-is-cancelled: bool
  }
)

(define-map participant-stakes
  { market-id: uint, staker-address: principal }
  {
    stake-distribution: (list 20 uint)
  }
)

(define-map market-options
  { market-id: uint }
  {
    available-options: (list 20 (string-ascii 64))
  }
)

;; Define variables
(define-data-var market-counter uint u0)

;; Helper functions

(define-private (is-valid-market-id (id uint))
  (and (> id u0) (<= id max-market-id))
)

(define-private (is-valid-string (str (string-ascii 256)))
  (> (len str) u0)
)

(define-private (is-valid-description (desc (string-ascii 1024)))
  (> (len desc) u0)
)

(define-private (is-valid-end-block (end-block uint))
  (> end-block stacks-block-height)
)

;; Custom maximum function
(define-private (find-maximum (first-number uint) (second-number uint))
  (if (> first-number second-number) first-number second-number)
)

;; Helper function to safely get an element from a list or return a default value
(define-private (get-list-element-or-default (input-list (list 20 uint)) (element-index uint) (default-value uint))
  (default-to default-value (element-at? input-list element-index))
)

;; Custom take function
(define-private (take-first-n (number-elements uint) (input-list (list 20 uint)))
  (let ((list-length (len input-list)))
    (if (>= number-elements list-length)
      input-list
      (concat (list) (unwrap-panic (slice? input-list u0 number-elements)))
    )
  )
)

;; Custom drop function
(define-private (drop-first-n (number-elements uint) (input-list (list 20 uint)))
  (let ((list-length (len input-list)))
    (if (>= number-elements list-length)
      (list)
      (concat (list) (unwrap-panic (slice? input-list number-elements list-length)))
    )
  )
)

;; Helper function to update a value at a specific index in a list
(define-private (update-list-element (input-list (list 20 uint)) (element-index uint) (new-value uint))
  (let ((prefix-elements (take-first-n element-index input-list))
        (suffix-elements (drop-first-n (+ element-index u1) input-list)))
    (unwrap-panic (as-max-len? (concat (concat prefix-elements (list new-value)) suffix-elements) u20))
  )
)

;; Functions

;; Create a new prediction market
(define-public (create-prediction-market (market-question (string-ascii 256)) (market-description (string-ascii 1024)) (market-end-block uint) (market-options-list (list 20 (string-ascii 64))))
  (let
    (
      (market-id (var-get market-counter))
      (number-of-options (len market-options-list))
      (initial-stake-totals (list u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0))
    )
    (asserts! (> number-of-options u1) ERROR_INVALID_OPTION)
    (asserts! (is-valid-string market-question) ERROR_INVALID_QUESTION)
    (asserts! (is-valid-description market-description) ERROR_INVALID_DESCRIPTION)
    (asserts! (is-valid-end-block market-end-block) ERROR_INVALID_END_BLOCK)
    (map-set market-registry
      { market-id: market-id }
      {
        market-question: market-question,
        market-description: market-description,
        market-end-block: market-end-block,
        winning-option: none,
        option-stake-totals: initial-stake-totals,
        market-is-resolved: false,
        market-is-cancelled: false
      }
    )
    (map-set market-options
      { market-id: market-id }
      {
        available-options: market-options-list
      }
    )
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Place a stake on a prediction market
(define-public (place-market-stake (market-id uint) (selected-option-index uint) (stake-amount uint))
  (let
    (
      (market-data (unwrap! (map-get? market-registry { market-id: market-id }) ERROR_INVALID_MARKET_ID))
      (market-option-data (unwrap! (map-get? market-options { market-id: market-id }) ERROR_INVALID_MARKET_ID))
      (existing-stake-data (default-to { stake-distribution: (list u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0 u0) } 
        (map-get? participant-stakes { market-id: market-id, staker-address: tx-sender })))
    )
    (asserts! (is-valid-market-id market-id) ERROR_INVALID_MARKET_ID)
    (asserts! (not (get market-is-resolved market-data)) ERROR_MARKET_ALREADY_RESOLVED)
    (asserts! (not (get market-is-cancelled market-data)) ERROR_MARKET_CANCELLED)
    (asserts! (>= stake-amount minimum-stake-amount) ERROR_INVALID_STAKE_AMOUNT)
    (asserts! (<= stake-amount (stx-get-balance tx-sender)) ERROR_INSUFFICIENT_BALANCE)
    (asserts! (< selected-option-index (len (get available-options market-option-data))) ERROR_INVALID_OPTION)

    (let
      (
        (current-option-stake (get-list-element-or-default (get option-stake-totals market-data) selected-option-index u0))
        (updated-option-stake (+ current-option-stake stake-amount))
        (updated-option-totals (update-list-element (get option-stake-totals market-data) selected-option-index updated-option-stake))
        (current-participant-stake (get-list-element-or-default (get stake-distribution existing-stake-data) selected-option-index u0))
        (updated-participant-stake (+ current-participant-stake stake-amount))
        (updated-participant-stakes (update-list-element (get stake-distribution existing-stake-data) selected-option-index updated-participant-stake))
      )
      (map-set market-registry { market-id: market-id }
        (merge market-data { option-stake-totals: updated-option-totals })
      )

      (map-set participant-stakes
        { market-id: market-id, staker-address: tx-sender }
        { stake-distribution: updated-participant-stakes }
      )

      (stx-transfer? stake-amount tx-sender (as-contract tx-sender))
    )
  )
)

;; Finalize a prediction market
(define-public (resolve-prediction-market (market-id uint) (winning-option-index uint))
  (let
    (
      (market-data (unwrap! (map-get? market-registry { market-id: market-id }) ERROR_INVALID_MARKET_ID))
      (market-option-data (unwrap! (map-get? market-options { market-id: market-id }) ERROR_INVALID_MARKET_ID))
    )
    (asserts! (is-valid-market-id market-id) ERROR_INVALID_MARKET_ID)
    (asserts! (is-eq tx-sender contract-administrator) ERROR_UNAUTHORIZED)
    (asserts! (not (get market-is-resolved market-data)) ERROR_MARKET_ALREADY_RESOLVED)
    (asserts! (not (get market-is-cancelled market-data)) ERROR_MARKET_CANCELLED)
    (asserts! (>= stacks-block-height (get market-end-block market-data)) ERROR_UNAUTHORIZED)
    (asserts! (< winning-option-index (len (get available-options market-option-data))) ERROR_INVALID_OPTION)

    (map-set market-registry { market-id: market-id }
      (merge market-data {
        winning-option: (some winning-option-index),
        market-is-resolved: true
      })
    )
    (ok true)
  )
)
