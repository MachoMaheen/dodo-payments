use std::env;

use actix_cors::Cors;
use actix_web::{middleware, web, App, HttpServer};
use dotenv::dotenv;
use log::info;
use sqlx::postgres::PgPoolOptions;

mod config;
mod handlers;
mod middleware;
mod models;
mod utils;

// Enable SQLx offline mode if needed
#[cfg(feature = "sqlx-macros")]
use crate::config::sqlx_config;

use crate::config::setup_database_pool;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Load environment variables from .env file
    dotenv().ok();
    
    // Enable SQLx offline mode if the feature is enabled
    #[cfg(feature = "sqlx-macros")]
    sqlx_config::enable_sqlx_offline();
    
    // Initialize logger
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    // Get configuration from environment
    let config = config::Config::from_env();
    
    info!("Starting server on {}", config.server_addr);
    
    // Create database connection pool
    let pool = setup_database_pool(&config.database_url).await;
    
    // Create JWT secret as app data
    let jwt_secret = web::Data::new(config.jwt_secret);
    
    // Run the server
    HttpServer::new(move || {
        // Set up CORS
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);
        
        App::new()
            // Add middleware
            .wrap(middleware::Logger::default())
            .wrap(cors)
            // Add app data
            .app_data(web::Data::new(pool.clone()))
            .app_data(jwt_secret.clone())
            // Configure routes
            .configure(handlers::config_routes)
    })
    .bind(config.server_addr)?
    .run()
    .await
}
