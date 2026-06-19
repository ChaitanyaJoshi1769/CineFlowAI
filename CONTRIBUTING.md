# Contributing to CineFlow AI

Thank you for your interest in contributing to CineFlow AI! We welcome contributions from the community.

## Code of Conduct

Please be respectful and constructive in all interactions. We're committed to providing a welcoming and inspiring community for all.

## Getting Started

### Prerequisites

- **Docker & Docker Compose** - For running infrastructure
- **Node.js 18+** - For frontend development
- **Rust 1.70+** - For backend services
- **Python 3.11+** - For AI services
- **PostgreSQL 15** client tools
- **Git** - For version control

### Development Setup

```bash
# Clone the repository
git clone https://github.com/ChaitanyaJoshi1769/CineFlowAI.git
cd CineFlowAI

# Run the installation script
chmod +x scripts/setup/install-all.sh
./scripts/setup/install-all.sh

# Start backend services
./scripts/setup/start-backend.sh

# In another terminal, start frontend
cd frontend
npm run dev
```

Visit http://localhost:3000 to see the application.

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Follow the existing code style
- Write tests for new functionality
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run tests
npm test                    # Frontend
cargo test --all            # Backend (Rust)
pytest tests/               # Backend (Python)

# Run linting
npm run lint                # Frontend
cargo fmt --all             # Format Rust
black backend/              # Format Python
flake8 backend/             # Lint Python
```

### 4. Commit Your Changes

```bash
git add .
git commit -m "feat: brief description of changes"
```

Follow the conventional commits format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `test:` for tests
- `chore:` for maintenance
- `refactor:` for code refactoring

### 5. Push and Create a Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a PR on GitHub with a clear description of your changes.

## Code Style Guidelines

### Rust

- Run `cargo fmt` before committing
- Run `cargo clippy` to check for common mistakes
- Use meaningful variable names
- Write documentation comments for public APIs

### Python

- Follow PEP 8
- Run `black` for formatting
- Use type hints
- Add docstrings to functions

### TypeScript/JavaScript

- Use Prettier for formatting
- Use ESLint for linting
- Follow the existing component structure
- Use TypeScript for all new code

### Database

- Always create migration files for schema changes
- Use descriptive names for migrations
- Add rollback procedures
- Test migrations on a local copy first

## Pull Request Process

1. **Update README** if needed
2. **Update documentation** for API changes
3. **Add tests** for new functionality
4. **Run full test suite** locally
5. **Request review** from maintainers
6. **Address feedback** promptly

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] New tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or clearly noted)
- [ ] Commits are descriptive

## Testing

### Writing Tests

```rust
// Rust example
#[tokio::test]
async fn test_feature() {
    // Arrange
    let setup = test_setup().await;
    
    // Act
    let result = do_something(&setup).await;
    
    // Assert
    assert_eq!(result, expected);
}
```

```python
# Python example
@pytest.mark.asyncio
async def test_feature():
    # Arrange
    setup = await async_test_setup()
    
    # Act
    result = await do_something(setup)
    
    # Assert
    assert result == expected
```

### Test Coverage

- Aim for >80% code coverage
- Test happy paths and error cases
- Use fixtures for common setup

## Documentation

### Code Documentation

- Write clear docstrings/comments
- Explain the "why" not just the "what"
- Include examples for complex functions

### API Documentation

Update OpenAPI specs and GraphQL schema when making API changes.

### Architecture Documentation

Major architectural changes should be documented in `/docs/architecture/`.

## Reporting Issues

### Bug Reports

Include:
- Clear description of the issue
- Steps to reproduce
- Expected behavior
- Actual behavior
- Environment details (OS, version, etc.)

### Feature Requests

Include:
- Clear description of the feature
- Motivation and use cases
- Possible implementation approach (optional)
- Any concerns or blockers

## Performance Considerations

- Consider scalability in design
- Profile code before optimizing
- Document performance decisions
- Test with realistic data sizes

## Security

- Don't commit secrets or credentials
- Use `git-secrets` hook to prevent this
- Report security issues privately to security@cineflow.ai
- Follow OWASP guidelines for web security

## Build & Deployment

### Local Build

```bash
# Full build
npm run build                       # Frontend
cargo build --release --all         # Rust services
docker build -t cineflow:dev .      # Docker image
```

### CI/CD

- GitHub Actions runs automatically on PR
- Must pass all checks before merging
- Staging deploys from `develop` branch
- Production deploys from `main` branch

## Documentation Files

- `/docs` - Architecture and design documents
- `/README.md` - Project overview
- `/CONTRIBUTING.md` - This file
- Service-level READMEs in each service directory

## Getting Help

- **Questions?** Open a discussion on GitHub
- **Documentation?** Check `/docs` directory
- **Still stuck?** Ask on our Discord community
- **Security concern?** Email security@cineflow.ai

## License

By contributing to CineFlow AI, you agree that your contributions will be licensed under the Apache 2.0 License.

## Recognition

Contributors will be recognized in:
- `CONTRIBUTORS.md` file
- Release notes
- Project website

Thank you for contributing to CineFlow AI! 🎬🤖
