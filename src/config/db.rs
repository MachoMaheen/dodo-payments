use log::info;
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;

pub async fn init_database(pool: &PgPool) -> Result<(), sqlx::Error> {
    info!("Initializing database");

    // This is just a simple check to verify connection
    // Actual schema will be managed through migrations
    let row: (i64,) = sqlx::query_as("SELECT 1")
        .fetch_one(pool)
        .await?;

    info!("Database connection verified");
    Ok(())
}

pub async fn setup_database_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    info!("Setting up database connection pool");
    
    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await?;
    
    info!("Database pool created");
    Ok(pool)
}
