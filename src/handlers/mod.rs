pub mod user;
pub mod account;
pub mod transaction;
pub mod health;

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
                    // Public routes
                    .route("/register", web::post().to(user::register))
                    .route("/login", web::post().to(user::login))
                    // Protected routes
                    .service(
                        web::scope("/profile")
                            .wrap(Auth)
                            .route("", web::get().to(user::get_profile))
                            .route("", web::patch().to(user::update_profile))
                    )
            )
            // Account routes - all protected
            .service(
                web::scope("/accounts")
                    .wrap(Auth)
                    .route("/balance", web::get().to(account::get_balance))
            )
            // Transaction routes - all protected
            .service(
                web::scope("/transactions")
                    .wrap(Auth)
                    .route("", web::post().to(transaction::create_transaction))
                    .route("", web::get().to(transaction::list_transactions))
                    .route("/{transaction_id}", web::get().to(transaction::get_transaction))
            )
    );
}
