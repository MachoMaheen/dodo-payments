# Using Runtime Queries Instead of SQLx Macros

After analyzing the errors in our codebase, we've discovered several issues related to SQLx macros, BigDecimal serialization, and transaction handling. Here's how to fix them:

## The Main Issues

1. **BigDecimal Serialization**: BigDecimal needs the `serde` feature enabled to work properly with Serde and SQLx
2. **Transaction API Errors**: The `&mut tx` syntax doesn't work with SQLx 0.7.x (need to use `&mut *tx` or just `&tx`)
3. **SQLx Offline Mode**: Without a complete `sqlx-data.json`, compile-time macros fail
4. **Version Conflict**: We found a version conflict between `bigdecimal = "0.3.1"` and references to `bigdecimal = "0.4.8"`

## The Solution: Use Runtime Queries

The simplest way to get the application working is to switch from `sqlx::query!` macros to runtime query functions:

1. Replace `sqlx::query!` with `sqlx::query()`
2. Replace `sqlx::query_as!` with `sqlx::query_as()`
3. Use binding variables with `.bind()` instead of embedding them in the query

For example, change:

```rust
let user = sqlx::query_as!(
    User,
    r#"SELECT * FROM users WHERE id = $1"#,
    user_id
).fetch_one(pool).await?;
```

To:

```rust
let user = sqlx::query_as::<_, User>(
    "SELECT * FROM users WHERE id = $1"
)
.bind(user_id)
.fetch_one(pool).await?;
```

## Docker Configuration

Update the Docker configuration to use runtime queries:

1. Set `ENV SQLX_OFFLINE=false` in the Dockerfile
2. Set `SQLX_OFFLINE=false` in docker-compose.yml environment variables

## Transaction Handling

Update transaction handling to use the correct SQLx 0.7.x approach:

Instead of:

```rust
let mut tx = pool.begin().await?;
sqlx::query!("...").execute(&mut tx).await?;
tx.commit().await?;
```

Use:

```rust
let mut tx = pool.begin().await?;
sqlx::query("...").execute(&tx).await?; // Note: &tx not &mut tx
tx.commit().await?;
```

## Alternative Solution: Use i64 Instead of BigDecimal

If runtime queries don't solve all issues, consider converting monetary values to cents (i64) instead of using BigDecimal:

```rust
// In models
pub amount: i64, // Store cents instead of BigDecimal

// When inserting
let amount_cents = (amount_dollars * 100.0) as i64;

// When retrieving
let amount_dollars = amount_cents as f64 / 100.0;
```

## Fixed Model Structures

We've also updated the TransactionListResponse structure to include pagination fields:

```rust
pub struct TransactionListResponse {
    pub transactions: Vec<TransactionResponse>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}
```

This ensures consistency between both the original and fixed versions of the transaction handlers.

## Running the Application

To run the application with these changes:

1. Update the Docker config to use SQLX_OFFLINE=false
2. Run `bash setup-db-and-prepare.sh` to set up the database
3. Run `docker-compose up -d` to start the services

**Note**: This is a temporary solution to get the application running. A more robust solution would be to properly implement the serde features for BigDecimal, but this approach will work for now.
