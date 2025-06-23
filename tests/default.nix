# Test runner for wallpaper functionality
{
  pkgs,
  lib,
  ...
}:

let
  # Import our test suite
  wallpaperTests = import ./wallpaper-test.nix {
    inherit pkgs lib;
    config = {}; # Mock config for testing
  };

in
{
  # Create a combined test runner that runs all wallpaper tests
  wallpaper-test-suite = pkgs.runCommand "wallpaper-test-suite" {
    buildInputs = with pkgs; [ imagemagick file ];
  } ''
    set -euo pipefail
    
    echo "=== Running Wallpaper Test Suite ==="
    
    # Create results directory
    mkdir -p $out/test-results
    
    # Run each test and collect results
    echo "Running pie-image-combiner tests..."
    ${wallpaperTests.wallpaper-combiner-test} > $out/test-results/combiner-test.log 2>&1 || {
      echo "ERROR: Combiner test failed"
      cat $out/test-results/combiner-test.log
      exit 1
    }
    
    echo "Running wallpaper generator tests..."
    ${wallpaperTests.wallpaper-generator-test} > $out/test-results/generator-test.log 2>&1 || {
      echo "ERROR: Generator test failed"
      cat $out/test-results/generator-test.log
      exit 1
    }
    
    echo "Running integration tests..."
    ${wallpaperTests.wallpaper-integration-test} > $out/test-results/integration-test.log 2>&1 || {
      echo "ERROR: Integration test failed"
      cat $out/test-results/integration-test.log
      exit 1
    }
    
    echo "=== All Wallpaper Tests Passed! ==="
    echo "Test results saved to: $out/test-results/"
    
    # Create a summary
    echo "Test Summary:" > $out/test-summary.txt
    echo "✓ Pie Image Combiner Tests: PASSED" >> $out/test-summary.txt
    echo "✓ Wallpaper Generator Tests: PASSED" >> $out/test-summary.txt  
    echo "✓ Integration Tests: PASSED" >> $out/test-summary.txt
    echo "All tests completed successfully" >> $out/test-summary.txt
  '';
  
  # Export individual tests for granular testing
  inherit (wallpaperTests) 
    wallpaper-combiner-test
    wallpaper-generator-test
    wallpaper-integration-test;
}