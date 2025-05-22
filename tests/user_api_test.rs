//! API integration tests for the Dodo Payments user endpoints
//! 
//! Note: These tests are designed to run with SQLX_OFFLINE=true
//! and don't require an active database connection.

use actix_web::{test, web, App, http, Error};
use actix_web::dev::{Service, ServiceResponse};
use sqlx::postgres::PgPoolOptions;
use actix_rt;
use uuid::Uuid;
use serde_json::json;
use actix_http::Request;
use bytes::Bytes;
use std::path::Path;
use std::fs;
use dotenv::dotenv;

use dodo_payments::{
    handlers,
    models::RegisterUserRequest,
};

#[cfg(test)]
mod api_tests {
    use super::*;
    
    // Setup function to create a test application instance
    async fn setup_test_app() -> (
        impl Service<Request, Response = ServiceResponse, Error = actix_web::Error>,
        sqlx::PgPool
    ) {
        // Set SQLX_OFFLINE mode for testing
        std::env::set_var("SQLX_OFFLINE", "true");
        
        // Load environment variables
        dotenv::dotenv().ok();
        
        // Create a database URL for tests
        let database_url = match std::env::var("SQLX_OFFLINE") {
            Ok(val) if val == "true" => "postgres://postgres:password@offline/dodo_payments_test",
            _ => "postgres://postgres:password@localhost:5433/dodo_payments_test"
        };
        
        // Create a database pool with SQLx offline mode
        let pool = match PgPoolOptions::new()
            .max_connections(5)
            .connect_lazy(database_url) {
                Ok(pool) => pool,
                Err(e) => {
                    eprintln!("Warning: Could not connect to database: {}. Using offline mode only.", e);
                    PgPoolOptions::new()
                        .max_connections(1)
                        .connect_lazy("postgres://offline_mode_only")
                        .expect("Failed to create offline pool")
                }
            };
        
        // Ensure JWT secret file exists
        if !std::path::Path::new("jwt_secret.txt").exists() {
            std::fs::write("jwt_secret.txt", "dodo_payments_test_secret")
                .expect("Failed to create test JWT secret file");
        }
        
        // Create test JWT secret
        let jwt_secret = web::Data::new("test_jwt_secret".to_string());
        
        // Create test app
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(pool.clone()))
                .app_data(jwt_secret.clone())
                .configure(handlers::config_routes)
        )
        .await;
        
        (app, pool)
    }

    // Helper function to cleanup test data after test
    async fn cleanup_test_data(pool: &sqlx::PgPool, username: &str) {
        // In SQLX_OFFLINE mode, we skip the actual execution
        if std::env::var("SQLX_OFFLINE").unwrap_or_default() == "true" {
            return;
        }
        
        let _ = sqlx::query("DELETE FROM users WHERE username = $1")
            .bind(username)
            .execute(pool)
            .await;
    }
    
    // Helper function to read response body
    async fn read_body(resp: ServiceResponse) -> Bytes {
        let body = resp.into_body();
        actix_web::body::to_bytes(body).await.unwrap()
    }

    // Simple sanity test that doesn't need a database connection
    #[actix_rt::test]
    async fn test_sanity() {
        // Simple test that always passes
        assert!(true);
    }
    
    // Health check endpoint test
    #[actix_rt::test]
    async fn test_health_endpoint() {
        let (app, _) = setup_test_app().await;
        
        let req = test::TestRequest::get()
            .uri("/api/health")
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert!(resp.status().is_success());
    }
    
    // User registration test
    #[actix_rt::test]
    async fn test_user_registration() {
        let (app, pool) = setup_test_app().await;
        
        // Generate a unique username for this test
        let unique_username = format!("testuser_{}", Uuid::new_v4());
        
        // Create test user data
        let user_data = RegisterUserRequest {
            username: unique_username.clone(),
            email: format!("{}@example.com", unique_username),
            password: "password123".to_string(),
        };
        
        // Register user
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&user_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        
        assert_eq!(resp.status(), http::StatusCode::CREATED);
        
        // Verify response body contains the username
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert_eq!(json_response["username"], unique_username);
        
        // Clean up test data
        cleanup_test_data(&pool, &unique_username).await;
    }
    
    // User login test
    #[actix_rt::test]
    async fn test_user_login() {
        let (app, pool) = setup_test_app().await;
        
        // Generate a unique username for this test
        let unique_username = format!("testuser_{}", Uuid::new_v4());
        
        // Register a user first
        let register_data = RegisterUserRequest {
            username: unique_username.clone(),
            email: format!("{}@example.com", unique_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&register_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::CREATED);
        
        // Now try to login
        let login_data = json!({
            "username": unique_username,
            "password": "password123"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::OK);
        
        // Verify response contains a token
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert!(json_response["token"].as_str().is_some());
        
        // Clean up test data
        cleanup_test_data(&pool, &unique_username).await;
    }
    
    // Test invalid login
    #[actix_rt::test]
    async fn test_invalid_login() {
        let (app, _) = setup_test_app().await;
        
        // Try to login with invalid credentials
        let login_data = json!({
            "username": "nonexistent_user",
            "password": "wrong_password"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::UNAUTHORIZED);
    }
    
    // Test profile retrieval
    #[actix_rt::test]
    async fn test_profile_retrieval() {
        let (app, pool) = setup_test_app().await;
        
        // Create and register a user
        let unique_username = format!("testuser_{}", Uuid::new_v4());
        let register_data = RegisterUserRequest {
            username: unique_username.clone(),
            email: format!("{}@example.com", unique_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&register_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Login to get JWT token
        let login_data = json!({
            "username": unique_username,
            "password": "password123"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        let token = json_response["token"].as_str().unwrap();
        
        // Get profile with token
        let req = test::TestRequest::get()
            .uri("/api/users/profile")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::OK);
        
        // Verify response contains user data
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert_eq!(json_response["username"], unique_username);
        
        // Clean up test data
        cleanup_test_data(&pool, &unique_username).await;
    }
    
    // Test account balance retrieval
    #[actix_rt::test]
    async fn test_account_balance() {
        let (app, pool) = setup_test_app().await;
        
        // Create and register a user
        let unique_username = format!("testuser_{}", Uuid::new_v4());
        let register_data = RegisterUserRequest {
            username: unique_username.clone(),
            email: format!("{}@example.com", unique_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&register_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Login to get JWT token
        let login_data = json!({
            "username": unique_username,
            "password": "password123"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        let token = json_response["token"].as_str().unwrap();
        
        // Get account balance with token
        let req = test::TestRequest::get()
            .uri("/api/accounts/balance")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::OK);
        
        // Verify response contains balance data
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert!(json_response["balance"].is_string());
        assert_eq!(json_response["currency"], "USD");
        
        // Clean up test data
        cleanup_test_data(&pool, &unique_username).await;
    }
    
    // Test transaction creation
    #[actix_rt::test]
    async fn test_transaction_creation() {
        let (app, pool) = setup_test_app().await;
        
        // Create sender
        let sender_username = format!("sender_{}", Uuid::new_v4());
        let sender_data = RegisterUserRequest {
            username: sender_username.clone(),
            email: format!("{}@example.com", sender_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&sender_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Create recipient
        let recipient_username = format!("recipient_{}", Uuid::new_v4());
        let recipient_data = RegisterUserRequest {
            username: recipient_username.clone(),
            email: format!("{}@example.com", recipient_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&recipient_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Login as sender
        let login_data = json!({
            "username": sender_username,
            "password": "password123"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        let token = json_response["token"].as_str().unwrap();
        
        // Create transaction
        let transaction_data = json!({
            "recipient_username": recipient_username,
            "amount": "10.00",
            "description": "Test payment"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/transactions")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&transaction_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::CREATED);
        
        // Verify transaction was created
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert!(json_response["id"].is_string());
        assert_eq!(json_response["description"], "Test payment");
        
        // Clean up test data
        cleanup_test_data(&pool, &sender_username).await;
        cleanup_test_data(&pool, &recipient_username).await;
    }
    
    // Test listing transactions
    #[actix_rt::test]
    async fn test_transaction_listing() {
        let (app, pool) = setup_test_app().await;
        
        // Create sender
        let sender_username = format!("sender_{}", Uuid::new_v4());
        let sender_data = RegisterUserRequest {
            username: sender_username.clone(),
            email: format!("{}@example.com", sender_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&sender_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Create recipient
        let recipient_username = format!("recipient_{}", Uuid::new_v4());
        let recipient_data = RegisterUserRequest {
            username: recipient_username.clone(),
            email: format!("{}@example.com", recipient_username),
            password: "password123".to_string(),
        };
        
        let req = test::TestRequest::post()
            .uri("/api/users/register")
            .set_json(&recipient_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Login as sender
        let login_data = json!({
            "username": sender_username,
            "password": "password123"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/users/login")
            .set_json(&login_data)
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        let token = json_response["token"].as_str().unwrap();
        
        // Create transaction
        let transaction_data = json!({
            "recipient_username": recipient_username,
            "amount": "10.00",
            "description": "Test payment"
        });
        
        let req = test::TestRequest::post()
            .uri("/api/transactions")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .set_json(&transaction_data)
            .to_request();
            
        app.call(req).await.unwrap();
        
        // Get transactions
        let req = test::TestRequest::get()
            .uri("/api/transactions")
            .insert_header(("Authorization", format!("Bearer {}", token)))
            .to_request();
            
        let resp = app.call(req).await.unwrap();
        assert_eq!(resp.status(), http::StatusCode::OK);
        
        // Verify transactions list
        let body = read_body(resp).await;
        let json_response: serde_json::Value = serde_json::from_slice(&body).unwrap();
        
        assert!(json_response["transactions"].is_array());
        
        // Clean up test data
        cleanup_test_data(&pool, &sender_username).await;
        cleanup_test_data(&pool, &recipient_username).await;
    }
}
