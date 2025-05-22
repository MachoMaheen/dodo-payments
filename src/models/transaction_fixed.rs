use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};
use uuid::Uuid;
use validator::Validate;
use bigdecimal::BigDecimal;
use std::str::FromStr;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Transaction {
    pub id: Uuid,
    pub sender_id: Uuid,
    pub recipient_id: Uuid,
    pub amount: BigDecimal,
    pub currency: String,
    pub description: Option<String>,
    pub status: TransactionStatus,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "transaction_status", rename_all = "lowercase")]
pub enum TransactionStatus {
    Pending,
    Completed,
    Failed,
}

#[derive(Debug, Serialize, Deserialize, Validate)]
pub struct CreateTransactionRequest {
    pub recipient_id: Uuid,
    
    #[validate(range(min = 0.01, message = "amount must be greater than 0"))]
    pub amount: f64,
    
    #[validate(length(min = 3, max = 3, message = "currency must be a 3-letter code"))]
    pub currency: String,
    
    #[validate(length(max = 200, message = "description must be less than 200 characters"))]
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TransactionResponse {
    pub id: Uuid,
    pub sender_id: Uuid,
    pub recipient_id: Uuid,
    pub amount: f64,
    pub currency: String,
    pub description: Option<String>,
    pub status: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TransactionListResponse {
    pub transactions: Vec<TransactionResponse>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}

impl From<Transaction> for TransactionResponse {
    fn from(transaction: Transaction) -> Self {
        // Safely convert BigDecimal to f64
        let amount_f64 = transaction.amount.to_string().parse::<f64>().unwrap_or(0.0);
        
        Self {
            id: transaction.id,
            sender_id: transaction.sender_id,
            recipient_id: transaction.recipient_id,
            amount: amount_f64,
            currency: transaction.currency,
            description: transaction.description,
            status: format!("{:?}", transaction.status).to_lowercase(),
            created_at: transaction.created_at,
        }
    }
}

// Helper function to convert f64 to BigDecimal
pub fn f64_to_bigdecimal(value: f64) -> Result<BigDecimal, String> {
    BigDecimal::from_str(&value.to_string())
        .map_err(|e| format!("Failed to convert to BigDecimal: {}", e))
}
