use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

/// User model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub username: Option<String>,
    pub password_hash: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub status: UserStatus,
    pub email_verified: bool,
    pub email_verified_at: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub last_login_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "varchar")]
pub enum UserStatus {
    #[serde(rename = "active")]
    Active,
    #[serde(rename = "inactive")]
    Inactive,
    #[serde(rename = "banned")]
    Banned,
}

/// Register request
#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub username: Option<String>,
}

/// Login request
#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
    pub device_name: Option<String>,
}

/// Auth token response
#[derive(Debug, Serialize)]
pub struct AuthTokenResponse {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: String,
    pub expires_in: i64,
}

/// JWT claims
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JwtClaims {
    pub sub: String, // user_id
    pub email: String,
    pub iat: i64,
    pub exp: i64,
}

/// Organization model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Organization {
    pub id: Uuid,
    pub name: String,
    pub slug: String,
    pub description: Option<String>,
    pub logo_url: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Membership model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Membership {
    pub id: Uuid,
    pub user_id: Uuid,
    pub organization_id: Uuid,
    pub role: String,
    pub joined_at: DateTime<Utc>,
}

/// Permission model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Permission {
    pub id: Uuid,
    pub user_id: Option<Uuid>,
    pub organization_id: Option<Uuid>,
    pub resource_type: String,
    pub resource_id: Uuid,
    pub action: String,
    pub granted_at: DateTime<Utc>,
}

/// API Key model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct ApiKey {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub name: String,
    pub key_prefix: String,
    pub permissions: Vec<String>,
    pub rate_limit_per_minute: i32,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

/// Session model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Session {
    pub id: Uuid,
    pub user_id: Uuid,
    pub token_hash: String,
    pub ip_address: Option<String>,
    pub user_agent: Option<String>,
    pub device_name: Option<String>,
    pub expires_at: DateTime<Utc>,
    pub created_at: DateTime<Utc>,
}

/// Audit log model
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct AuditLog {
    pub id: Uuid,
    pub organization_id: Uuid,
    pub user_id: Option<Uuid>,
    pub action: String,
    pub resource_type: String,
    pub resource_id: Option<Uuid>,
    pub status: String,
    pub ip_address: Option<String>,
    pub created_at: DateTime<Utc>,
}
