use actix_web::{web, HttpResponse, Responder};
use log::error;
use sqlx::{PgPool, Postgres, Transaction as SqlxTransaction};
use uuid::Uuid;
use validator::Validate;
use sqlx::types::BigDecimal;
use std::str::FromStr;

use crate::models::{
    AppError, CreateTransactionRequest, Transaction, TransactionListResponse, TransactionResponse, TransactionStatus,
};

pub async fn create_transaction(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    transaction_data: web::Json<CreateTransactionRequest>,
) -> Result<impl Responder, AppError> {
    // Validate request data
    transaction_data.validate()?;
    
    let sender_id = user_id.into_inner();
    let recipient_id = transaction_data.recipient_id;
    
    // Ensure sender and recipient are different
    if sender_id == recipient_id {
        return Err(AppError::BadRequestError("Cannot send money to yourself".to_string()));
    }
    
    // Ensure recipient exists
    let recipient_exists = sqlx::query!(
        "SELECT id FROM users WHERE id = $1",
        recipient_id
    )
    .fetch_optional(pool.get_ref())
    .await?
    .is_some();
    
    if !recipient_exists {
        return Err(AppError::NotFoundError("Recipient not found".to_string()));
    }
    
    // Begin transaction
    let mut tx = pool.begin().await?;
    
    // Check sender balance
    let sender_account = sqlx::query!(
        r#"
        SELECT balance, currency FROM accounts
        WHERE user_id = $1
        FOR UPDATE
        "#,
        sender_id
    )
    .fetch_one(&mut tx)
    .await?;
    
    // Ensure sender has enough funds
    if sender_account.balance < transaction_data.amount {
        return Err(AppError::BadRequestError("Insufficient funds".to_string()));
    }
    
    // Ensure currency matches
    if sender_account.currency != transaction_data.currency {
        return Err(AppError::BadRequestError(format!(
            "Currency mismatch: account is in {}, transaction is in {}",
            sender_account.currency, transaction_data.currency
        )));
    }
    
    // Create transaction record
    let transaction = sqlx::query_as!(
        Transaction,
        r#"
        INSERT INTO transactions (sender_id, recipient_id, amount, currency, status)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id, sender_id, recipient_id, amount, currency, status as "status: _", created_at, updated_at
        "#,
        sender_id,
        recipient_id,
        transaction_data.amount,
        transaction_data.currency,
        TransactionStatus::Pending as _
    )
    .fetch_one(&mut tx)
    .await?;
    
    // Update sender's balance
    sqlx::query!(
        r#"
        UPDATE accounts
        SET balance = balance - $1, updated_at = NOW()
        WHERE user_id = $2
        "#,
        transaction_data.amount,
        sender_id
    )
    .execute(&mut tx)
    .await?;
    
    // Update recipient's balance
    sqlx::query!(
        r#"
        UPDATE accounts
        SET balance = balance + $1, updated_at = NOW()
        WHERE user_id = $2
        "#,
        transaction_data.amount,
        recipient_id
    )
    .execute(&mut tx)
    .await?;
    
    // Mark transaction as completed
    let completed_transaction = sqlx::query_as!(
        Transaction,
        r#"
        UPDATE transactions
        SET status = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING id, sender_id, recipient_id, amount, currency, status as "status: _", created_at, updated_at
        "#,
        TransactionStatus::Completed as _,
        transaction.id
    )
    .fetch_one(&mut tx)
    .await?;
    
    // Commit transaction
    tx.commit().await?;
    
    Ok(HttpResponse::Created().json(TransactionResponse::from(completed_transaction)))
}

pub async fn get_transaction(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    transaction_id: web::Path<Uuid>,
) -> Result<impl Responder, AppError> {
    let transaction = sqlx::query_as!(
        Transaction,
        r#"
        SELECT id, sender_id, recipient_id, amount, currency, status as "status: _", created_at, updated_at
        FROM transactions
        WHERE id = $1 AND (sender_id = $2 OR recipient_id = $2)
        "#,
        transaction_id.into_inner(),
        user_id.into_inner()
    )
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::NotFoundError("Transaction not found".to_string()))?;
    
    Ok(HttpResponse::Ok().json(TransactionResponse::from(transaction)))
}

pub async fn list_transactions(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    query: web::Query<ListTransactionsQuery>,
) -> Result<impl Responder, AppError> {
    let limit = query.limit.unwrap_or(10);
    let offset = query.offset.unwrap_or(0);
    let status = query.status.as_deref();

    // Base query
    let mut sql = String::from(
        r#"
        SELECT id, sender_id, recipient_id, amount, currency, status as "status: _", created_at, updated_at
        FROM transactions
        WHERE (sender_id = $1 OR recipient_id = $1)
        "#
    );
    
    // Add status filter if provided
    if let Some(status_str) = status {
        sql.push_str("AND status = $3 ");
    }
    
    // Add ordering and pagination
    sql.push_str("ORDER BY created_at DESC LIMIT $2 OFFSET $4");
    
    // Prepare and execute query based on whether status filter is present
    let transactions = if let Some(status_str) = status {
        // Convert status string to enum
        let status = match status_str.to_lowercase().as_str() {
            "pending" => TransactionStatus::Pending,
            "completed" => TransactionStatus::Completed,
            "failed" => TransactionStatus::Failed,
            _ => return Err(AppError::BadRequestError("Invalid status".to_string())),
        };
        
        sqlx::query_as!(
            Transaction,
            sql,
            user_id.into_inner(),
            limit as i64,
            status as _,
            offset as i64
        )
        .fetch_all(pool.get_ref())
        .await?
    } else {
        // Without status filter
        sqlx::query_as!(
            Transaction,
            r#"
            SELECT id, sender_id, recipient_id, amount, currency, status as "status: _", created_at, updated_at
            FROM transactions
            WHERE (sender_id = $1 OR recipient_id = $1)
            ORDER BY created_at DESC LIMIT $2 OFFSET $3
            "#,
            user_id.into_inner(),
            limit as i64,
            offset as i64
        )
        .fetch_all(pool.get_ref())
        .await?
    };
    
    // Count total transactions (without pagination)
    let count_sql = if let Some(status_str) = status {
        let status = match status_str.to_lowercase().as_str() {
            "pending" => TransactionStatus::Pending,
            "completed" => TransactionStatus::Completed,
            "failed" => TransactionStatus::Failed,
            _ => return Err(AppError::BadRequestError("Invalid status".to_string())),
        };
        
        sqlx::query_scalar!(
            r#"
            SELECT COUNT(*) as "count!"
            FROM transactions
            WHERE (sender_id = $1 OR recipient_id = $1) AND status = $2
            "#,
            user_id.into_inner(),
            status as _
        )
        .fetch_one(pool.get_ref())
        .await?
    } else {
        sqlx::query_scalar!(
            r#"
            SELECT COUNT(*) as "count!"
            FROM transactions
            WHERE (sender_id = $1 OR recipient_id = $1)
            "#,
            user_id.into_inner()
        )
        .fetch_one(pool.get_ref())
        .await?
    };
    
    let transaction_responses = transactions
        .into_iter()
        .map(TransactionResponse::from)
        .collect::<Vec<_>>();
    
    Ok(HttpResponse::Ok().json(TransactionListResponse {
        transactions: transaction_responses,
        total: count_sql as i64,
        page: (offset / limit) as i64,
        per_page: limit as i64,
    }))
}

#[derive(serde::Deserialize)]
pub struct ListTransactionsQuery {
    limit: Option<u32>,
    offset: Option<u32>,
    status: Option<String>,
}
