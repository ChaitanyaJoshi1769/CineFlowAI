use actix_web::{web, HttpResponse};
use sqlx::PgPool;
use uuid::Uuid;

pub async fn get_user_permissions(pool: web::Data<PgPool>, path: web::Path<Uuid>) -> HttpResponse {
    let user_id = path.into_inner();
    
    let result = sqlx::query(
        "SELECT id, resource_type, resource_id, action FROM permissions WHERE user_id = $1"
    )
    .bind(user_id)
    .fetch_all(pool.get_ref())
    .await;

    match result {
        Ok(rows) => {
            let perms: Vec<_> = rows.iter().map(|row| serde_json::json!({
                "id": row.get::<Uuid, _>("id"),
                "resource_type": row.get::<String, _>("resource_type"),
                "resource_id": row.get::<Uuid, _>("resource_id"),
                "action": row.get::<String, _>("action")
            })).collect();
            HttpResponse::Ok().json(serde_json::json!({"success": true, "data": {"items": perms}}))
        }
        Err(e) => {
            tracing::error!("Get permissions error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to get permissions"}))
        }
    }
}

pub async fn grant_permission(pool: web::Data<PgPool>, req: web::Json<serde_json::Value>) -> HttpResponse {
    let user_id = match req.get("user_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
        Some(id) => id,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Invalid user_id"})),
    };

    let resource_type = match req.get("resource_type").and_then(|v| v.as_str()) {
        Some(t) => t,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing resource_type"})),
    };

    let resource_id = match req.get("resource_id").and_then(|v| v.as_str()).and_then(|s| Uuid::parse_str(s).ok()) {
        Some(id) => id,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Invalid resource_id"})),
    };

    let action = match req.get("action").and_then(|v| v.as_str()) {
        Some(a) => a,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing action"})),
    };

    let perm_id = Uuid::new_v4();

    let result = sqlx::query(
        "INSERT INTO permissions (id, user_id, resource_type, resource_id, action) VALUES ($1, $2, $3, $4, $5)"
    )
    .bind(perm_id)
    .bind(user_id)
    .bind(resource_type)
    .bind(resource_id)
    .bind(action)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"success": true, "data": {"id": perm_id}})),
        Err(e) => {
            tracing::error!("Grant permission error: {}", e);
            HttpResponse::BadRequest().json(serde_json::json!({"error": "Failed to grant permission"}))
        }
    }
}

pub async fn revoke_permission(pool: web::Data<PgPool>, path: web::Path<Uuid>) -> HttpResponse {
    let perm_id = path.into_inner();
    
    let result = sqlx::query(
        "DELETE FROM permissions WHERE id = $1"
    )
    .bind(perm_id)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({"success": true})),
        Err(e) => {
            tracing::error!("Revoke permission error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to revoke permission"}))
        }
    }
}
