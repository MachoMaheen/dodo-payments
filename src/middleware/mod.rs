pub mod auth;
pub mod auth_fixed;

// Use the fixed auth middleware by default
pub use auth_fixed::Auth;

// Other modules should import Auth directly from middleware module
