use chrono::{DateTime, Utc};
use serde::{Serialize, Deserialize};
use uuid::Uuid;
use bigdecimal::BigDecimal;
use std::str::FromStr;

#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Account {
    pub id: Uuid,
    pub user_id: Uuid,
    pub balance: BigDecimal,
    pub currency: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AccountBalanceResponse {
    pub balance: f64,
    pub currency: String,
}

impl From<Account> for AccountBalanceResponse {
    fn from(account: Account) -> Self {
        // Convert BigDecimal to f64 for JSON serialization - safely parse the string value
        let balance_f64 = account.balance.to_string().parse::<f64>().unwrap_or(0.0);
        
        Self {
            balance: balance_f64,
            currency: account.currency,
        }
    }
}

// Helper function to convert f64 to BigDecimal
pub fn f64_to_bigdecimal(value: f64) -> Result<BigDecimal, String> {
    BigDecimal::from_str(&value.to_string())
        .map_err(|e| format!("Failed to convert to BigDecimal: {}", e))
}
