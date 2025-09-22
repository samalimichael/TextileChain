;; TextileChain - Sustainable textile supply chain monitoring and certification system
(define-map textile-batches uint {
  manufacturer: principal,
  fabric-type: (string-utf8 64),
  production-methods: (string-utf8 256),
  manufacturing-date: uint,
  sustainability-practices: (string-utf8 64),
  eco-certified: bool
})

(define-map manufacturer-production principal (list 100 uint))
(define-map sustainability-auditors principal bool)
(define-data-var batch-tracking-id uint u0)

;; Error codes
(define-constant err-not-manufacturer (err u900))
(define-constant err-not-auditor (err u901))
(define-constant err-batch-not-found (err u902))
(define-constant err-access-forbidden (err u403))
(define-constant err-production-limit-exceeded (err u904))
(define-constant err-invalid-auditor-principal (err u905))
(define-constant err-invalid-fabric-type (err u906))
(define-constant err-invalid-production-methods (err u907))
(define-constant err-invalid-manufacturing-date (err u908))
(define-constant err-invalid-sustainability-practices (err u909))
(define-constant err-invalid-batch-tracking-id (err u910))

;; Contract guardian for textile certification
(define-constant contract-guardian tx-sender)

;; Register sustainability auditor
(define-public (register-sustainability-auditor (auditor principal))
  (begin
    ;; Check if sender is contract guardian
    (asserts! (is-eq tx-sender contract-guardian) err-access-forbidden)
    
    ;; Validate auditor principal
    (asserts! (not (is-eq auditor 'SP000000000000000000002Q6VF78)) err-invalid-auditor-principal)
    
    ;; Add auditor to registry
    (ok (map-set sustainability-auditors auditor true))
  )
)

;; Register textile batch
(define-public (register-textile-batch 
  (fabric-type (string-utf8 64)) 
  (production-methods (string-utf8 256)) 
  (manufacturing-date uint) 
  (sustainability-practices (string-utf8 64)))
  (let
    ((batch-id (var-get batch-tracking-id))
     (manufacturer tx-sender)
     (current-production (default-to (list) (map-get? manufacturer-production manufacturer))))
    
    ;; Validate inputs
    (asserts! (> (len fabric-type) u0) err-invalid-fabric-type)
    (asserts! (> (len production-methods) u0) err-invalid-production-methods)
    (asserts! (> manufacturing-date u1600000000) err-invalid-manufacturing-date)
    (asserts! (> (len sustainability-practices) u0) err-invalid-sustainability-practices)
    
    ;; Check production registration limit
    (asserts! (< (len current-production) u100) err-production-limit-exceeded)
    
    ;; Store textile batch information
    (map-set textile-batches batch-id {
      manufacturer: manufacturer,
      fabric-type: fabric-type,
      production-methods: production-methods,
      manufacturing-date: manufacturing-date,
      sustainability-practices: sustainability-practices,
      eco-certified: false
    })
    
    ;; Update manufacturer's production list
    (let 
      ((updated-production-list (unwrap-panic (as-max-len? (concat (list batch-id) current-production) u100))))
      (map-set manufacturer-production manufacturer updated-production-list)
    )
    
    ;; Increment batch tracking ID
    (var-set batch-tracking-id (+ batch-id u1))
    
    (ok batch-id)))

;; Certify textile sustainability
(define-public (certify-textile-sustainability (batch-id uint))
  (begin
    ;; Validate batch ID
    (asserts! (< batch-id (var-get batch-tracking-id)) err-invalid-batch-tracking-id)
    
    (let
      ((textile-batch (unwrap! (map-get? textile-batches batch-id) err-batch-not-found)))
      
      ;; Check if sender is sustainability auditor
      (asserts! (default-to false (map-get? sustainability-auditors tx-sender)) err-not-auditor)
      
      ;; Update eco-certification status
      (ok (map-set textile-batches batch-id (merge textile-batch {eco-certified: true})))
    )
  )
)

;; Get textile batch details
(define-read-only (get-textile-batch (batch-id uint))
  (map-get? textile-batches batch-id))

;; Get manufacturer's production
(define-read-only (get-manufacturer-production (manufacturer principal))
  (default-to (list) (map-get? manufacturer-production manufacturer)))

;; Check sustainability auditor status
(define-read-only (is-sustainability-auditor (address principal))
  (default-to false (map-get? sustainability-auditors address)))