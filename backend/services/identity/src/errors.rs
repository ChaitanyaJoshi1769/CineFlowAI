use actix_web::{error::ResponseError, HttpResponse};
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    DatabaseError(String),
    ValidationError(String),
    AuthenticationError(String),
    AuthorizationError(String),
    NotFoundError(String),
    InternalError(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            AppError::DatabaseError(msg) => write!(f, "Database error: {}", msg),
            AppError::ValidationError(msg) => write!(f, "Validation error: {}", msg),
            AppError::AuthenticationError(msg) => write!(f, "Authentication error: {}", msg),
            AppError::AuthorizationError(msg) => write!(f, "Authorization error: {}", msg),
            AppError::NotFoundError(msg) => write!(f, "Not found: {}", msg),
            AppError::InternalError(msg) => write!(f, "Internal error: {}", msg),
        }
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::ValidationError(msg) => {
                HttpResponse::BadRequest().json(serde_json::json!({"error": msg}))
            }
            AppError::AuthenticationError(msg) => {
                HttpResponse::Unauthorized().json(serde_json::json!({"error": msg}))
            }
            AppError::AuthorizationError(msg) => {
                HttpResponse::Forbidden().json(serde_json::json!({"error": msg}))
            }
            AppError::NotFoundError(msg) => {
                HttpResponse::NotFound().json(serde_json::json!({"error": msg}))
            }
            _ => HttpResponse::InternalServerError().json(serde_json::json!({"error": "Internal server error"})),
        }
    }
}
