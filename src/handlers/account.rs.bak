use actix_web::{web, HttpResponse, Responder};
use sqlx::PgPool;
use uuid::Uuid;

use crate::models::{Account, AccountBalanceResponse, AppError};

pub async fn get_balance(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
) -> Result<impl Responder, AppError> {
    let account = sqlx::query_as!(
        Account,
        r#"
        SELECT id, user_id, balance, currency, created_at, updated_at
        FROM accounts
        WHERE user_id = $1
        "#,
        user_id.into_inner()
    )
    .fetch_one(pool.get_ref())
    .await?;
    
    Ok(HttpResponse::Ok().json(AccountBalanceResponse::from(account)))
}

// For future implementation: top up account, withdraw funds, etc.
