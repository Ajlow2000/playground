use security_core::classification::DataClassification;
use security_core::severity::SecuritySeverity;
use security_events::{
    AuditChain, EventKind, EventOutcome, EventValue, HmacEventSigner, RedactionEngine,
    SecurityEvent,
};

fn main() {
    demo_basic_event();
    demo_hmac_signing();
    demo_audit_chain();
    demo_redaction();
}

fn demo_basic_event() {
    println!("=== Basic SecurityEvent ===");

    let mut event = SecurityEvent::new(
        EventKind::AuthnFailure,
        SecuritySeverity::High,
        EventOutcome::Failure,
    );
    event.actor = Some("alice@example.com".to_string());
    event.resource = Some("/api/admin/users".to_string());
    event.reason_code = Some("bad_password");

    println!("event_id : {}", event.event_id);
    println!("kind     : {:?}", event.kind);
    println!("severity : {:?}", event.severity);
    println!("outcome  : {:?}", event.outcome);
    println!("actor    : {:?}", event.actor);
    println!();
}

fn demo_hmac_signing() {
    println!("=== HMAC Signing ===");

    let signer = HmacEventSigner::new("super-secret-audit-key").expect("key must not be empty");

    let mut event = SecurityEvent::new(
        EventKind::AdminAction,
        SecuritySeverity::Info,
        EventOutcome::Success,
    );
    event.actor = Some("ops-bot".to_string());

    signer.sign_event(&mut event).expect("signing failed");

    let valid = signer.verify_event(&event).expect("verification failed");
    println!("hmac     : {:?}", event.hmac.as_deref().map(|h| &h[..16]));
    println!("valid    : {valid}");

    // Demonstrate tamper detection: mutate the event after signing and re-verify.
    let mut tampered = event.clone();
    tampered.actor = Some("evil-actor".to_string());
    let still_valid = signer
        .verify_event(&tampered)
        .expect("verification failed");
    println!("tampered : {still_valid}"); // false
    println!();
}

fn demo_audit_chain() {
    println!("=== Audit Chain ===");

    let mut chain = AuditChain::new();

    for (kind, outcome) in [
        (EventKind::AuthnFailure, EventOutcome::Failure),
        (EventKind::AuthzDeny, EventOutcome::Blocked),
        (EventKind::RateLimitBlock, EventOutcome::Blocked),
        (EventKind::AdminAction, EventOutcome::Success),
    ] {
        let event = SecurityEvent::new(kind, SecuritySeverity::Medium, outcome);
        chain.append(event);
    }

    println!("entries  : {}", chain.len());
    println!("intact   : {}", chain.verify());

    // Each entry's hash incorporates the prior hash, making retroactive edits detectable.
    for (i, entry) in chain.entries().iter().enumerate() {
        println!("  [{i}] hash={}", &entry.hash[..16]);
    }
    println!();
}

fn demo_redaction() {
    println!("=== Redaction ===");

    let engine = RedactionEngine::with_default_policy();

    let mut event = SecurityEvent::new(
        EventKind::SecretAccess,
        SecuritySeverity::Critical,
        EventOutcome::Success,
    );

    // Each label carries a DataClassification; the engine applies the matching strategy.
    event.labels.insert(
        "endpoint".to_string(),
        EventValue::Classified {
            value: "GET /api/v1/secrets".to_string(),
            classification: DataClassification::Public, // Allow → unchanged
        },
    );
    event.labels.insert(
        "user_email".to_string(),
        EventValue::Classified {
            value: "alice@example.com".to_string(),
            classification: DataClassification::PII, // Hash → SHA256:<hex>
        },
    );
    event.labels.insert(
        "api_key".to_string(),
        EventValue::Classified {
            value: "sk_live_abc123".to_string(),
            classification: DataClassification::Credentials, // Drop → removed
        },
    );

    let processed = engine.process_event(event);

    for (k, v) in &processed.labels {
        // api_key is absent (Credentials → Drop)
        println!("  {k} = {v:?}");
    }
    println!();
}
