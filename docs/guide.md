# Development Guide

## Code Style Guidelines
- **Imports**: Group standard library, third-party, and local imports with a blank line between groups
- **Formatting**: Use Ruff with 88 character line length
- **Types**: Use type annotations everywhere; import types from typing module
- **Naming**: Use snake_case for variables/functions, PascalCase for classes, UPPER_CASE for constants
- **Error Handling**: Use specific exceptions with meaningful error messages
- **Documentation**: Use docstrings for all public functions, classes, and methods
- **Logging**: Use the structured logging module; avoid print statements
- **Async**: Use async/await for non-blocking operations, especially in FastAPI endpoints
- **Configuration**: Use environment variables with YAML for configuration
- **Requirements**: Use the most up-to-date versions of dependencies unless specifically instructed not to
