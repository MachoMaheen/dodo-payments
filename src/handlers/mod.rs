pub mod user;
pub mod account;
pub mod transaction;
pub mod health;

use actix_web::web;

// Configure routes
pub fn config_routes(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/api")
            .service(
                web::scope("/users")
                    .route("/register", web::post().to(user::register))
                    .route("/login", web::post().to(user::login))
                    .route("/profile", web::get().to(user::get_profile))
                    .route("/profile", web::patch().to(user::update_profile))
            )
            .service(
                web::scope("/accounts")
                    .route("/balance", web::get().to(account::get_balance))
            )
            .service(
                web::scope("/transactions")
                    .route("", web::post().to(transaction::create_transaction))
                    .route("", web::get().to(transaction::list_transactions))
                    .route("/{transaction_id}", web::get().to(transaction::get_transaction))
            )
    )
    .route("/health", web::get().to(health::health_check));
}
