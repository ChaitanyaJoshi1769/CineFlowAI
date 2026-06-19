use actix_web::{web, HttpResponse};
use sqlx::PgPool;
use uuid::Uuid;

pub async fn list_users(pool: web::Data<PgPool>) -> HttpResponse {
    let result: Result<Vec<_>, _> = sqlx::query(
        "SELECT id, email, username, first_name, last_name, status, created_at FROM users LIMIT 50"
    )
    .fetch_all(pool.get_ref())
    .await
    .map(|rows| rows.iter().map(|row| serde_json::json!({
        "id": row.get::<Uuid, _>("id"),
        "email": row.get::<String, _>("email"),
        "username": row.get::<Option<String>, _>("username"),
        "first_name": row.get::<Option<String>, _>("first_name"),
        "last_name": row.get::<Option<String>, _>("last_name"),
        "status": row.get::<String, _>("status"),
        "created_at": row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
    })).collect());

    match result {
        Ok(users) => HttpResponse::Ok().json(serde_json::json!({
            "success": true,
            "data": {"items": users}
        })),
        Err(e) => {
            tracing::error!("List users error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to list users"}))
        }
    }
}

pub async fn get_user(pool: web::Data<PgPool>, path: web::Path<Uuid>) -> HttpResponse {
    let user_id = path.into_inner();
    
    let result = sqlx::query(
        "SELECT id, email, username, first_name, last_name, avatar_url, bio, status, created_at FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await;

    match result {
        Ok(Some(row)) => {
            HttpResponse::Ok().json(serde_json::json!({
                "success": true,
                "data": {
                    "id": row.get::<Uuid, _>("id"),
                    "email": row.get::<String, _>("email"),
                    "username": row.get::<Option<String>, _>("username"),
                    "first_name": row.get::<Option<String>, _>("first_name"),
                    "last_name": row.get::<Option<String>, _>("last_name"),
                    "avatar_url": row.get::<Option<String>, _>("avatar_url"),
                    "bio": row.get::<Option<String>, _>("bio"),
                    "status": row.get::<String, _>("status"),
                    "created_at": row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                }
            }))
        }
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({"error": "User not found"})),
        Err(e) => {
            tracing::error!("Get user error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to get user"}))
        }
    }
}

pub async fn update_user(pool: web::Data<PgPool>, path: web::Path<Uuid>, req: web::Json<serde_json::Value>) -> HttpResponse {
    let user_id = path.into_inner();
    
    let first_name = req.get("first_name").and_then(|v| v.as_str());
    let last_name = req.get("last_name").and_then(|v| v.as_str());
    let avatar_url = req.get("avatar_url").and_then(|v| v.as_str());
    let bio = req.get("bio").and_then(|v| v.as_str());

    let result = sqlx::query(
        "UPDATE users SET first_name = COALESCE($2, first_name), last_name = COALESCE($3, last_name), avatar_url = COALESCE($4, avatar_url), bio = COALESCE($5, bio), updated_at = NOW() WHERE id = $1"
    )
    .bind(user_id)
    .bind(first_name)
    .bind(last_name)
    .bind(avatar_url)
    .bind(bio)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({"success": true})),
        Err(e) => {
            tracing::error!("Update user error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to update user"}))
        }
    }
}

pub async fn delete_user(pool: web::Data<PgPool>, path: web::Path<Uuid>) -> HttpResponse {
    let user_id = path.into_inner();
    
    let result = sqlx::query(
        "UPDATE users SET status = 'inactive', updated_at = NOW() WHERE id = $1"
    )
    .bind(user_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({"success": true})),
        Err(e) => {
            tracing::error!("Delete user error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to delete user"}))
        }
    }
}
