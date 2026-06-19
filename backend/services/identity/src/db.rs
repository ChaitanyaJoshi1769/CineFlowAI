use sqlx::{PgPool, Row};
use uuid::Uuid;

pub async fn check_database_health(pool: &PgPool) -> Result<(), String> {
    sqlx::query("SELECT 1")
        .fetch_one(pool)
        .await
        .map(|_| ())
        .map_err(|e| format!("Database check failed: {}", e))
}
