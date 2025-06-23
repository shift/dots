# Wallpaper Function Tests

This directory contains comprehensive tests for the `generatePieChartWallpaper` function in the repository.

## Overview

The tests validate the functionality of the wallpaper generation system, which combines multiple user wallpapers into a single "pie chart" wallpaper where each wallpaper occupies an equal angular slice of a circular output.

## Test Structure

### Core Test Files

- **`wallpaper-test.nix`** - Main Nix-based test suite containing:
  - `wallpaper-combiner-test` - Tests the pie-image-combiner script directly
  - `wallpaper-generator-test` - Tests wallpaper collection and generation logic
  - `wallpaper-integration-test` - End-to-end integration tests

- **`default.nix`** - Test runner that orchestrates all tests and provides a combined test suite

- **`test-wallpaper.sh`** - Standalone bash script for manual testing without Nix

## Test Scenarios

### 1. Basic Pie Chart Generation
- Tests combining multiple images into a pie chart
- Validates output format (PNG)
- Checks output dimensions
- Verifies file integrity

### 2. Single Image Handling
- Tests behavior with only one input image
- Ensures the image fills the entire circle

### 3. Default Dimensions
- Tests that default 1024x768 dimensions work correctly
- Validates dimension parsing and application

### 4. Error Handling
- Tests behavior with invalid image files
- Validates proper error messages and exit codes
- Ensures the script fails gracefully with bad input

### 5. User Environment Simulation
- Creates mock user directories with `.config/stylix/image` files
- Tests wallpaper collection from multiple users
- Simulates the real-world user configuration scenario

### 6. Fallback Mechanisms
- Tests behavior when no user wallpapers are found
- Validates fallback to default wallpaper
- Ensures system continues to work even with missing user configs

## Running Tests

### With Nix (Recommended)

```bash
# Run the complete test suite
nix build .#wallpaper-tests.wallpaper-test-suite

# Run individual test components
nix build .#wallpaper-tests.wallpaper-combiner-test
nix build .#wallpaper-tests.wallpaper-generator-test
nix build .#wallpaper-tests.wallpaper-integration-test
```

### Without Nix (Manual Testing)

```bash
# Run the standalone test script
./test-wallpaper.sh
```

This script will:
1. Install ImageMagick if not present (requires sudo)
2. Create temporary test images
3. Run all test scenarios
4. Clean up automatically

## Test Requirements

- **ImageMagick** - For image processing operations
- **file** command - For MIME type detection
- **bash** - For script execution

## Test Coverage

The tests ensure that the `generatePieChartWallpaper` function:

1. ✅ Successfully generates combined wallpaper images
2. ✅ Handles various input scenarios (single, multiple images)
3. ✅ Validates input files and provides appropriate error handling
4. ✅ Works with custom dimensions and default dimensions
5. ✅ Collects wallpapers from user configurations correctly
6. ✅ Falls back to default wallpapers when needed
7. ✅ Produces valid PNG output with correct dimensions
8. ✅ Handles edge cases gracefully

## Mock Data

The tests create mock data including:
- Colored test images (red, blue, green 100x100 PNG files)
- Mock user directory structures (`/home/squeals/.config/stylix/`)
- Invalid files for error testing
- Sample configuration scenarios

## Integration with Repository

The tests are integrated into the flake.nix as packages:

```nix
packages = {
  wallpaper-tests = import ./tests { inherit pkgs lib; };
};
```

This allows the tests to be run as part of the standard Nix workflow and ensures they're maintained alongside the code they test.

## Expected Outputs

Successful test runs will produce:
- Valid PNG files with specified dimensions
- Appropriate log messages indicating test progress
- Summary of all passed test cases
- Temporary files are cleaned up automatically

## Troubleshooting

### Common Issues

1. **ImageMagick not found** - Install ImageMagick using your system package manager
2. **Permission denied** - Ensure the test script is executable (`chmod +x test-wallpaper.sh`)
3. **Nix not available** - Use the standalone test script instead

### Test Failures

If tests fail, check:
1. ImageMagick is properly installed and functional
2. Sufficient disk space for temporary files
3. File permissions in the test directory
4. System has required dependencies (file, bash)

The tests are designed to be self-contained and should work on most Unix-like systems.