# Capture Docker build logs for Dodo Payments

echo "=== Capturing Docker build logs for Dodo Payments ==="

LOG_FILE="docker_build_logs_$(date +%Y%m%d_%H%M%S).log"
echo "Logs will be saved to $LOG_FILE"

# Stop any running containers
echo "Stopping existing containers..." | tee -a "$LOG_FILE"
docker-compose down 2>&1 | tee -a "$LOG_FILE"

# Clean Docker builder cache
echo "Cleaning Docker builder cache..." | tee -a "$LOG_FILE"
docker builder prune -f 2>&1 | tee -a "$LOG_FILE"

# Build the Docker image with full output logging
echo "Building Docker image..." | tee -a "$LOG_FILE"
DOCKER_BUILDKIT=1 docker build . -t dodo-payments:latest --progress=plain 2>&1 | tee -a "$LOG_FILE"

echo "Starting services..." | tee -a "$LOG_FILE"
docker-compose up -d 2>&1 | tee -a "$LOG_FILE"

echo "Getting container logs..." | tee -a "$LOG_FILE"
docker-compose logs 2>&1 | tee -a "$LOG_FILE"

echo "Logs have been saved to $LOG_FILE"
