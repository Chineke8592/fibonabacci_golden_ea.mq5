# Project Structure

## Directory Organization
```
/
├── .kiro/                 # Kiro configuration and steering rules
│   └── steering/          # AI assistant guidance documents
├── src/                   # Source code (TBD - adjust based on chosen tech)
├── tests/                 # Test files
├── docs/                  # Documentation
├── config/                # Configuration files
└── scripts/               # Build and utility scripts
```

## File Naming Conventions
- Use kebab-case for directories and files where appropriate
- Follow language-specific conventions for source files
- Use descriptive names that clearly indicate purpose
- Avoid abbreviations unless they are widely understood

## Code Organization Patterns
- Separate concerns into logical modules/packages
- Keep related functionality together
- Maintain clear separation between business logic and infrastructure
- Follow established architectural patterns for chosen technology

## Configuration Management
- Environment-specific configurations in separate files
- Use environment variables for sensitive data
- Document all configuration options
- Provide sensible defaults

## Documentation Structure
- README.md in root with project overview and setup instructions
- API documentation alongside code
- Architecture decisions recorded in docs/
- Inline code comments for complex logic

## Import/Module Guidelines
- Use absolute imports where possible
- Group imports logically (external, internal, relative)
- Avoid circular dependencies
- Keep dependency graphs shallow and clear