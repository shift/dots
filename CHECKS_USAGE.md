# Enhanced Flake Checks Usage Examples

This document provides practical examples of using the enhanced flake checks.

## Quick Start

```bash
# Run all checks
nix flake check

# Run formatting and fix issues
nix fmt

# Run specific individual checks
nix build .#checks.x86_64-linux.deadnix-check
nix build .#checks.x86_64-linux.security-check
```

## Check Categories and Use Cases

### 1. Development Workflow
```bash
# Before committing changes
nix fmt                                        # Fix formatting
nix build .#checks.x86_64-linux.format-check  # Verify formatting
nix build .#checks.x86_64-linux.deadnix-check # Remove dead code
nix build .#checks.x86_64-linux.statix-check  # Fix linting issues
```

### 2. Pre-deployment Validation
```bash
# Ensure system builds correctly
nix build .#checks.x86_64-linux.build-consistency

# Validate flake structure
nix build .#checks.x86_64-linux.flake-check

# Check dependencies are up to date
nix build .#checks.x86_64-linux.dependency-audit
```

### 3. Security Review
```bash
# Run security audit
nix build .#checks.x86_64-linux.security-check

# Check for potential issues
nix build .#checks.x86_64-linux.doc-validation
```

### 4. Performance and Cleanup
```bash
# Validate evaluation performance
nix build .#checks.x86_64-linux.gc-check

# Remove unused code
nix build .#checks.x86_64-linux.deadnix-check
```

## CI/CD Integration

### GitHub Actions
Copy the contents of `/tmp/enhanced-flake-checks.yml` to `.github/workflows/` to enable automated checks on every PR and push.

### Local Pre-commit Hook
```bash
# .git/hooks/pre-commit
#!/bin/bash
nix fmt
nix build .#checks.x86_64-linux.format-check
nix build .#checks.x86_64-linux.deadnix-check
nix build .#checks.x86_64-linux.security-check
```

## Troubleshooting

### Common Issues

1. **Format check fails**: Run `nix fmt` to fix formatting issues
2. **Dead code detected**: Review and remove unused code identified by deadnix
3. **Security warnings**: Address hardcoded values or unsafe function usage
4. **Build consistency fails**: Check that system configurations are valid
5. **Flake check fails**: Ensure flake.nix syntax and structure is correct

### Debug Mode
```bash
# Run checks with more verbose output
nix build .#checks.x86_64-linux.security-check --print-build-logs
```

## Customization

The checks can be customized by modifying the `checks` section in `flake.nix`. Each check is a standard Nix derivation that can be extended or modified as needed.

### Adding Custom Checks
```nix
# In flake.nix perSystem.checks
custom-check = pkgs.runCommand "custom-check" 
  { buildInputs = [ pkgs.some-tool ]; } ''
    # Your custom validation logic
    touch $out
  '';
```