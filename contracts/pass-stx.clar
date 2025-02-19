;; ConcertPass NFT Ticketing Smart Contract
;; SPDX-License-Identifier: MIT

(define-non-fungible-token concert-pass (string-ascii 100))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-OWNER (err u100))
(define-constant ERR-PASS-ALREADY-MINTED (err u101))
(define-constant ERR-PASS-NOT-FOUND (err u102))
(define-constant ERR-UNAUTHORIZED-TRANSFER (err u103))
(define-constant ERR-INVALID-INPUT (err u104))
(define-constant ERR-VENUE-FULL (err u105))
(define-constant ERR-SHOW-ALREADY-CANCELLED (err u106))
(define-constant ERR-REFUND-FAILED (err u107))
(define-constant ERR-PASSES-ALREADY-SOLD (err u108))
(define-constant ERR-INVALID-TRANSFER-RECIPIENT (err u109))

;; Input Validation Functions
(define-private (is-valid-concert-name (name (string-ascii 100)))
  (and 
    (> (len name) u0) 
    (<= (len name) u100)
  )
)

(define-private (is-valid-show-time (time (string-ascii 50)))
  (and 
    (> (len time) u0) 
    (<= (len time) u50)
  )
)

(define-private (is-valid-pass-price (price uint))
  (> price u0)
)

(define-private (is-valid-venue-capacity (capacity uint))
  (> capacity u0)
)

;; Principal Validation Function
(define-private (is-valid-principal (addr principal))
  (not (is-eq addr CONTRACT-OWNER))
)

;; Storage
(define-map pass-metadata 
  {pass-id: (string-ascii 100)} 
  {
    concert-name: (string-ascii 100),
    show-time: (string-ascii 50),
    pass-price: uint,
    venue-capacity: uint,
    tickets-sold: uint,
    is-cancelled: bool
  }
)

;; Tracks pass holders for each concert
(define-map concert-pass-holders 
  {pass-id: (string-ascii 100), pass-owner: principal} 
  bool
)

;; Read-only functions
(define-read-only (get-pass-owner (pass-id (string-ascii 100)))
  (nft-get-owner? concert-pass pass-id)
)

(define-read-only (get-pass-metadata (pass-id (string-ascii 100)))
  (map-get? pass-metadata {pass-id: pass-id})
)

;; Mint new concert pass
(define-public (mint-pass 
  (pass-id (string-ascii 100))
  (concert-name (string-ascii 100))
  (show-time (string-ascii 50))
  (pass-price uint)
  (venue-capacity uint)
)
  (begin
    ;; Validate inputs
    (asserts! (is-valid-concert-name concert-name) ERR-INVALID-INPUT)
    (asserts! (is-valid-show-time show-time) ERR-INVALID-INPUT)
    (asserts! (is-valid-pass-price pass-price) ERR-INVALID-INPUT)
    (asserts! (is-valid-venue-capacity venue-capacity) ERR-INVALID-INPUT)
    
    ;; Ensure pass hasn't been minted before
    (asserts! (is-none (get-pass-metadata pass-id)) ERR-PASS-ALREADY-MINTED)
    
    ;; Create pass metadata
    (map-set pass-metadata 
      {pass-id: pass-id}
      {
        concert-name: concert-name,
        show-time: show-time,
        pass-price: pass-price,
        venue-capacity: venue-capacity,
        tickets-sold: u0,
        is-cancelled: false
      }
    )
    
    ;; Mint NFT to contract owner
    (nft-mint? concert-pass pass-id CONTRACT-OWNER)
  )
)

;; Update Concert Details
(define-public (update-concert-details
  (pass-id (string-ascii 100))
  (new-concert-name (string-ascii 100))
  (new-show-time (string-ascii 50))
  (new-pass-price uint)
)
  (let ((pass-info (unwrap! (get-pass-metadata pass-id) ERR-PASS-NOT-FOUND)))
    (begin
      ;; Ensure only contract owner can update
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)
      
      ;; Prevent updates after passes have been sold
      (asserts! (is-eq (get tickets-sold pass-info) u0) ERR-PASSES-ALREADY-SOLD)
      
      ;; Validate new inputs
      (asserts! (is-valid-concert-name new-concert-name) ERR-INVALID-INPUT)
      (asserts! (is-valid-show-time new-show-time) ERR-INVALID-INPUT)
      (asserts! (is-valid-pass-price new-pass-price) ERR-INVALID-INPUT)
      
      ;; Update pass metadata
      (map-set pass-metadata 
        {pass-id: pass-id}
        (merge pass-info {
          concert-name: new-concert-name,
          show-time: new-show-time,
          pass-price: new-pass-price
        })
      )
      
      (ok true)
    )
  )
)

