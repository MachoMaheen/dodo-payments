# Production-optimized Dockerfile for Dodo Payments
FROM rust:slim as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y postgresql-client libpq-dev pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the Cargo.toml and Cargo.lock files first
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs file to build dependencies
RUN mkdir -p src && \
    echo "fn main() {println!(\"dummy\");}" > src/main.rs && \
    echo "pub fn dummy() {}" > src/lib.rs

# Build dependencies - this will be cached if dependencies don't change
RUN cargo build --release

# Delete the dummy files
RUN rm -rf src/

# Copy the real source code
COPY . .

# Build and run the JWT secret generator
RUN cargo build --release --bin generate_jwt_secret
RUN ./target/release/generate_jwt_secret

# Build the application in release mode
RUN cargo build --release

# Runtime stage - Use a smaller base image
FROM debian:bookworm-slim

WORKDIR /app

# Install only essential runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates libpq-dev postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Copy only the necessary files from the builder stage
COPY --from=builder /app/target/release/dodo-payments /app/dodo-payments
COPY --from=builder /app/migrations /app/migrations/
COPY --from=builder /app/jwt_secret.txt /app/jwt_secret.txt
COPY wait-for-db.sh /app/wait-for-db.sh
COPY init-db.sh /app/init-db.sh
COPY health-check.sh /app/health-check.sh

# Make scripts executable
RUN chmod +x /app/wait-for-db.sh /app/init-db.sh /app/health-check.sh

# Set environment variables
ENV RUST_LOG=info
ENV SERVER_ADDR=0.0.0.0:8080

# Expose the port
EXPOSE 8080

# Set the default command (will be overridden by docker-compose)
CMD ["/app/dodo-payments"]