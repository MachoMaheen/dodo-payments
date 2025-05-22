use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;
use serde::{Serialize, Deserialize};
use bigdecimal::BigDecimal;
use std::str::FromStr;

use crate::utils::auth::{hash_password, verify_password, generate_jwt};
use crate::models::{AppError, User, UserResponse, LoginUserRequest, RegisterUserRequest, TokenResponse};

/// Register a new user
pub async fn register(
    pool: web::Data<PgPool>,
    user_data: web::Json<RegisterUserRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    user_data.validate()?;
    
    // Check if username already exists
    let existing_user = sqlx::query("SELECT username FROM users WHERE username = $1")
        .bind(&user_data.username)
        .fetch_optional(pool.get_ref())
        .await?;
    
    if existing_user.is_some() {
        return Err(AppError::ConflictError("Username already taken".to_string()));
    }
    
    // Check if email already exists
    let existing_email = sqlx::query("SELECT email FROM users WHERE email = $1")
        .bind(&user_data.email)
        .fetch_optional(pool.get_ref())
        .await?;
    
    if existing_email.is_some() {
        return Err(AppError::ConflictError("Email already registered".to_string()));
    }
    
    // Hash password
    let password_hash = hash_password(&user_data.password)?;
    
    // Insert new user without transaction for now
    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, email, password_hash)
        VALUES ($1, $2, $3)
        RETURNING id, username, email, password_hash, created_at, updated_at
        "#
    )
    .bind(&user_data.username)
    .bind(&user_data.email)
    .bind(&password_hash)
    .fetch_one(pool.get_ref())
    .await?;
    
    // Create an account for the user with zero balance
    let zero_balance = BigDecimal::from_str("0").unwrap();
    
    sqlx::query(
        r#"
        INSERT INTO accounts (user_id, balance, currency)
        VALUES ($1, $2, $3)
        "#
    )
    .bind(user.id)
    .bind(&zero_balance)
    .bind("USD") // Default currency
    .execute(pool.get_ref())
    .await?;
    
    // Convert to user response
    let user_response = UserResponse::from(user);
    
    Ok(HttpResponse::Created().json(user_response))
}

/// Login user and return JWT token
pub async fn login(
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
    
    // Return token
    Ok(HttpResponse::Ok().json(TokenResponse::new(token)))
}

/// Get user profile
pub async fn get_profile(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<impl Responder, AppError> {
    let user_id = user_id.into_inner();
    
    // Get user data
    let user = sqlx::query_as::<_, User>(
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE id = $1
        "#
    )
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::NotFoundError("User not found".to_string()))?;
    
    // Return user profile data
    Ok(HttpResponse::Ok().json(UserResponse::from(user)))
}

/// Update user profile
pub async fn update_profile(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    update_data: web::Json<UpdateProfileRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    update_data.validate()?;
    
    let user_id = user_id.into_inner();
    
    // Check if email already exists if it's being updated
    if let Some(ref email) = update_data.email {
        let existing_email = sqlx::query(
            "SELECT id FROM users WHERE email = $1 AND id != $2"
        )
        .bind(email)
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await?;
        
        if existing_email.is_some() {
            return Err(AppError::ConflictError("Email already registered by another user".to_string()));
        }
        
        // Update email
        sqlx::query(
            "UPDATE users SET email = $1, updated_at = NOW() WHERE id = $2"
        )
        .bind(email)
        .bind(user_id)
        .execute(pool.get_ref())
        .await?;
    }
    
    // Get updated user profile
    let user = sqlx::query_as::<_, User>(
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE id = $1
        "#
    )
    .bind(user_id)
    .fetch_one(pool.get_ref())
    .await?;
    
    Ok(HttpResponse::Ok().json(UserResponse::from(user)))
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct UpdateProfileRequest {
    #[validate(email(message = "email must be a valid email address"))]
    pub email: Option<String>,
}
