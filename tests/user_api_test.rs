use actix_web::{test, web, App};
use serde_json::json;
use sqlx::postgres::PgPoolOptions;
use uuid::Uuid;

use dodo_payments::{
    config::Config,
    handlers,
    models::{RegisterUserRequest, TokenResponse, UserResponse},
};

#[cfg(test)]
mod tests {
    use super::*;

    async fn setup_test_app() -> (actix_web::test::TestApp, sqlx::PgPool) {
        // Load environment variables
        dotenv::dotenv().ok();
        
        // Get database URL from environment or use a test-specific one
        let database_url = std::env::var("TEST_DATABASE_URL")
            .unwrap_or_else(|_| "postgres://postgres:password@localhost:5432/dodo_payments_test".to_string());
        
        // Connect to the database
        let pool = PgPoolOptions::new()
            .max_connections(5)
            .connect(&database_url)
            .await
            .expect("Failed to connect to database");
        
        // Create test JWT secret
        let jwt_secret = web::Data::new("test_jwt_secret".to_string());
        
        // Create test app
        let app = test::init_service(
            App::new()
                .app_data(web::Data::new(pool.clone()))
                .app_data(jwt_secret.clone())
                .configure(handlers::config_routes),
        )
        .await;
        
        (app, pool)
    }

    // Helper function to cleanup test data after test
    async fn cleanup_test_data(pool: &sqlx::PgPool, username: &str) {
        let _ = sqlx::query!("DELETE FROM users WHERE username = $1", username)
            .execute(pool)
            .await;
    }

    #[actix_web::test]
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
            .uri("/users/register")
            .set_json(&user_data)
            .to_request();
        
        let resp: UserResponse = test::call_and_read_body_json(&app, req).await;
        
        // Check that the response contains the expected username
        assert_eq!(resp.username, unique_username);
        
        // Clean up test data
        cleanup_test_data(&pool, &unique_username).await;
    }
}
