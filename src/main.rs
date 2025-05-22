use std::env;
use std::io::Result;
use std::fs;

use actix_cors::Cors;
use actix_web::{middleware as actix_middleware, web, App, HttpServer};
use dotenv::dotenv;
use log::info;
use sqlx::postgres::PgPoolOptions;

#[actix_web::main]
async fn main() -> Result<()> {
    // Load environment variables from .env file
    dotenv().ok();
    
    // Initialize logger
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    // Get server address from environment or use default
    let server_addr = env::var("SERVER_ADDR").unwrap_or_else(|_| "127.0.0.1:8080".to_string());
    info!("Starting server on {}", server_addr);
    
    // Get database URL from environment or use default
    let database_url = env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://postgres:password@localhost:5432/dodo_payments".to_string());
    
    // Create database connection pool
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect_lazy(&database_url)
        .expect("Failed to create database connection pool");
    
    // Read JWT secret from file or environment variable
    let jwt_secret = env::var("JWT_SECRET").ok().unwrap_or_else(|| {
        fs::read_to_string("jwt_secret.txt")
            .unwrap_or_else(|_| {
                info!("JWT secret not found, using default value");
                "dodo_payments_default_secret".to_string()
            })
    });
    
    info!("JWT secret loaded (length: {})", jwt_secret.len());
    
    // Create data that will be shared across requests
    let pool_data = web::Data::new(pool);
    let jwt_secret_data = web::Data::new(jwt_secret);
      // Run the server
    HttpServer::new(move || {
        // Set up CORS
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);
        
       App::new()
    .wrap(cors)
    .wrap(actix_middleware::Logger::default())
    .app_data(pool_data.clone())
    .app_data(jwt_secret_data.clone())
    .configure(dodo_payments::handlers::config_routes)

    })
    .bind(server_addr)?
    .run()
    .await
}
