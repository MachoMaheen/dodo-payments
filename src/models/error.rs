use actix_web::{ResponseError, HttpResponse};
use serde::Serialize;
use std::fmt;
use validator::ValidationErrors;

#[derive(Debug)]
pub enum AppError {
    InternalServerError(String),
    ValidationError(ValidationErrors),
    AuthenticationError(String),
    NotFoundError(String),
    ConflictError(String),
    BadRequestError(String),
}

#[derive(Serialize)]
pub struct ErrorResponse {
    pub status: String,
    pub message: String,
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::InternalServerError(msg) => write!(f, "Internal server error: {}", msg),
            AppError::ValidationError(_) => write!(f, "Validation error"),
            AppError::AuthenticationError(msg) => write!(f, "Authentication error: {}", msg),
            AppError::NotFoundError(msg) => write!(f, "Not found: {}", msg),
            AppError::ConflictError(msg) => write!(f, "Conflict: {}", msg),
            AppError::BadRequestError(msg) => write!(f, "Bad request: {}", msg),
        }
    }
}

impl ResponseError for AppError {
    fn error_response(&self) -> HttpResponse {
        match self {
            AppError::InternalServerError(msg) => {
                HttpResponse::InternalServerError().json(ErrorResponse {
                    status: "error".into(),
                    message: msg.clone(),
                })
            }
            AppError::ValidationError(errors) => {
                // Convert validation errors to a more user-friendly format
                let error_messages: Vec<String> = errors
                    .field_errors()
                    .iter()
                    .map(|(field, errors)| {
                        let messages: Vec<String> = errors
                            .iter()
                            .map(|error| error.message.as_ref().unwrap_or(&error.code).to_string())
                            .collect();
                        format!("{}: {}", field, messages.join(", "))
                    })
                    .collect();

                HttpResponse::BadRequest().json(ErrorResponse {
                    status: "error".into(),
                    message: error_messages.join("; "),
                })
            }
            AppError::AuthenticationError(msg) => {
                HttpResponse::Unauthorized().json(ErrorResponse {
                    status: "error".into(),
                    message: msg.clone(),
                })
            }
            AppError::NotFoundError(msg) => {
                HttpResponse::NotFound().json(ErrorResponse {
                    status: "error".into(),
                    message: msg.clone(),
                })
            }
            AppError::ConflictError(msg) => {
                HttpResponse::Conflict().json(ErrorResponse {
                    status: "error".into(),
                    message: msg.clone(),
                })
            }
            AppError::BadRequestError(msg) => {
                HttpResponse::BadRequest().json(ErrorResponse {
                    status: "error".into(),
                    message: msg.clone(),
                })
            }
        }
    }
}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFoundError("Resource not found".into()),
            sqlx::Error::Database(db_err) => {
                if let Some(code) = db_err.code() {
                    if code.as_ref() == "23505" {
                        // Unique violation
                        return AppError::ConflictError("Resource already exists".into());
                    }
                }
                AppError::InternalServerError(format!("Database error: {}", db_err))
            }
            _ => AppError::InternalServerError(format!("Database error: {}", err)),
        }
    }
}

impl From<ValidationErrors> for AppError {
    fn from(errors: ValidationErrors) -> Self {
        AppError::ValidationError(errors)
    }
}
