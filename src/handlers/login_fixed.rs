use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;
use serde::{Serialize, Deserialize};

use crate::utils::auth::{verify_password, generate_jwt};
use crate::models::{AppError, User, LoginUserRequest};

#[derive(Debug, Serialize, Deserialize)]
pub struct TokenResponseFixed {
    pub token: String,
    pub token_type: String,
}

impl TokenResponseFixed {
    pub fn new(token: String) -> Self {
        Self {
            token,
            token_type: "Bearer".to_string(),
        }
    }
}

/// Login user and return JWT token with improved response formatting
pub async fn login_fixed(
    pool: web::Data<PgPool>,
    login_data: web::Json<LoginUserRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    login_data.validate()?;
    
    // Find user by username
    let user = sqlx::query_as::<_, User>(
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE username = $1
        "#
    )
    .bind(&login_data.username)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::AuthenticationError("Invalid username or password".to_string()))?;
    
    // Verify password
    if !verify_password(&login_data.password, &user.password_hash)? {
        return Err(AppError::AuthenticationError("Invalid username or password".to_string()));
    }
    
    // Read JWT secret
    let jwt_secret = std::fs::read_to_string("jwt_secret.txt")
        .map_err(|e| AppError::InternalServerError(format!("Failed to read JWT secret: {}", e)))?;
    
    // Generate JWT token
    let token = generate_jwt(user.id, &jwt_secret)?;
    
    // Return token with improved formatting by using HttpResponse directly
    let token_response = TokenResponseFixed::new(token);
    
    Ok(HttpResponse::Ok()
        .content_type("application/json")
        .json(token_response))
}