;; Purchase pass
(define-public (purchase-pass (pass-id (string-ascii 100)))
  (let ((pass-info (unwrap! (get-pass-metadata pass-id) ERR-PASS-NOT-FOUND)))
    (begin
      ;; Check if concert has not been cancelled
      (asserts! (not (get is-cancelled pass-info)) (err u108))
      
      ;; Check if pass sales haven't exceeded venue capacity
      (asserts! 
        (< (get tickets-sold pass-info) (get venue-capacity pass-info)) 
        ERR-VENUE-FULL
      )
      
      ;; Transfer pass price
      (try! (stx-transfer? (get pass-price pass-info) tx-sender CONTRACT-OWNER))
      
      ;; Update tickets sold
      (map-set pass-metadata 
        {pass-id: pass-id}
        (merge pass-info {tickets-sold: (+ (get tickets-sold pass-info) u1)})
      )
      
      ;; Record pass holder
      (map-set concert-pass-holders 
        {pass-id: pass-id, pass-owner: tx-sender} 
        true
      )
      
      ;; Mint pass NFT to purchaser
      (nft-mint? concert-pass pass-id tx-sender)
    )
  )
)

;; Transfer pass
(define-public (transfer-pass 
  (pass-id (string-ascii 100)) 
  (new-owner principal)
)
  (begin
    ;; Validate transfer recipient
    (asserts! (is-valid-principal new-owner) ERR-INVALID-TRANSFER-RECIPIENT)
    
    ;; Ensure only current pass owner can transfer
    (asserts! 
      (is-eq tx-sender (unwrap! (nft-get-owner? concert-pass pass-id) ERR-PASS-NOT-FOUND)) 
      ERR-UNAUTHORIZED-TRANSFER
    )
    
    ;; Transfer pass ownership map
    (map-delete concert-pass-holders {pass-id: pass-id, pass-owner: tx-sender})
    (map-set concert-pass-holders 
      {pass-id: pass-id, pass-owner: new-owner} 
      true
    )
    
    ;; Transfer NFT
    (nft-transfer? concert-pass pass-id tx-sender new-owner)
  )
)

;; Cancel Concert
(define-public (cancel-concert (pass-id (string-ascii 100)))
  (let ((pass-info (unwrap! (get-pass-metadata pass-id) ERR-PASS-NOT-FOUND)))
    (begin
      ;; Ensure only contract owner can cancel
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-OWNER)
      
      ;; Ensure concert hasn't already been cancelled
      (asserts! (not (get is-cancelled pass-info)) ERR-SHOW-ALREADY-CANCELLED)
      
      ;; Mark concert as cancelled
      (map-set pass-metadata 
        {pass-id: pass-id}
        (merge pass-info {is-cancelled: true})
      )
      
      (ok true)
    )
  )
)

;; Refund Pass
(define-public (refund-pass (pass-id (string-ascii 100)))
  (let (
    (pass-info (unwrap! (get-pass-metadata pass-id) ERR-PASS-NOT-FOUND))
    (pass-owner (unwrap! (nft-get-owner? concert-pass pass-id) ERR-PASS-NOT-FOUND))
  )
    (begin
      ;; Ensure concert is cancelled
      (asserts! (get is-cancelled pass-info) (err u109))
      
      ;; Ensure caller is pass owner
      (asserts! (is-eq tx-sender pass-owner) ERR-UNAUTHORIZED-TRANSFER)
      
      ;; Burn the pass NFT
      (try! (nft-burn? concert-pass pass-id tx-sender))
      
      ;; Refund pass price
      (try! (stx-transfer? (get pass-price pass-info) CONTRACT-OWNER tx-sender))
      
      ;; Remove pass holder
      (map-delete concert-pass-holders 
        {pass-id: pass-id, pass-owner: tx-sender}
      )
      
      (ok true)
    )
  )
)