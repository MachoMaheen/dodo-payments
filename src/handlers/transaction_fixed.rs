use actix_web::{web, HttpResponse, Responder};
use sqlx::{PgPool, Row}; // Import Row trait explicitly for try_get method
use uuid::Uuid;
use validator::Validate;
use bigdecimal::BigDecimal;
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
    let recipient_exists = sqlx::query("SELECT id FROM users WHERE id = $1")
        .bind(recipient_id)
        .fetch_optional(pool.get_ref())
        .await?
        .is_some();
    
    if !recipient_exists {
        return Err(AppError::NotFoundError("Recipient not found".to_string()));
    }
    
    // Begin transaction
    let mut tx = pool.begin().await?;
    
    // Convert f64 to BigDecimal
    let amount_decimal = BigDecimal::from_str(&transaction_data.amount.to_string())
        .map_err(|_| AppError::BadRequestError("Invalid amount".to_string()))?;

    // Check sender balance
    let sender_account = sqlx::query(
        r#"
        SELECT balance, currency FROM accounts
        WHERE user_id = $1
        FOR UPDATE
        "#
    )
    .bind(sender_id)
    .fetch_one(&mut *tx)
    .await?;
    
    let balance: BigDecimal = sender_account.try_get("balance")?;
    let currency: String = sender_account.try_get("currency")?;
    
    // Ensure sender has enough funds
    if balance < amount_decimal {
        return Err(AppError::BadRequestError("Insufficient funds".to_string()));
    }
    
    // Ensure currency matches
    if currency != transaction_data.currency {
        return Err(AppError::BadRequestError(format!(
            "Currency mismatch: account is in {}, transaction is in {}",
            currency, transaction_data.currency
        )));
    }
    
    // Create transaction record
    let transaction_id = sqlx::query(
        r#"
        INSERT INTO transactions (sender_id, recipient_id, amount, currency, status)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
        "#
    )
    .bind(sender_id)
    .bind(recipient_id)
    .bind(&amount_decimal)
    .bind(&transaction_data.currency)
    .bind(TransactionStatus::Pending as i32)
    .fetch_one(&mut *tx)
    .await?
    .try_get::<Uuid, _>("id")?;
    
    // Update sender's balance
    sqlx::query(
        r#"
        UPDATE accounts
        SET balance = balance - $1, updated_at = NOW()
        WHERE user_id = $2
        "#
    )
    .bind(&amount_decimal)
    .bind(sender_id)
    .execute(&mut *tx)
    .await?;
    
    // Update recipient's balance
    sqlx::query(
        r#"
        UPDATE accounts
        SET balance = balance + $1, updated_at = NOW()
        WHERE user_id = $2
        "#
    )
    .bind(&amount_decimal)
    .bind(recipient_id)
    .execute(&mut *tx)
    .await?;
    
    // Mark transaction as completed
    let completed_transaction = sqlx::query(
        r#"
        UPDATE transactions
        SET status = $1, updated_at = NOW()
        WHERE id = $2
        RETURNING id, sender_id, recipient_id, amount, currency, status, created_at, updated_at
        "#
    )
    .bind(TransactionStatus::Completed as i32)
    .bind(transaction_id)
    .fetch_one(&mut *tx)
    .await?;

    // Extract data from the row
    let transaction = Transaction {
        id: completed_transaction.try_get("id")?,
        sender_id: completed_transaction.try_get("sender_id")?,
        recipient_id: completed_transaction.try_get("recipient_id")?,
        amount: completed_transaction.try_get("amount")?,
        currency: completed_transaction.try_get("currency")?,
        status: TransactionStatus::Completed, // We know it's completed because we just set it
        created_at: completed_transaction.try_get("created_at")?,
        updated_at: completed_transaction.try_get("updated_at")?,
    };
    
    // Commit transaction
    tx.commit().await?;
    
    Ok(HttpResponse::Created().json(TransactionResponse::from(transaction)))
}

pub async fn get_transaction(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    transaction_id: web::Path<Uuid>,
) -> Result<impl Responder, AppError> {
    let user_id = user_id.into_inner();
    let transaction_id = transaction_id.into_inner();
    
    let row = sqlx::query(
        r#"
        SELECT id, sender_id, recipient_id, amount, currency, status, created_at, updated_at
        FROM transactions
        WHERE id = $1 AND (sender_id = $2 OR recipient_id = $2)
        "#
    )
    .bind(transaction_id)
    .bind(user_id)
    .fetch_optional(pool.get_ref())
    .await?
    .ok_or_else(|| AppError::NotFoundError("Transaction not found".to_string()))?;
    
    let transaction = Transaction {
        id: row.try_get("id")?,
        sender_id: row.try_get("sender_id")?,
        recipient_id: row.try_get("recipient_id")?,
        amount: row.try_get("amount")?,
        currency: row.try_get("currency")?,
        status: match row.try_get::<i32, _>("status")? {
            0 => TransactionStatus::Pending,
            1 => TransactionStatus::Completed,
            2 => TransactionStatus::Failed,
            _ => TransactionStatus::Pending, // Default case
        },
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    };
    
    Ok(HttpResponse::Ok().json(TransactionResponse::from(transaction)))
}

