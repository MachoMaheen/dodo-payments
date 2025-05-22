use actix_web::{web, HttpResponse, Responder};
use serde::{Serialize, Deserialize};
use uuid::Uuid;

// Fixed token structure for proper JSON serialization
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

// Wrapper for token response
pub async fn json_token_response(token: String) -> impl Responder {
    let token_response = TokenResponseFixed::new(token);
    
    // Use HttpResponse to ensure proper serialization
    HttpResponse::Ok()
        .content_type("application/json")
        .json(token_response)
}
