use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};
use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models::AppError;

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,     // Subject (user ID)
    pub exp: usize,      // Expiration time (as UTC timestamp)
    pub iat: usize,      // Issued at (as UTC timestamp)
}

pub fn hash_password(password: &str) -> Result<String, AppError> {
    let salt = SaltString::generate(&mut OsRng);
    let argon2 = Argon2::default();
    
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|e| AppError::InternalServerError(format!("Password hashing error: {}", e)))
}

pub fn verify_password(password: &str, hash: &str) -> Result<bool, AppError> {
    let parsed_hash = PasswordHash::new(hash)
        .map_err(|e| AppError::InternalServerError(format!("Password parsing error: {}", e)))?;
    
    let result = Argon2::default().verify_password(password.as_bytes(), &parsed_hash);
    Ok(result.is_ok())
}

pub fn generate_jwt(user_id: Uuid, secret: &str) -> Result<String, AppError> {
    let now = Utc::now();
    let iat = now.timestamp() as usize;
    let exp = (now + Duration::hours(24)).timestamp() as usize;
    
    let claims = Claims {
        sub: user_id.to_string(),
        exp,
        iat,
    };
    
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(|e| AppError::InternalServerError(format!("JWT generation error: {}", e)))
}

// Helper function used by middleware
pub fn validate_jwt(token: &str, secret: &str) -> Result<Uuid, AppError> {
    let decoded = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|e| AppError::AuthenticationError(format!("Invalid token: {}", e)))?;
    
    Uuid::parse_str(&decoded.claims.sub)
        .map_err(|_| AppError::AuthenticationError("Invalid user ID in token".to_string()))
}

// Helper function used by handlers where we don't have the JWT secret as an argument
pub fn create_jwt(user_id: Uuid) -> Result<String, AppError> {
    let jwt_secret = std::fs::read_to_string("jwt_secret.txt")
        .map_err(|e| AppError::InternalServerError(format!("Failed to read JWT secret: {}", e)))?;
    
    generate_jwt(user_id, &jwt_secret)
}
