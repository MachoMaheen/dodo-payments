use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;

pub async fn health_check(pool: web::Data<PgPool>) -> impl Responder {
    match sqlx::query("SELECT 1").execute(pool.get_ref()).await {
        Ok(_) => HttpResponse::Ok().json(serde_json::json!({ 
            "status": "ok",
            "message": "Service is healthy"
        })),
        Err(e) => {
            log::error!("Health check failed: {}", e);
            HttpResponse::ServiceUnavailable().json(serde_json::json!({
                "status": "error",
                "message": "Database connection failed"
            }))
        }
    }
}
