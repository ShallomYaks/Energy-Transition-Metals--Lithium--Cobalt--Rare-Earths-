(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-batch (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-certification (err u105))
(define-constant err-invalid-transfer (err u106))

(define-data-var next-batch-id uint u1)
(define-data-var next-certification-id uint u1)

(define-map mineral-batches
  uint
  {
    metal-type: (string-ascii 20),
    quantity: uint,
    origin-mine: (string-ascii 100),
    extraction-date: uint,
    current-owner: principal,
    status: (string-ascii 20),
    ethical-score: uint,
    carbon-footprint: uint,
    certification-ids: (list 10 uint)
  }
)

(define-map certifications
  uint
  {
    certification-type: (string-ascii 30),
    issuer: principal,
    batch-id: uint,
    issue-date: uint,
    expiry-date: uint,
    is-valid: bool,
    verification-hash: (buff 32)
  }
)

(define-map supply-chain-records
  uint
  (list 20 {
    timestamp: uint,
    location: (string-ascii 100),
    handler: principal,
    action: (string-ascii 50),
    quality-check: bool,
    temperature: (optional int),
    humidity: (optional uint)
  })
)

(define-map authorized-certifiers
  principal
  {
    name: (string-ascii 100),
    certification-types: (list 5 (string-ascii 30)),
    is-active: bool,
    registration-date: uint
  }
)

(define-map trade-compliance-rules
  (string-ascii 20)
  {
    min-ethical-score: uint,
    required-certifications: (list 5 (string-ascii 30)),
    max-carbon-footprint: uint,
    restricted-origins: (list 10 (string-ascii 100)),
    is-active: bool
  }
)

(define-read-only (get-batch (batch-id uint))
  (map-get? mineral-batches batch-id)
)

(define-read-only (get-certification (cert-id uint))
  (map-get? certifications cert-id)
)

(define-read-only (get-supply-chain-record (batch-id uint))
  (map-get? supply-chain-records batch-id)
)

(define-read-only (get-authorized-certifier (certifier principal))
  (map-get? authorized-certifiers certifier)
)

(define-read-only (get-trade-compliance-rule (metal-type (string-ascii 20)))
  (map-get? trade-compliance-rules metal-type)
)

(define-read-only (is-batch-compliant (batch-id uint))
  (match (map-get? mineral-batches batch-id)
    batch-data (match (map-get? trade-compliance-rules (get metal-type batch-data))
      compliance-rule (and
        (>= (get ethical-score batch-data) (get min-ethical-score compliance-rule))
        (<= (get carbon-footprint batch-data) (get max-carbon-footprint compliance-rule))
        (get is-active compliance-rule)
      )
      false
    )
    false
  )
)

(define-read-only (get-next-batch-id)
  (var-get next-batch-id)
)

(define-read-only (get-next-certification-id)
  (var-get next-certification-id)
)

(define-public (register-mineral-batch
  (metal-type (string-ascii 20))
  (quantity uint)
  (origin-mine (string-ascii 100))
  (extraction-date uint)
  (ethical-score uint)
  (carbon-footprint uint)
)
  (let (
    (batch-id (var-get next-batch-id))
  )
    (asserts! (> quantity u0) err-invalid-batch)
    (asserts! (<= ethical-score u100) err-invalid-batch)
    (map-set mineral-batches batch-id {
      metal-type: metal-type,
      quantity: quantity,
      origin-mine: origin-mine,
      extraction-date: extraction-date,
      current-owner: tx-sender,
      status: "extracted",
      ethical-score: ethical-score,
      carbon-footprint: carbon-footprint,
      certification-ids: (list)
    })
    (map-set supply-chain-records batch-id (list {
      timestamp: stacks-block-height,
      location: origin-mine,
      handler: tx-sender,
      action: "extraction",
      quality-check: true,
      temperature: none,
      humidity: none
    }))
    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

(define-public (register-certifier
  (certifier principal)
  (name (string-ascii 100))
  (certification-types (list 5 (string-ascii 30)))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? authorized-certifiers certifier)) err-already-exists)
    (map-set authorized-certifiers certifier {
      name: name,
      certification-types: certification-types,
      is-active: true,
      registration-date: stacks-block-height
    })
    (ok true)
  )
)