pub async fn list_transactions(
    user_id: web::ReqData<Uuid>,
    pool: web::Data<PgPool>,
    query: web::Query<ListTransactionsQuery>,
) -> Result<impl Responder, AppError> {
    let user_id = user_id.into_inner();
    let limit = query.limit.unwrap_or(10);
    let offset = query.offset.unwrap_or(0);
    
    let mut sql = String::from(
        r#"
        SELECT id, sender_id, recipient_id, amount, currency, status, created_at, updated_at
        FROM transactions
        WHERE (sender_id = $1 OR recipient_id = $1)
        "#
    );
    
    // Add status filter if provided
    let mut params = vec![user_id.to_string()];
    let mut param_index = 2;
    
    if let Some(status_str) = &query.status {
        let status_num = match status_str.to_lowercase().as_str() {
            "pending" => 0,
            "completed" => 1,
            "failed" => 2,
            _ => return Err(AppError::BadRequestError("Invalid status".to_string())),
        };
        sql.push_str(&format!("AND status = ${} ", param_index));
        params.push(status_num.to_string());
        param_index += 1;
    }
    
    // Add ordering and pagination
    sql.push_str(&format!("ORDER BY created_at DESC LIMIT ${} OFFSET ${}", param_index, param_index + 1));
    params.push(limit.to_string());
    params.push(offset.to_string());
    
    // Build and execute the dynamic query
    let mut query_builder = sqlx::query(&sql);
    for param in params {
        query_builder = query_builder.bind(param);
    }
    
    let rows = query_builder
        .fetch_all(pool.get_ref())
        .await?;
    
    // Map rows to Transaction objects
    let mut transactions = Vec::with_capacity(rows.len());
    for row in rows {
        let transaction = Transaction {
            id: row.try_get("id")?,
            sender_id: row.try_get("sender_id")?,
            recipient_id: row.try_get("recipient_id")?,
            amount: row.try_get("amount")?,
            currency: row.try_get("currency")?,
            status: match row.try_get::<i32, _>("status")? {
                0 => TransactionStatus::Pending,
                1 => TransactionStatus::Completed,
                2 => TransactionStatus::Failed,
                _ => TransactionStatus::Pending,
            },
            created_at: row.try_get("created_at")?,
            updated_at: row.try_get("updated_at")?,
        };
        transactions.push(transaction);
    }
    
    // Count total transactions
    let mut count_sql = String::from(
        r#"
        SELECT COUNT(*) as count
        FROM transactions
        WHERE (sender_id = $1 OR recipient_id = $1)
        "#
    );
    
    if let Some(status_str) = &query.status {
        let status_num = match status_str.to_lowercase().as_str() {
            "pending" => 0,
            "completed" => 1,
            "failed" => 2,
            _ => return Err(AppError::BadRequestError("Invalid status".to_string())),
        };
        count_sql.push_str("AND status = $2");
        
        let count: i64 = sqlx::query(&count_sql)
            .bind(user_id)
            .bind(status_num)
            .fetch_one(pool.get_ref())
            .await?
            .try_get("count")?;
            
        let transaction_responses = transactions
            .into_iter()
            .map(TransactionResponse::from)
            .collect::<Vec<_>>();
        
        Ok(HttpResponse::Ok().json(TransactionListResponse {
            transactions: transaction_responses,
            total: count as i64,
            page: (offset / limit) as i64,
            per_page: limit as i64,
        }))
    } else {
        let count: i64 = sqlx::query(&count_sql)
            .bind(user_id)
            .fetch_one(pool.get_ref())
            .await?
            .try_get("count")?;
            
        let transaction_responses = transactions
            .into_iter()
            .map(TransactionResponse::from)
            .collect::<Vec<_>>();
        
        Ok(HttpResponse::Ok().json(TransactionListResponse {
            transactions: transaction_responses,
            total: count as i64,
            page: (offset / limit) as i64,
            per_page: limit as i64,
        }))
    }
}

#[derive(serde::Deserialize)]
pub struct ListTransactionsQuery {
    limit: Option<u32>,
    offset: Option<u32>,
    status: Option<String>,
}
