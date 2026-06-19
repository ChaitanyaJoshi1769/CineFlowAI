pub mod auth;
pub mod users;
pub mod organizations;
pub mod permissions;

use actix_web::HttpResponse;

/// Health check endpoint
pub async fn health() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "identity",
        "timestamp": chrono::Utc::now().to_rfc3339()
    }))
}

/// Readiness check endpoint
pub async fn ready() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "ready": true,
        "service": "identity"
    }))
}
