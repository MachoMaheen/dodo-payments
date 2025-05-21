use crate::models::User;
use crate::utils::{generate_jwt, hash_password, validate_jwt, verify_password};
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_user() -> User {
        User {
            id: Uuid::new_v4(),
            username: "testuser".to_string(),
            password_hash: "hash".to_string(),
            email: "test@example.com".to_string(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
        }
    }

    #[test]
    fn test_password_hashing_and_verification() {
        let password = "my_secure_password";
        let hash = hash_password(password).expect("Failed to hash password");
        
        // Hash should not be the same as the original password
        assert_ne!(password, hash);
        
        // Verification should succeed with correct password
        let is_valid = verify_password(password, &hash).expect("Failed to verify password");
        assert!(is_valid);
        
        // Verification should fail with incorrect password
        let is_valid = verify_password("wrong_password", &hash).expect("Failed to verify password");
        assert!(!is_valid);
    }

    #[test]
    fn test_jwt_generation_and_validation() {
        let user = create_test_user();
        let secret = "test_secret";
        
        let token = generate_jwt(&user, secret).expect("Failed to generate JWT");
        
        // Token should be a non-empty string
        assert!(!token.is_empty());
        
        // Token validation should succeed
        let user_id = validate_jwt(&token, secret).expect("Failed to validate JWT");
        
        // User ID should match
        assert_eq!(user.id, user_id);
        
        // Validation with wrong secret should fail
        let result = validate_jwt(&token, "wrong_secret");
        assert!(result.is_err());
    }
}
