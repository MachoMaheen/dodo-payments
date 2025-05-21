use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;
use sqlx::Row; // Explicitly import Row trait
use uuid::Uuid;
use bigdecimal::BigDecimal;

use crate::models::{Account, AccountBalanceResponse, AppError};

pub async fn get_balance(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<impl Responder, AppError> {
    let user_id = user_id.into_inner();
    
    let row = sqlx::query(
        r#"
        SELECT id, user_id, balance, currency, created_at, updated_at
        FROM accounts
        WHERE user_id = $1
        "#
    )
    .bind(user_id)
    .fetch_one(pool.get_ref())
    .await?;
      let account = Account {
        id: row.get("id"),
        user_id: row.get("user_id"),
        balance: row.get("balance"),
        currency: row.get("currency"),
        created_at: row.get("created_at"),
        updated_at: row.get("updated_at"),
    };
    
    Ok(HttpResponse::Ok().json(AccountBalanceResponse::from(account)))
}
