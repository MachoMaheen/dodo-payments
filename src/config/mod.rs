use std::env;
use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use dotenv::dotenv;
use log::info;

pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub server_addr: String,
    pub rust_log: String,
}

impl Config {
    pub fn from_env() -> Self {
        dotenv().ok();
        
        // Get database URL with potential Docker secrets
        let database_url = Self::get_database_url();
        
        // Get JWT secret from Docker secrets or environment variable
        let jwt_secret = Self::get_jwt_secret();
        
        let server_addr = env::var("SERVER_ADDR")
            .unwrap_or_else(|_| "127.0.0.1:8080".to_string());
        
        let rust_log = env::var("RUST_LOG")
            .unwrap_or_else(|_| "info".to_string());
        
        Self {
            database_url,
            jwt_secret,
            server_addr,
            rust_log,
        }
    }
    
    fn get_database_url() -> String {
        // Check if we have Docker secrets for database credentials
        let db_user = Self::get_db_user();
        let db_password = Self::get_db_password();
        
        // Try to get connection details from environment variables
        let db_host = env::var("DB_HOST").unwrap_or_else(|_| "db".to_string());
        let db_port = env::var("DB_PORT").unwrap_or_else(|_| "5432".to_string());
        let db_name = env::var("DB_NAME").unwrap_or_else(|_| "dodo_payments".to_string());
        
        // If DATABASE_URL is explicitly set, use that instead
        if let Ok(url) = env::var("DATABASE_URL") {
            info!("Using DATABASE_URL from environment variable");
            return url;
        }
        
        // Construct the URL from components
        let url = format!(
            "postgres://{}:{}@{}:{}/{}",
            db_user, db_password, db_host, db_port, db_name
        );
        
        info!("Constructed database URL from components");
        url
    }
    
    fn get_db_user() -> String {
        // First try to read from Docker secret file
        if let Ok(user) = std::fs::read_to_string("/run/secrets/db_user") {
            let user = user.trim();
            info!("Using database user from Docker secret file");
            return user.to_string();
        }
        
        // Fall back to environment variable
        env::var("POSTGRES_USER").unwrap_or_else(|_| {
            info!("Using default database user: postgres");
            "postgres".to_string()
        })
    }
    
    fn get_db_password() -> String {
        // First try to read from Docker secret file
        if let Ok(password) = std::fs::read_to_string("/run/secrets/db_password") {
            let password = password.trim();
            info!("Using database password from Docker secret file");
            return password.to_string();
        }
        
        // Fall back to environment variable
        env::var("POSTGRES_PASSWORD").unwrap_or_else(|_| {
            info!("Using default database password (NOT SECURE FOR PRODUCTION)");
            "password".to_string()
        })
    }
    
    fn get_jwt_secret() -> String {
        // First try to read from Docker secret file
        if let Ok(secret) = std::fs::read_to_string("/run/secrets/jwt_secret") {
            let secret = secret.trim();
            info!("Using JWT secret from Docker secret file");
            return secret.to_string();
        }
        
        // Then try reading from local file (for local Docker development)
        if let Ok(secret) = std::fs::read_to_string("jwt_secret.txt") {
            let secret = secret.trim();
            info!("Using JWT secret from local file");
            return secret.to_string();
        }
        
        // Fall back to environment variable
        match env::var("JWT_SECRET") {
            Ok(secret) => {
                info!("Using JWT secret from environment variable");
                secret
            },
            Err(_) => {
                info!("JWT_SECRET not found, using default (NOT SECURE FOR PRODUCTION)");
                "development_jwt_secret_not_secure".to_string()
            }
        }
    }
}



// Function to set up the database pool
pub async fn setup_database_pool(database_url: &str) -> PgPool {
    PgPoolOptions::new()
        .max_connections(10)
        .acquire_timeout(Duration::from_secs(5))
        .connect(database_url)
        .await
        .expect("Failed to create database connection pool")
}
pub mod db;
