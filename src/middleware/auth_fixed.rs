use actix_web::{
    dev::{forward_ready, Service, ServiceRequest, ServiceResponse, Transform},
    http::header::HeaderValue,
    web, Error, HttpMessage,
};
use futures::future::{ready, LocalBoxFuture, Ready};
use std::rc::Rc;
use std::fs;
use uuid::Uuid;

use crate::utils::auth::validate_jwt;

pub struct Auth;

impl<S, B> Transform<S, ServiceRequest> for Auth
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Transform = AuthMiddleware<S>;
    type InitError = ();
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ready(Ok(AuthMiddleware {
            service: Rc::new(service),
        }))
    }
}

pub struct AuthMiddleware<S> {
    service: Rc<S>,
}

impl<S, B> Service<ServiceRequest> for AuthMiddleware<S>
where
    S: Service<ServiceRequest, Response = ServiceResponse<B>, Error = Error> + 'static,
    S::Future: 'static,
    B: 'static,
{
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = LocalBoxFuture<'static, Result<Self::Response, Self::Error>>;
    
    forward_ready!(service);
    
    fn call(&self, req: ServiceRequest) -> Self::Future {
        let service = Rc::clone(&self.service);
        
        // Read JWT secret from file directly
        let jwt_secret_result = fs::read_to_string("jwt_secret.txt");
        
        // Get authorization header
        let auth_header = req.headers().get("Authorization").cloned();
        
        Box::pin(async move {
            // Handle JWT secret read result
            let jwt_secret = match jwt_secret_result {
                Ok(secret) => secret.trim().to_string(), // Trim any whitespace
                Err(_) => {
                    return Err(actix_web::error::ErrorInternalServerError("Failed to read JWT secret"));
                }
            };
            
            let token = match extract_token_from_header(auth_header.as_ref()) {
                Some(t) => t,
                None => {
                    return Err(actix_web::error::ErrorUnauthorized(
                        "Authorization header missing or invalid"
                    ));
                }
            };
            
            // Validate and extract user ID from token
            match validate_jwt(&token, &jwt_secret) {
                Ok(user_id) => {
                    // Insert user_id as an app_data for handlers
                    req.app_data::<web::Data<Uuid>>()
                        .map(|current| {
                            *current.as_ref()
                        });
                    
                    // Add user_id to request extensions
                    req.extensions_mut().insert(user_id);
                    
                    service.call(req).await
                },
                Err(e) => {
                    Err(actix_web::error::ErrorUnauthorized(e.to_string()))
                }
            }
        })
    }
}

fn extract_token_from_header(header: Option<&HeaderValue>) -> Option<String> {
    header.and_then(|h| {
        let header_str = h.to_str().ok()?;
        if header_str.starts_with("Bearer ") {
            Some(header_str[7..].to_string())
        } else {
            None
        }
    })
}
