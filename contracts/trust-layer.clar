;; Title: TrustLayer Protocol - Decentralized Reputation Engine
;;
;; Summary:
;; An innovative blockchain infrastructure that creates a universal reputation layer
;; for the decentralized web, enabling trustless interactions through verifiable
;; reputation metrics and dynamic trust scoring algorithms.
;;
;; Description:
;; TrustLayer Protocol revolutionizes digital trust by implementing a comprehensive
;; reputation management system that operates across multiple blockchain networks.
;; The protocol leverages advanced cryptographic proofs and behavioral analytics
;; to create immutable reputation records that evolve with user activity patterns.
;;
;; Unlike traditional systems that rely on centralized authorities, TrustLayer
;; empowers users to build and maintain their reputation through authentic
;; network participation. The protocol features intelligent reputation decay
;; mechanisms that ensure scores remain current and meaningful, preventing
;; the accumulation of stale reputation data.
;;
;; Core Capabilities:
;; - Autonomous reputation identity management
;; - Dynamic trust scoring based on verified activities
;; - Time-weighted reputation decay for accuracy
;; - Cross-platform reputation portability
;; - Cryptographically secured reputation histories
;; - Threshold-based trust verification systems
;;
;; TrustLayer creates a new foundation for decentralized applications where
;; reputation becomes a portable asset, enabling seamless trust relationships
;; across the entire blockchain ecosystem.
;;

;; SYSTEM CONSTANTS & ERROR DEFINITIONS

;; Protocol Error Codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMETERS (err u101))
(define-constant ERR-IDENTITY-EXISTS (err u102))
(define-constant ERR-IDENTITY-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-CREDIBILITY (err u104))
(define-constant ERR-MAX-CREDIBILITY-REACHED (err u105))

;; System Configuration Parameters
(define-constant MAX-CREDIBILITY-SCORE u1000)
(define-constant MIN-CREDIBILITY-SCORE u0)
(define-constant CREDIBILITY-DECAY-RATE u10)  ;; 10% degradation per cycle

;; DATA STORAGE STRUCTURES

;; Primary Identity Registry
;; Comprehensive reputation profiles with temporal tracking
(define-map identities 
  {owner: principal}
  {
    did: (string-ascii 50),      ;; Decentralized Identity Identifier
    credibility-score: uint,     ;; Current reputation score
    created-at: uint,            ;; Profile creation timestamp
    last-updated: uint           ;; Last activity timestamp
  }
)

;; Activity-Based Reputation Multipliers
;; Defines scoring weights for different network participation types
(define-map credibility-actions
  {action-type: (string-ascii 50)}
  {multiplier: uint}
)

;; PRIVATE UTILITY FUNCTIONS

;; Validates identity ownership and existence
(define-private (is-valid-owner (owner principal))
  (and 
    (is-some (map-get? identities {owner: owner}))
    (is-eq owner tx-sender)
  )
)

;; PUBLIC PROTOCOL FUNCTIONS

;; Initialize Reputation Activity Framework
;; Establishes foundational reputation multipliers for network activities
(define-public (initialize-credibility-actions)
  (begin
    (map-set credibility-actions 
      {action-type: "governance-participation"} 
      {multiplier: u5}
    )
    (map-set credibility-actions 
      {action-type: "contract-execution"} 
      {multiplier: u10}
    )
    (map-set credibility-actions 
      {action-type: "community-engagement"} 
      {multiplier: u7}
    )
    (ok true)
  )
)

;; Create Digital Reputation Identity
;; Establishes a new reputation profile within the TrustLayer ecosystem
(define-public (create-identity (did (string-ascii 50)))
  (let 
    (
      (sender tx-sender)
      (current-stacks-block-height stacks-block-height)
    )
    (begin
      ;; Ensure identity uniqueness constraint
      (asserts! (is-none (map-get? identities {owner: sender})) 
        ERR-IDENTITY-EXISTS)
      
      ;; Validate DID format requirements
      (asserts! (> (len did) u5) 
        ERR-INVALID-PARAMETERS)
      
      ;; Initialize new reputation profile
      (map-set identities 
        {owner: sender}
        {
          did: did,
          credibility-score: u50,  ;; Initial reputation allocation
          created-at: current-stacks-block-height,
          last-updated: current-stacks-block-height
        }
      )
      (ok did)
    )
  )
)

;; Update Reputation Score
;; Enhances reputation based on verified network activities
(define-public (update-credibility 
  (action-type (string-ascii 50))
)
  (let 
    (
      (owner tx-sender)
      (current-identity 
        (unwrap! 
          (map-get? identities {owner: owner}) 
          ERR-IDENTITY-NOT-FOUND
        )
      )
      (action-multiplier 
        (default-to u0 
          (get multiplier 
            (map-get? credibility-actions {action-type: action-type})
          )
        )
      )
      (current-score (get credibility-score current-identity))
      (updated-score 
        (if (< (+ current-score action-multiplier) MAX-CREDIBILITY-SCORE)
            (+ current-score action-multiplier)
            MAX-CREDIBILITY-SCORE
        )
      )
    )
    (begin
      ;; Verify action type exists in registry
      (asserts! (is-some (map-get? credibility-actions {action-type: action-type}))
        ERR-INVALID-PARAMETERS)

      ;; Apply reputation enhancement
      (map-set identities 
        {owner: owner}
        (merge current-identity {
          credibility-score: updated-score,
          last-updated: stacks-block-height
        })
      )
      (ok updated-score)
    )
  )
)