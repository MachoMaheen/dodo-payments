//! Test suite for rate limiting functionality
//! These tests validate that the rate limiting middleware works as expected

use actix_web::{test, web, App, HttpResponse};
use actix_web::http::StatusCode;
use actix_extensible_rate_limit::{
    backend::SimpleInputFunctionBuilder,
    backend::memory::InMemoryBackend,
    RateLimiter,
};
use std::time::Duration;
use tokio::time::sleep;

// A simple handler for testing
async fn test_handler() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({"status": "success"}))
}

#[actix_web::test]
async fn test_rate_limiter_functionality() {    // Configure a strict rate limiter for testing (2 requests per minute)
    let input = SimpleInputFunctionBuilder::new(Duration::from_secs(60), 2)
        .key_extractor(|req| Some("test_key".to_string()))
        .build();
    let backend = InMemoryBackend::builder().build();
    let rate_limit = RateLimiter::builder(backend, input)
        .add_headers()
        .build();

    // Set up a test service with the rate limiter
    let app = test::init_service(
        App::new()
            .service(
                web::scope("/test")
                    .wrap(rate_limit.clone())
                    .route("", web::get().to(test_handler))
            )
    ).await;

    // First request should succeed
    let req1 = test::TestRequest::get().uri("/test").to_request();
    let resp1 = test::call_service(&app, req1).await;
    assert_eq!(resp1.status(), StatusCode::OK, "First request should succeed");

    // Second request should succeed
    let req2 = test::TestRequest::get().uri("/test").to_request();
    let resp2 = test::call_service(&app, req2).await;
    assert_eq!(resp2.status(), StatusCode::OK, "Second request should succeed");

    // Third request should be rate limited
    let req3 = test::TestRequest::get().uri("/test").to_request();
    let resp3 = test::call_service(&app, req3).await;
    assert_eq!(resp3.status(), StatusCode::TOO_MANY_REQUESTS, "Third request should be rate limited");

    // Check rate limit headers
    let headers = resp1.headers();
    assert!(headers.contains_key("x-ratelimit-limit"), "Response should include rate limit headers");
    assert!(headers.contains_key("x-ratelimit-remaining"), "Response should include rate limit remaining header");
    assert!(headers.contains_key("x-ratelimit-reset"), "Response should include rate limit reset header");
}

#[actix_web::test]
async fn test_rate_limiter_with_different_paths() {    // Configure a rate limiter (3 requests per minute)
    let input = SimpleInputFunctionBuilder::new(Duration::from_secs(60), 3)
        .key_extractor(|req| Some("test_key".to_string()))
        .build();
    let backend = InMemoryBackend::builder().build();
    let rate_limit = RateLimiter::builder(backend, input)
        .add_headers()
        .build();

    // Set up a test service with multiple endpoints under rate limiting
    let app = test::init_service(
        App::new()
            .service(
                web::scope("/api")
                    .wrap(rate_limit.clone())
                    .route("/endpoint1", web::get().to(test_handler))
                    .route("/endpoint2", web::get().to(test_handler))
            )
    ).await;

    // Make 3 requests to different endpoints (should all succeed)
    let req1 = test::TestRequest::get().uri("/api/endpoint1").to_request();
    let resp1 = test::call_service(&app, req1).await;
    assert_eq!(resp1.status(), StatusCode::OK, "First request should succeed");

    let req2 = test::TestRequest::get().uri("/api/endpoint2").to_request();
    let resp2 = test::call_service(&app, req2).await;
    assert_eq!(resp2.status(), StatusCode::OK, "Second request should succeed");

    let req3 = test::TestRequest::get().uri("/api/endpoint1").to_request();
    let resp3 = test::call_service(&app, req3).await;
    assert_eq!(resp3.status(), StatusCode::OK, "Third request should succeed");

    // Fourth request should be rate limited regardless of endpoint
    let req4 = test::TestRequest::get().uri("/api/endpoint2").to_request();
    let resp4 = test::call_service(&app, req4).await;
    assert_eq!(resp4.status(), StatusCode::TOO_MANY_REQUESTS, "Fourth request should be rate limited");
    
    // Check headers contain rate limit information
    let headers = resp3.headers();
    assert!(headers.contains_key("x-ratelimit-remaining"), "Response should include rate limit remaining header");
    
    // Check that the rate limit remaining was decremented
    if let Some(remaining) = headers.get("x-ratelimit-remaining") {
        let remaining_str = remaining.to_str().unwrap_or("invalid");
        assert_eq!(remaining_str, "0", "Last successful request should show 0 remaining requests");
    }
}

#[actix_web::test]
async fn test_rate_limiter_reset() {    // Configure a rate limiter with a very short window (2 seconds, 1 request)    // Using 2 seconds instead of 1 to give more buffer for timing issues
    let input = SimpleInputFunctionBuilder::new(Duration::from_secs(2), 1)
        .key_extractor(|req| Some("test_key".to_string()))
        .build();
    let backend = InMemoryBackend::builder().build();
    let rate_limit = RateLimiter::builder(backend, input)
        .add_headers()
        .build();

    // Set up test service
    let app = test::init_service(
        App::new()
            .service(
                web::scope("/reset-test")
                    .wrap(rate_limit.clone())
                    .route("", web::get().to(test_handler))
            )
    ).await;

    // First request should succeed
    let req1 = test::TestRequest::get().uri("/reset-test").to_request();
    let resp1 = test::call_service(&app, req1).await;
    assert_eq!(resp1.status(), StatusCode::OK, "First request should succeed");

    // Second request should be rate limited
    let req2 = test::TestRequest::get().uri("/reset-test").to_request();
    let resp2 = test::call_service(&app, req2).await;
    assert_eq!(resp2.status(), StatusCode::TOO_MANY_REQUESTS, "Second request should be rate limited");

    // Wait for the rate limiter to reset (slightly over 2 seconds)
    // Using tokio::time::sleep for async sleep
    tokio::time::sleep(Duration::from_millis(2200)).await;

    // Third request should succeed after reset
    let req3 = test::TestRequest::get().uri("/reset-test").to_request();
    let resp3 = test::call_service(&app, req3).await;
    assert_eq!(resp3.status(), StatusCode::OK, "Request after rate limit reset should succeed");
}
