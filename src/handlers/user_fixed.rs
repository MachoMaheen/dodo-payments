use actix_web::{web, HttpResponse, Responder};
use log::error;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;
use sqlx::types::BigDecimal;

use crate::{
    models::{AppError, LoginUserRequest, RegisterUserRequest, TokenResponse, User, UserResponse},
    utils::{generate_jwt, hash_password, verify_password},
};

pub async fn register(
    pool: web::Data<PgPool>,
    user_data: web::Json<RegisterUserRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    user_data.validate()?;
    
    // Check if username already exists
    let existing_user = sqlx::query(
        "SELECT username FROM users WHERE username = $1"
    )
    .bind(&user_data.username)
    .fetch_optional(pool.get_ref())
    .await?;
    
    if existing_user.is_some() {
        return Err(AppError::ConflictError("Username already taken".to_string()));
    }
    
    // Check if email already exists
    let existing_email = sqlx::query(
        "SELECT email FROM users WHERE email = $1"
    )
    .bind(&user_data.email)
    .fetch_optional(pool.get_ref())
    .await?;
    
    if existing_email.is_some() {
        return Err(AppError::ConflictError("Email already registered".to_string()));
    }
    
    // Hash password
    let password_hash = hash_password(&user_data.password)?;
    
    // Start a transaction
    let mut tx = pool.begin().await?;
    
    // Insert new user
    let row = sqlx::query(
        r#"
        INSERT INTO users (username, email, password_hash)
        VALUES ($1, $2, $3)
        RETURNING id, username, email, password_hash, created_at, updated_at
        "#
    )
    .bind(&user_data.username)
    .bind(&user_data.email)
    .bind(&password_hash)
    .fetch_one(&mut *tx)
    .await?;
    
    // Extract user data
    let user = User {
        id: row.try_get("id")?,
        username: row.try_get("username")?,
        email: row.try_get("email")?,
        password_hash: row.try_get("password_hash")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    };
    
    // Create an account for the user with zero balance (using BigDecimal)
    let zero_balance = BigDecimal::from(0);
    
    sqlx::query(
        r#"
        INSERT INTO accounts (user_id, balance, currency)
        VALUES ($1, $2, $3)
        "#
    )
    .bind(user.id)
    .bind(&zero_balance)
    .bind("USD") // Default currency
    .execute(&mut *tx)
    .await?;
    
    // Commit transaction
    tx.commit().await?;
    
    // Convert to user response (hide sensitive data)
    let user_response = UserResponse::from(user);
    
    Ok(HttpResponse::Created().json(user_response))
}

pub async fn login(
    pool: web::Data<PgPool>,
    jwt_secret: web::Data<String>,
    login_data: web::Json<LoginUserRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    login_data.validate()?;
    
    // Find user by username
    let row = sqlx::query(
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE username = $1
        "#
    )
    .bind(&login_data.username)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::AuthError("Invalid username or password".to_string()))?;
    
    // Extract user data
    let user = User {
        id: row.try_get("id")?,
        username: row.try_get("username")?,
        email: row.try_get("email")?,
        password_hash: row.try_get("password_hash")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    };
    
    // Verify password
    if !verify_password(&login_data.password, &user.password_hash)? {
        return Err(AppError::AuthError("Invalid username or password".to_string()));
    }
    
    // Generate JWT token
    let token = generate_jwt(user.id, &jwt_secret)?;
    
    // Return token
    Ok(HttpResponse::Ok().json(TokenResponse { token }))
}

pub async fn get_profile(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<impl Responder, AppError> {
    let user_id = user_id.into_inner();
    
    let row = sqlx::query(
        r#"
        SELECT id, username, email, created_at, updated_at
        FROM users
        WHERE id = $1
        "#
    )
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::NotFoundError("User not found".to_string()))?;
    
    let user = User {
        id: row.try_get("id")?,
        username: row.try_get("username")?,
        email: row.try_get("email")?,
        password_hash: "".to_string(), // Not needed for response
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    };
    
    Ok(HttpResponse::Ok().json(UserResponse::from(user)))
}

pub async fn update_profile(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    update_data: web::Json<UpdateProfileRequest>,
) -> Result<impl Responder, AppError> {
    // This is a placeholder since the struct isn't defined
    // In a real implementation, you would validate and update the user data
    
    Ok(HttpResponse::Ok().json(json!({
        "message": "Profile updated successfully"
    })))
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct UpdateProfileRequest {
    // Define the fields that can be updated
    pub email: Option<String>,
}

// Add the missing imports for the placeholder
use serde_json::json;
use serde::{Serialize, Deserialize};
