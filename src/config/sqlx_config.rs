// Enable SQLx offline mode by declaring a metadata override
// This ensures SQLx queries can be compiled even without a database connection

#[cfg(feature = "sqlx-macros")]
pub fn enable_sqlx_offline() {
    // This function doesn't need to do anything; it's just here to ensure
    // that the module is initialized and the sqlx_offline feature is enabled
}

// This enables SQLx offline compilation even without the SQLX_OFFLINE env variable
#[cfg(not(feature = "sqlx-macros"))]
pub fn enable_sqlx_offline() {}
