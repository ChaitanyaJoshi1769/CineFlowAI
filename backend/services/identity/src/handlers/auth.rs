use actix_web::{web, HttpResponse};
use sqlx::PgPool;
use uuid::Uuid;
use crate::models::{RegisterRequest, LoginRequest, User, UserStatus};
use crate::auth;

pub async fn register(
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
    req: web::Json<RegisterRequest>,
) -> HttpResponse {
    let password_hash = match auth::hash_password(&req.password) {
        Ok(h) => h,
        Err(e) => return HttpResponse::BadRequest().json(serde_json::json!({"error": e})),
    };

    let user_id = Uuid::new_v4();

    let result = sqlx::query(
        r#"
        INSERT INTO users (id, email, username, password_hash, first_name, last_name)
        VALUES ($1, $2, $3, $4, $5, $6)
        "#
    )
    .bind(user_id)
    .bind(&req.email)
    .bind(&req.username)
    .bind(&password_hash)
    .bind(&req.first_name)
    .bind(&req.last_name)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => {
            let (access_token, refresh_token) = match auth::create_token(&user_id, &req.email, &secret) {
                Ok(tokens) => tokens,
                Err(e) => return HttpResponse::InternalServerError().json(serde_json::json!({"error": e})),
            };

            HttpResponse::Created().json(serde_json::json!({
                "success": true,
                "data": {
                    "user_id": user_id,
                    "email": req.email,
                    "access_token": access_token,
                    "refresh_token": refresh_token,
                    "token_type": "Bearer",
                    "expires_in": 86400
                }
            }))
        }
        Err(e) => {
            tracing::error!("Registration error: {}", e);
            HttpResponse::BadRequest().json(serde_json::json!({
                "success": false,
                "error": "Registration failed"
            }))
        }
    }
}

pub async fn login(
    pool: web::Data<PgPool>,
    secret: web::Data<String>,
    req: web::Json<LoginRequest>,
) -> HttpResponse {
    let user: Option<User> = sqlx::query_as(
        "SELECT * FROM users WHERE email = $1"
    )
    .bind(&req.email)
    .fetch_optional(pool.get_ref())
    .await
    .ok()
    .flatten();

    match user {
        Some(user) => {
            match auth::verify_password(&req.password, &user.password_hash) {
                Ok(true) => {
                    let (access_token, refresh_token) = match auth::create_token(&user.id, &user.email, &secret) {
                        Ok(tokens) => tokens,
                        Err(e) => return HttpResponse::InternalServerError().json(serde_json::json!({"error": e})),
                    };

                    HttpResponse::Ok().json(serde_json::json!({
                        "success": true,
                        "data": {
                            "user_id": user.id,
                            "email": user.email,
                            "access_token": access_token,
                            "refresh_token": refresh_token,
                            "token_type": "Bearer",
                            "expires_in": 86400
                        }
                    }))
                }
                _ => HttpResponse::Unauthorized().json(serde_json::json!({
                    "success": false,
                    "error": "Invalid credentials"
                }))
            }
        }
        None => HttpResponse::Unauthorized().json(serde_json::json!({
            "success": false,
            "error": "User not found"
        }))
    }
}

pub async fn refresh_token(
    secret: web::Data<String>,
    req: web::Json<serde_json::Value>,
) -> HttpResponse {
    let refresh_token = match req.get("refresh_token").and_then(|t| t.as_str()) {
        Some(t) => t,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing refresh_token"})),
    };

    match auth::verify_token(refresh_token, &secret) {
        Ok(claims) => {
            match auth::create_token(&Uuid::parse_str(&claims.sub).unwrap_or_default(), &claims.email, &secret) {
                Ok((access, new_refresh)) => {
                    HttpResponse::Ok().json(serde_json::json!({
                        "success": true,
                        "data": {
                            "access_token": access,
                            "refresh_token": new_refresh,
                            "token_type": "Bearer",
                            "expires_in": 86400
                        }
                    }))
                }
                Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({"error": e}))
            }
        }
        Err(e) => HttpResponse::Unauthorized().json(serde_json::json!({"error": e}))
    }
}

pub async fn verify_token(
    secret: web::Data<String>,
    req: web::Json<serde_json::Value>,
) -> HttpResponse {
    let token = match req.get("token").and_then(|t| t.as_str()) {
        Some(t) => t,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing token"})),
    };

    match auth::verify_token(token, &secret) {
        Ok(claims) => {
            HttpResponse::Ok().json(serde_json::json!({
                "success": true,
                "data": {
                    "user_id": claims.sub,
                    "email": claims.email,
                    "valid": true
                }
            }))
        }
        Err(e) => HttpResponse::Unauthorized().json(serde_json::json!({
            "success": false,
            "error": e
        }))
    }
}

pub async fn logout(
    pool: web::Data<PgPool>,
    req: web::Json<serde_json::Value>,
) -> HttpResponse {
    let session_id = match req.get("session_id").and_then(|s| s.as_str()) {
        Some(s) => s,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing session_id"})),
    };

    let result = sqlx::query(
        "UPDATE sessions SET revoked_at = NOW() WHERE id = $1"
    )
    .bind(session_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({"success": true})),
        Err(e) => {
            tracing::error!("Logout error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Logout failed"}))
        }
    }
}
