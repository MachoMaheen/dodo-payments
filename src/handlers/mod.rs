pub mod user;
pub mod account;
pub mod transaction;
pub mod health;
pub mod admin;

use actix_web::web;
use crate::middleware::Auth;

// Configure routes
pub fn config_routes(cfg: &mut web::ServiceConfig) {
    // Health check route - no auth required
    cfg.route("/health", web::get().to(health::health_check));
    
    // API routes with authentication where needed
    cfg.service(
        web::scope("/api")
            // User routes
            .service(
                web::scope("/users")
                    .route("/register", web::post().to(user::register))
                    .route("/login", web::post().to(user::login))
                    .service(
                        web::scope("/profile")
                            .wrap(Auth)
                            .route("", web::get().to(user::get_profile))
                            .route("", web::patch().to(user::update_profile))
                    )
            )
            // Account routes
            .service(
                web::scope("/accounts")
                    .wrap(Auth)
                    .route("/balance", web::get().to(account::get_balance))
            )
            // Transaction routes
            .service(
                web::scope("/transactions")
                    .wrap(Auth)
                    .route("", web::post().to(transaction::create_transaction))
                    .route("", web::get().to(transaction::list_transactions))
                    .route("/{transaction_id}", web::get().to(transaction::get_transaction))
            )
    );

    // Admin routes
    cfg.service(
        web::scope("/admin")
            .route("/fund/{user_id}", web::post().to(admin::fund_user_balance))
    );
}