pub mod user;
pub mod user_fixed;
pub mod transaction;
pub mod transaction_fixed;
pub mod account;
pub mod account_fixed;
pub mod health;

use actix_web::web;
use actix_extensible_rate_limit::{
    backend::SimpleInputFunctionBuilder,
    backend::memory::InMemoryBackend,
    RateLimiter,
};
use std::time::Duration;
use log::info;

use crate::middleware::Auth;

// Function to configure routes
pub fn config_routes(cfg: &mut web::ServiceConfig) {
    // Set up rate limiter
    let input = SimpleInputFunctionBuilder::new(Duration::from_secs(60), 100)
        .real_ip_key()
        .build();
    let backend = InMemoryBackend::builder().build();
    let rate_limit = RateLimiter::builder(backend, input)
        .add_headers()
        .build();

    // Health check - no auth required
    cfg.service(
        web::resource("/health")
            .route(web::get().to(health::health_check)),
    );

    // User routes
    cfg.service(
        web::scope("/users")
            .wrap(rate_limit.clone())
            .route("/register", web::post().to(user_fixed::register))
            .route("/login", web::post().to(user_fixed::login))
            .service(
                web::scope("")
                    .wrap(Auth)
                    .route("/profile", web::get().to(user_fixed::get_profile))
                    .route("/profile", web::put().to(user_fixed::update_profile)),
            ),
    );

    // Transaction routes
    cfg.service(
        web::scope("/transactions")
            .wrap(Auth)
            .wrap(rate_limit.clone())
            .route("", web::post().to(transaction_fixed::create_transaction))
            .route("", web::get().to(transaction_fixed::list_transactions))
            .route("/{id}", web::get().to(transaction_fixed::get_transaction)),
    );

    // Account routes
    cfg.service(
        web::scope("/accounts")
            .wrap(Auth)
            .route("/balance", web::get().to(account_fixed::get_balance)),
    );

    info!("Routes configured");
}