(define-public (issue-certification
  (batch-id uint)
  (certification-type (string-ascii 30))
  (expiry-date uint)
  (verification-hash (buff 32))
)
  (let (
    (cert-id (var-get next-certification-id))
    (batch-data (unwrap! (map-get? mineral-batches batch-id) err-not-found))
    (certifier-data (unwrap! (map-get? authorized-certifiers tx-sender) err-unauthorized))
  )
    (asserts! (get is-active certifier-data) err-unauthorized)
    (asserts! (is-some (index-of (get certification-types certifier-data) certification-type)) err-invalid-certification)
    (asserts! (> expiry-date stacks-block-height) err-invalid-certification)
    (map-set certifications cert-id {
      certification-type: certification-type,
      issuer: tx-sender,
      batch-id: batch-id,
      issue-date: stacks-block-height,
      expiry-date: expiry-date,
      is-valid: true,
      verification-hash: verification-hash
    })
    (let (
      (current-cert-ids (get certification-ids batch-data))
      (updated-cert-ids (unwrap! (as-max-len? (append current-cert-ids cert-id) u10) err-invalid-certification))
    )
      (map-set mineral-batches batch-id (merge batch-data {certification-ids: updated-cert-ids}))
    )
    (var-set next-certification-id (+ cert-id u1))
    (ok cert-id)
  )
)

(define-public (transfer-batch
  (batch-id uint)
  (new-owner principal)
  (location (string-ascii 100))
  (action (string-ascii 50))
)
  (let (
    (batch-data (unwrap! (map-get? mineral-batches batch-id) err-not-found))
    (current-records (default-to (list) (map-get? supply-chain-records batch-id)))
  )
    (asserts! (is-eq tx-sender (get current-owner batch-data)) err-unauthorized)
    (asserts! (is-batch-compliant batch-id) err-invalid-transfer)
    (let (
      (new-record {
        timestamp: stacks-block-height,
        location: location,
        handler: new-owner,
        action: action,
        quality-check: true,
        temperature: none,
        humidity: none
      })
      (updated-records (unwrap! (as-max-len? (append current-records new-record) u20) err-invalid-transfer))
    )
      (map-set mineral-batches batch-id (merge batch-data {current-owner: new-owner}))
      (map-set supply-chain-records batch-id updated-records)
    )
    (ok true)
  )
)

(define-public (update-batch-status
  (batch-id uint)
  (new-status (string-ascii 20))
  (location (string-ascii 100))
  (quality-check bool)
  (temperature (optional int))
  (humidity (optional uint))
)
  (let (
    (batch-data (unwrap! (map-get? mineral-batches batch-id) err-not-found))
    (current-records (default-to (list) (map-get? supply-chain-records batch-id)))
  )
    (asserts! (is-eq tx-sender (get current-owner batch-data)) err-unauthorized)
    (let (
      (new-record {
        timestamp: stacks-block-height,
        location: location,
        handler: tx-sender,
        action: "status-update",
        quality-check: quality-check,
        temperature: temperature,
        humidity: humidity
      })
      (updated-records (unwrap! (as-max-len? (append current-records new-record) u20) err-invalid-transfer))
    )
      (map-set mineral-batches batch-id (merge batch-data {status: new-status}))
      (map-set supply-chain-records batch-id updated-records)
    )
    (ok true)
  )
)

(define-public (set-trade-compliance-rule
  (metal-type (string-ascii 20))
  (min-ethical-score uint)
  (required-certifications (list 5 (string-ascii 30)))
  (max-carbon-footprint uint)
  (restricted-origins (list 10 (string-ascii 100)))
)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= min-ethical-score u100) err-invalid-batch)
    (map-set trade-compliance-rules metal-type {
      min-ethical-score: min-ethical-score,
      required-certifications: required-certifications,
      max-carbon-footprint: max-carbon-footprint,
      restricted-origins: restricted-origins,
      is-active: true
    })
    (ok true)
  )
)

(define-public (revoke-certification (cert-id uint))
  (let (
    (cert-data (unwrap! (map-get? certifications cert-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get issuer cert-data)) err-unauthorized)
    (map-set certifications cert-id (merge cert-data {is-valid: false}))
    (ok true)
  )
)

(define-public (deactivate-certifier (certifier principal))
  (let (
    (certifier-data (unwrap! (map-get? authorized-certifiers certifier) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set authorized-certifiers certifier (merge certifier-data {is-active: false}))
    (ok true)
  )
)

(define-public (update-ethical-score 
  (batch-id uint) 
  (new-score uint)
)
  (let (
    (batch-data (unwrap! (map-get? mineral-batches batch-id) err-not-found))
  )
    (asserts! (is-eq tx-sender (get current-owner batch-data)) err-unauthorized)
    (asserts! (<= new-score u100) err-invalid-batch)
    (map-set mineral-batches batch-id (merge batch-data {ethical-score: new-score}))
    (ok true)
  )
)

(define-read-only (get-certification-count (batch-id uint))
  (match (map-get? mineral-batches batch-id)
    batch-data (len (get certification-ids batch-data))
    u0
  )
)

(define-public (get-batch-certifications (batch-id uint))
  (match (map-get? mineral-batches batch-id)
    batch-data (ok (get certification-ids batch-data))
    err-not-found
  )
)
