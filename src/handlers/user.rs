use actix_web::{web, HttpResponse, Responder};
use log::error;
use sqlx::PgPool;
use uuid::Uuid;
use validator::Validate;

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
    let existing_user = sqlx::query!(
        "SELECT username FROM users WHERE username = $1",
        user_data.username
    )
    .fetch_optional(pool.get_ref())
    .await?;
    
    if existing_user.is_some() {
        return Err(AppError::ConflictError("Username already taken".to_string()));
    }
    
    // Check if email already exists
    let existing_email = sqlx::query!(
        "SELECT email FROM users WHERE email = $1",
        user_data.email
    )
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
    let user = sqlx::query_as!(
        User,
        r#"
        INSERT INTO users (username, email, password_hash)
        VALUES ($1, $2, $3)
        RETURNING id, username, email, password_hash, created_at, updated_at
        "#,
        user_data.username,
        user_data.email,
        password_hash
    )
    .fetch_one(&mut tx)
    .await?;
    
    // Create an account for the user with zero balance
    sqlx::query!(
        r#"
        INSERT INTO accounts (user_id, balance, currency)
        VALUES ($1, $2, $3)
        "#,
        user.id,
        0.0,
        "USD" // Default currency
    )
    .execute(&mut tx)
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
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE username = $1
        "#,
        login_data.username
    )
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::AuthenticationError("Invalid username or password".to_string()))?;
    
    // Verify password
    if !verify_password(&login_data.password, &user.password_hash)? {
        return Err(AppError::AuthenticationError("Invalid username or password".to_string()));
    }
    
    // Generate JWT token
    let token = generate_jwt(&user, jwt_secret.get_ref())?;
    
    Ok(HttpResponse::Ok().json(TokenResponse {
        token,
        token_type: "Bearer".to_string(),
    }))
}

pub async fn get_profile(user_id: web::ReqData<Uuid>, pool: web::Data<PgPool>) -> Result<impl Responder, AppError> {
    let user = sqlx::query_as!(
        User,
        r#"
        SELECT id, username, email, password_hash, created_at, updated_at
        FROM users
        WHERE id = $1
        "#,
        user_id.into_inner()
    )
    .fetch_one(pool.get_ref())
    .await?;
    
    Ok(HttpResponse::Ok().json(UserResponse::from(user)))
}

pub async fn update_profile(
    user_id: web::ReqData<Uuid>, 
    pool: web::Data<PgPool>,
    // TODO: Implement profile update request
) -> Result<impl Responder, AppError> {
    // This is a placeholder for future implementation
    Ok(HttpResponse::NotImplemented().json(serde_json::json!({
        "message": "Profile update not implemented yet"
    })))
}
