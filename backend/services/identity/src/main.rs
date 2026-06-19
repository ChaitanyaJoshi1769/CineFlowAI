use actix_web::{web, App, HttpServer, middleware};
use sqlx::postgres::PgPoolOptions;
use std::env;
use tracing_subscriber;

mod handlers;
mod models;
mod db;
mod auth;
mod errors;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // Load environment variables
    dotenv::dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let redis_url = env::var("REDIS_URL").expect("REDIS_URL must be set");
    let jwt_secret = env::var("JWT_SECRET").expect("JWT_SECRET must be set");
    let api_host = env::var("API_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let api_port = env::var("API_PORT").unwrap_or_else(|_| "8001".to_string());

    // Create database pool
    let database_pool = PgPoolOptions::new()
        .max_connections(20)
        .connect(&database_url)
        .await
        .expect("Failed to create database pool");

    // Run migrations
    sqlx::query(include_str!("../../migrations/001_create_users.sql"))
        .execute(&database_pool)
        .await
        .ok();

    tracing::info!("Identity Service starting on {}:{}", api_host, api_port);

    let bind_addr = format!("{}:{}", api_host, api_port);

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(database_pool.clone()))
            .app_data(web::Data::new(jwt_secret.clone()))
            .wrap(middleware::Logger::default())
            .route("/health", web::get().to(handlers::health))
            .route("/ready", web::get().to(handlers::ready))
            .service(
                web::scope("/api/v1/auth")
                    .route("/register", web::post().to(handlers::auth::register))
                    .route("/login", web::post().to(handlers::auth::login))
                    .route("/refresh", web::post().to(handlers::auth::refresh_token))
                    .route("/verify", web::post().to(handlers::auth::verify_token))
                    .route("/logout", web::post().to(handlers::auth::logout))
            )
            .service(
                web::scope("/api/v1/users")
                    .route("", web::get().to(handlers::users::list_users))
                    .route("/{user_id}", web::get().to(handlers::users::get_user))
                    .route("/{user_id}", web::put().to(handlers::users::update_user))
                    .route("/{user_id}", web::delete().to(handlers::users::delete_user))
            )
            .service(
                web::scope("/api/v1/organizations")
                    .route("", web::post().to(handlers::organizations::create_organization))
                    .route("", web::get().to(handlers::organizations::list_organizations))
                    .route("/{org_id}", web::get().to(handlers::organizations::get_organization))
                    .route("/{org_id}", web::put().to(handlers::organizations::update_organization))
            )
            .service(
                web::scope("/api/v1/permissions")
                    .route("/{user_id}", web::get().to(handlers::permissions::get_user_permissions))
                    .route("", web::post().to(handlers::permissions::grant_permission))
                    .route("/{permission_id}", web::delete().to(handlers::permissions::revoke_permission))
            )
    })
    .bind(&bind_addr)?
    .run()
    .await
}
