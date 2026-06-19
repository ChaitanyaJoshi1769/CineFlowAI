#!/bin/bash
set -e

echo "=========================================="
echo "CineFlow AI - Complete Installation"
echo "=========================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    log_info "✓ Docker found"

    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    log_info "✓ Docker Compose found"

    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    log_info "✓ Node.js found: $(node --version)"

    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo is not installed"
        exit 1
    fi
    log_info "✓ Rust found: $(cargo --version)"

    if ! command -v python3 &> /dev/null; then
        log_error "Python 3 is not installed"
        exit 1
    fi
    log_info "✓ Python found: $(python3 --version)"

    if ! command -v pip &> /dev/null; then
        log_error "pip is not installed"
        exit 1
    fi
    log_info "✓ pip found"

    echo ""
}

# Setup environment
setup_environment() {
    log_info "Setting up environment variables..."

    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        log_info "Created .env from template - please edit with your settings"
    fi
    echo ""
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."

    # Frontend
    log_info "Installing frontend dependencies..."
    cd "$PROJECT_ROOT/frontend"
    npm install
    log_info "✓ Frontend dependencies installed"

    # Backend - API Gateway
    log_info "Installing API Gateway dependencies..."
    cd "$PROJECT_ROOT/backend/services/api-gateway"
    cargo fetch
    log_info "✓ API Gateway dependencies fetched"

    # Backend - Python services
    for service_dir in "$PROJECT_ROOT/backend/services"/*/; do
        if [ -f "$service_dir/requirements.txt" ]; then
            service_name=$(basename "$service_dir")
            log_info "Installing $service_name dependencies..."
            pip install --upgrade pip setuptools wheel > /dev/null
            pip install -r "$service_dir/requirements.txt" > /dev/null
            log_info "✓ $service_name dependencies installed"
        fi
    done

    echo ""
}

# Setup databases
setup_databases() {
    log_info "Setting up databases..."

    cd "$PROJECT_ROOT/backend"

    # Start infrastructure
    log_info "Starting infrastructure containers..."
    docker-compose up -d postgres redis neo4j qdrant elasticsearch

    # Wait for services to be ready
    log_info "Waiting for services to be ready..."
    sleep 10

    # Apply migrations
    log_info "Running database migrations..."
    PGPASSWORD=cineflow_dev psql -h localhost -U cineflow -d cineflow_db -f "$PROJECT_ROOT/database/schemas/01-core.sql"
    PGPASSWORD=cineflow_dev psql -h localhost -U cineflow -d cineflow_db -f "$PROJECT_ROOT/database/schemas/02-memory-assets.sql"

    log_info "✓ Databases initialized"
    echo ""
}

# Build services
build_services() {
    log_info "Building services..."

    cd "$PROJECT_ROOT"

    # Build frontend
    log_info "Building frontend..."
    cd "$PROJECT_ROOT/frontend"
    npm run build
    log_info "✓ Frontend built"

    echo ""
}

# Generate code
generate_code() {
    log_info "Generating code from specifications..."

    # Generate protobuf code
    if command -v protoc &> /dev/null; then
        log_info "Generating protobuf code..."
        protoc --rust_out="$PROJECT_ROOT/backend/shared/" "$PROJECT_ROOT/backend/shared/protos/*.proto"
        log_info "✓ Protobuf code generated"
    else
        log_warn "protoc not found - skipping protobuf generation"
    fi

    echo ""
}

# Create symlinks
create_symlinks() {
    log_info "Creating development symlinks..."

    # Link .env files
    for service_dir in "$PROJECT_ROOT/backend/services"/*/; do
        ln -sf "$PROJECT_ROOT/.env" "$service_dir/.env" 2>/dev/null || true
    done

    log_info "✓ Symlinks created"
    echo ""
}

# Summary
print_summary() {
    echo "=========================================="
    echo -e "${GREEN}Installation Complete!${NC}"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "1. Edit .env with your configuration"
    echo "2. Start development: ./scripts/setup/start-backend.sh"
    echo "3. Frontend: cd frontend && npm run dev"
    echo "4. Visit http://localhost:3000"
    echo ""
    echo "Useful commands:"
    echo "  docker-compose logs -f              # View logs"
    echo "  docker-compose ps                   # View services"
    echo "  docker-compose down                 # Stop all services"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    setup_environment
    install_dependencies
    setup_databases
    build_services
    generate_code
    create_symlinks
    print_summary
}

main "$@"
