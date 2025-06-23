# dots - Device Orchestration, Totally Simplified

This repository contains a comprehensive NixOS configuration with enhanced flake checks for code quality, security, and consistency.

## Enhanced Flake Checks

This repository implements comprehensive checks for flake robustness and quality. These checks can be run with:

```bash
# Run all checks
nix flake check

# Run specific check categories
nix build .#checks.x86_64-linux.format-check      # Format validation
nix build .#checks.x86_64-linux.deadnix-check     # Dead code detection
nix build .#checks.x86_64-linux.statix-check      # Nix linting
nix build .#checks.x86_64-linux.flake-check       # Flake evaluation
nix build .#checks.x86_64-linux.doc-validation    # Documentation validation
nix build .#checks.x86_64-linux.dependency-audit # Dependency auditing
nix build .#checks.x86_64-linux.build-consistency # Build consistency
nix build .#checks.x86_64-linux.security-check    # Security enhancements
nix build .#checks.x86_64-linux.gc-check          # Evaluation optimization
```

### Check Categories

#### 1. Dead Code Detection
- Uses `deadnix` to identify unused Nix code
- Integrated with treefmt for automatic detection

#### 2. Format and Lint Checks
- **nixfmt**: Nix code formatting
- **shellcheck**: Shell script linting
- **statix**: Advanced Nix linting
- **prettier**: General file formatting
- **taplo**: TOML formatting

#### 3. Dependency Auditing
- Validates flake.lock exists and is properly structured
- Checks input freshness and metadata
- Ensures all inputs are properly locked

#### 4. Build Consistency
- Validates that core system configurations build successfully
- Tests both main system and installer configurations
- Runs dry-run builds to catch issues early

#### 5. Documentation Validation
- Ensures README.md exists and has content
- Scans for TODO/FIXME comments that might indicate incomplete work
- Validates documentation completeness

#### 6. Security Enhancements
- Scans for potential hardcoded passwords or secrets
- Validates allowUnfree usage is intentional
- Detects usage of unsafe Nix functions
- Basic security hygiene checks

#### 7. Garbage Collection and Evaluation
- Verifies expressions can be properly evaluated
- Checks for circular dependencies
- Validates evaluation performance

#### 8. CI/CD Integration
All checks are designed to integrate with CI/CD pipelines and can be run in GitHub Actions or other CI systems.

## Development

To set up the development environment:

```bash
# Enter development shell with all tools
nix develop

# Format all files
nix fmt

# Run all checks
nix flake check
```
