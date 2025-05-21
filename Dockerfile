# Dockerfile for Dodo Payments backend that uses SQLx compile-time macros
FROM rust:1.75 as builder

WORKDIR /app

# Install required dependencies
RUN apt-get update && apt-get install -y libpq-dev

# Copy SQLx data file for offline mode
COPY sqlx-data.json ./sqlx-data.json

# Copy Cargo configuration files
COPY Cargo.toml Cargo.lock ./

# Create dummy source layout for dependency caching
RUN mkdir -p src && \
    echo "fn main() { println!(\"Dummy build\"); }" > src/main.rs && \
    echo "pub fn dummy() {}" > src/lib.rs

# Build dependencies only - using offline mode
ENV SQLX_OFFLINE=true
RUN cargo build --release

# Remove dummy source files
RUN rm -rf src

# Copy actual source code
COPY src ./src/
COPY migrations ./migrations/

# Build the actual application with SQLx offline mode
RUN cargo build --release

# Create runtime image
FROM debian:bullseye-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y libpq5 ca-certificates tzdata curl && \
    rm -rf /var/lib/apt/lists/*

# Copy binary from builder
COPY --from=builder /app/target/release/dodo-payments /app/dodo-payments

# Copy migrations
COPY migrations /app/migrations

# Copy SQLx data file
COPY sqlx-data.json ./sqlx-data.json

# Set environment variables
ENV SERVER_ADDR=0.0.0.0:8080
ENV RUST_LOG=info
ENV SQLX_OFFLINE=true

# Expose port
EXPOSE 8080

# Run the application
CMD ["/app/dodo-payments"]
