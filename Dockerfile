# Simple Dockerfile for Dodo Payments
FROM rust:slim as builder

WORKDIR /app

# Install dependencies
RUN apt-get update && \
    apt-get install -y postgresql-client libpq-dev pkg-config libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the entire project
COPY . .

# Create jwt_secret.txt if not exists
RUN if [ ! -f jwt_secret.txt ]; then echo "dodo_payments_jwt_secret_key" > jwt_secret.txt; fi

# Build the application in release mode
RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary and needed files
COPY --from=builder /app/target/release/dodo-payments /app/dodo-payments
COPY --from=builder /app/migrations /app/migrations/
COPY --from=builder /app/jwt_secret.txt /app/jwt_secret.txt

# Set environment variables
ENV RUST_LOG=info
ENV SERVER_ADDR=0.0.0.0:8080

# Expose the port
EXPOSE 8080

# Run the application
CMD ["/app/dodo-payments"]
