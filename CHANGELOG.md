# Changelog

All notable changes to the Watson Orchestrate Proxy will be documented in this file.

## [1.2.0] - 2025-11-02

### Added
- Automatic instance ID injection for orchestrate endpoints
- Fixes "Instance ID mismatch" errors with Watson API

### Fixed
- Instance ID path routing for `/v1/orchestrate/*` endpoints
- Compatibility with new IBM Watson API requirements

## [1.1.0] - 2025-11-02  

### Added
- Rate limiting (100 requests per minute default)
- Retry logic with exponential backoff
- Token caching with intelligent refresh
- Health monitoring with detailed status
- Memory usage tracking
- Configurable environment variables for all settings
- Production-ready Docker support
- Comprehensive error handling

### Security
- Removed all hardcoded API keys
- Environment variable based configuration
- Added SECURITY_NOTICE.md documentation

### Changed
- Refactored token management for better reliability
- Improved logging with configurable levels

## [1.0.0] - 2025-11-01

### Added
- Initial proxy implementation
- JWT token authentication handling
- Basic request forwarding to Watson Orchestrate
- CORS support
- Health check endpoint
- Railway deployment configuration

### Features
- Bypass Tasklet.ai JWT validation issues
- Transparent authentication proxy
- Support for all Watson Orchestrate endpoints
