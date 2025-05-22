use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;
use serde::Deserialize;

#[derive(Deserialize)]
pub struct FundAmount {
    pub amount: f64,
}

pub async fn fund_user_balance(
    pool: web::Data<PgPool>,
    path: web::Path<Uuid>,
    data: web::Json<FundAmount>,
) -> impl Responder {
    let user_id = path.into_inner();
    let amount = data.amount;

    if amount <= 0.0 {
        return HttpResponse::BadRequest().json({
            serde_json::json!({ "error": "Amount must be greater than 0" })
        });
    }

   let result = sqlx::query(
    r#"
    UPDATE accounts
    SET balance = balance + $1
    WHERE user_id = $2
    "#
)
.bind(amount)
.bind(user_id)
.execute(pool.get_ref())
.await;

    match result {
        Ok(res) if res.rows_affected() > 0 => {
            HttpResponse::Ok().json({
                serde_json::json!({ "status": "success", "user_id": user_id, "credited": amount })
            })
        }
        Ok(_) => HttpResponse::NotFound().json({
            serde_json::json!({ "error": "User not found or has no account" })
        }),
        Err(err) => HttpResponse::InternalServerError().json({
            serde_json::json!({ "error": format!("DB error: {}", err) })
        }),
    }
}