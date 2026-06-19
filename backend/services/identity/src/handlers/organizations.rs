use actix_web::{web, HttpResponse};
use sqlx::PgPool;
use uuid::Uuid;

pub async fn create_organization(pool: web::Data<PgPool>, req: web::Json<serde_json::Value>) -> HttpResponse {
    let name = match req.get("name").and_then(|v| v.as_str()) {
        Some(n) => n,
        None => return HttpResponse::BadRequest().json(serde_json::json!({"error": "Missing name"})),
    };

    let slug = match req.get("slug").and_then(|v| v.as_str()) {
        Some(s) => s,
        None => name.to_lowercase().replace(" ", "-"),
    };

    let org_id = Uuid::new_v4();

    let result = sqlx::query(
        "INSERT INTO organizations (id, name, slug) VALUES ($1, $2, $3)"
    )
    .bind(org_id)
    .bind(name)
    .bind(slug)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Created().json(serde_json::json!({"success": true, "data": {"id": org_id}})),
        Err(e) => {
            tracing::error!("Create organization error: {}", e);
            HttpResponse::BadRequest().json(serde_json::json!({"error": "Failed to create organization"}))
        }
    }
}

pub async fn list_organizations(pool: web::Data<PgPool>) -> HttpResponse {
    let result = sqlx::query(
        "SELECT id, name, slug, description, status, created_at FROM organizations LIMIT 50"
    )
    .fetch_all(pool.get_ref())
    .await;

    match result {
        Ok(rows) => {
            let orgs: Vec<_> = rows.iter().map(|row| serde_json::json!({
                "id": row.get::<Uuid, _>("id"),
                "name": row.get::<String, _>("name"),
                "slug": row.get::<String, _>("slug"),
                "description": row.get::<Option<String>, _>("description"),
                "status": row.get::<String, _>("status"),
                "created_at": row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
            })).collect();
            HttpResponse::Ok().json(serde_json::json!({"success": true, "data": {"items": orgs}}))
        }
        Err(e) => {
            tracing::error!("List organizations error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to list organizations"}))
        }
    }
}

pub async fn get_organization(pool: web::Data<PgPool>, path: web::Path<Uuid>) -> HttpResponse {
    let org_id = path.into_inner();
    
    let result = sqlx::query(
        "SELECT id, name, slug, description, status, created_at FROM organizations WHERE id = $1"
    )
    .bind(org_id)
    .fetch_optional(pool.get_ref())
    .await;

    match result {
        Ok(Some(row)) => {
            HttpResponse::Ok().json(serde_json::json!({
                "success": true,
                "data": {
                    "id": row.get::<Uuid, _>("id"),
                    "name": row.get::<String, _>("name"),
                    "slug": row.get::<String, _>("slug"),
                    "description": row.get::<Option<String>, _>("description"),
                    "status": row.get::<String, _>("status"),
                    "created_at": row.get::<chrono::DateTime<chrono::Utc>, _>("created_at")
                }
            }))
        }
        Ok(None) => HttpResponse::NotFound().json(serde_json::json!({"error": "Organization not found"})),
        Err(e) => {
            tracing::error!("Get organization error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to get organization"}))
        }
    }
}

pub async fn update_organization(pool: web::Data<PgPool>, path: web::Path<Uuid>, req: web::Json<serde_json::Value>) -> HttpResponse {
    let org_id = path.into_inner();
    
    let name = req.get("name").and_then(|v| v.as_str());
    let description = req.get("description").and_then(|v| v.as_str());

    let result = sqlx::query(
        "UPDATE organizations SET name = COALESCE($2, name), description = COALESCE($3, description), updated_at = NOW() WHERE id = $1"
    )
    .bind(org_id)
    .bind(name)
    .bind(description)
    .execute(pool.get_ref())
    .await;

    match result {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({"success": true})),
        Err(e) => {
            tracing::error!("Update organization error: {}", e);
            HttpResponse::InternalServerError().json(serde_json::json!({"error": "Failed to update organization"}))
        }
    }
}
