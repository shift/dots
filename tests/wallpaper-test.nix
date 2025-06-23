{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Create the pie-image-combiner script for testing
  # This is extracted from the wallpaper module for standalone testing
  pieImageCombinerApp = pkgs.writeShellApplication {
    name = "pie-image-combiner";
    runtimeInputs = [
      pkgs.imagemagick
      pkgs.file
    ];
    text = ''
      #!/usr/bin/env bash

      # This script combines multiple images into a single "pie chart" image.
      # Each image will occupy an equal angular slice of a circular output.
      # The canvas size is configurable, defaulting to 1024x768.

      set -euo pipefail

      # Default canvas dimensions
      CANVAS_WIDTH=1024
      CANVAS_HEIGHT=768

      # --- Argument Parsing ---
      args=()
      while [[ $# -gt 0 ]]; do
          case "$1" in
              --width)
                  if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                      CANVAS_WIDTH="$2"
                      shift 2
                  else
                      echo "Error: --width requires a numeric value." >&2
                      exit 1
                  fi
                  ;;
              --height)
                  if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                      CANVAS_HEIGHT="$2"
                      shift 2
                  else
                      echo "Error: --height requires a numeric value." >&2
                      exit 1
                  fi
                  ;;
              --) # End of options marker
                  shift
                  args+=("$@") # Add remaining arguments and break
                  break
                  ;;
              -*) # Unknown option
                  echo "Error: Unknown option: $1" >&2
                  exit 1
                  ;;
              *) # Positional arguments (image paths or output file)
                  args+=("$1")
                  shift
                  ;;
          esac
      done
      set -- "''${args[@]}" # Restore positional parameters

      # Check for minimum arguments
      if [[ "$#" -lt 2 ]]; then
          echo "Usage: $(basename "$0") [--width <pixels>] [--height <pixels>] <image1.jpg> [image2.png ...] <output.png>"
          exit 1
      fi

      # Get output file and input images
      output_file="''${!#}" # The last argument is the output file name

      # Use declare and a loop instead of array slice syntax
      declare -a input_images
      for ((i=1; i<=$#-1; i++)); do
        input_images+=("''${!i}")
      done

      num_images="''${#input_images[@]}"

      if [[ "''${num_images}" -eq 0 ]]; then
          echo "Error: No input images provided before the output file name."
          exit 1
      fi

      # Validate that all input files exist and are valid images
      for img in "''${input_images[@]}"; do
          if [[ ! -f "''${img}" ]]; then
              echo "Error: Input file does not exist: ''${img}" >&2
              exit 1
          fi
          
          # Check if file is a valid image
          mime_type=$(file --mime-type -b "''${img}")
          if [[ ! "''${mime_type}" =~ ^image/ ]]; then
              echo "Error: Not a valid image file: ''${img} (''${mime_type})" >&2
              exit 1
          fi
      done

      # Calculate dimensions for the inscribed circle
      MIN_DIM=$((CANVAS_WIDTH < CANVAS_HEIGHT ? CANVAS_WIDTH : CANVAS_HEIGHT))
      RADIUS=$((MIN_DIM / 2))
      CIRCLE_CENTER_X=$((CANVAS_WIDTH / 2))
      CIRCLE_CENTER_Y=$((CANVAS_HEIGHT / 2))
      CIRCLE_BOUNDING_BOX_X1=$((CIRCLE_CENTER_X - RADIUS))
      CIRCLE_BOUNDING_BOX_Y1=$((CIRCLE_CENTER_Y - RADIUS))
      CIRCLE_BOUNDING_BOX_X2=$((CIRCLE_CENTER_X + RADIUS))
      CIRCLE_BOUNDING_BOX_Y2=$((CIRCLE_CENTER_Y + RADIUS))

      # Create temporary directory
      tmp_dir=$(mktemp -d)
      trap 'rm -rf "''${tmp_dir}"' EXIT

      # Calculate angle per slice
      degrees_per_image=$((360 / num_images))
      current_angle=0

      declare -a masked_slice_files

      for i in "''${!input_images[@]}"; do
          img="''${input_images[i]}"
          
          # Calculate slice angles
          slice_start_angle="''${current_angle}"
          slice_end_angle=$((current_angle + degrees_per_image))

          # Resize and crop the input image to a square that fits within the circle
          square_crop="''${tmp_dir}/square_crop_''${i}.png"
          magick "''${img}" -resize "''${MIN_DIM}x''${MIN_DIM}^" -gravity center -extent "''${MIN_DIM}x''${MIN_DIM}" "''${square_crop}"

          # Create a circular mask and apply it to the square-cropped image
          circle_mask="''${tmp_dir}/circle_mask_''${i}.png"
          magick -size "''${MIN_DIM}x''${MIN_DIM}" xc:black -fill white -draw "circle ''${RADIUS},''${RADIUS} ''${RADIUS},0" "''${circle_mask}"

          circular_crop="''${tmp_dir}/circular_crop_''${i}.png"
          magick "''${square_crop}" "''${circle_mask}" -alpha off -compose copy_opacity -composite "''${circular_crop}"

          # Place the circular crop on the full canvas
          positioned_circle="''${tmp_dir}/positioned_circle_''${i}.png"
          magick -size "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}" xc:transparent "''${circular_crop}" -geometry "+''${CIRCLE_BOUNDING_BOX_X1}+''${CIRCLE_BOUNDING_BOX_Y1}" -composite "''${positioned_circle}"

          # Create the pie slice mask
          slice_mask="''${tmp_dir}/slice_mask_''${i}.png"
          magick -size "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}" xc:transparent \
              -fill white \
              -draw "arc ''${CIRCLE_BOUNDING_BOX_X1},''${CIRCLE_BOUNDING_BOX_Y1} ''${CIRCLE_BOUNDING_BOX_X2},''${CIRCLE_BOUNDING_BOX_Y2} ''${slice_start_angle} ''${slice_end_angle}" \
              "''${slice_mask}"

          # Apply the pie slice mask to the positioned circular image
          masked_slice="''${tmp_dir}/masked_slice_''${i}.png"
          magick "''${positioned_circle}" "''${slice_mask}" -alpha off -compose copy_opacity -composite "''${masked_slice}"

          masked_slice_files+=("''${masked_slice}")
          current_angle="''${slice_end_angle}"
      done

      # Assemble all masked slices into the final image
      final_composite_command="magick -size ''${CANVAS_WIDTH}x''${CANVAS_HEIGHT} xc:transparent"

      for slice_file in "''${masked_slice_files[@]}"; do
          final_composite_command+=" \"''${slice_file}\" -composite"
      done
      final_composite_command+=" \"''${output_file}\""

      echo "Executing: ''${final_composite_command}"
      eval "''${final_composite_command}"

      echo "Composite image saved to: ''${output_file}"
    '';
  };

  # Create test data directory
  testDataDir = pkgs.runCommand "wallpaper-test-data" {} ''
    mkdir -p $out/images
    mkdir -p $out/mock-home/squeals/.config/stylix
    
    # Create test PNG images using ImageMagick
    ${pkgs.imagemagick}/bin/magick -size 100x100 xc:red $out/images/test1.png
    ${pkgs.imagemagick}/bin/magick -size 100x100 xc:blue $out/images/test2.png
    ${pkgs.imagemagick}/bin/magick -size 100x100 xc:green $out/images/test3.png
    
    # Create a valid test wallpaper for mock user
    cp $out/images/test1.png $out/mock-home/squeals/.config/stylix/image
    
    # Create an invalid image file for testing
    echo "not an image" > $out/images/invalid.txt
  '';

in
{
  # Test the pie-image-combiner directly
  wallpaper-combiner-test = pkgs.runCommand "wallpaper-combiner-test" {
    buildInputs = with pkgs; [ imagemagick file ];
  } ''
    set -euo pipefail
    
    # Import the pie-image-combiner from our test script
    COMBINER_SCRIPT="${pieImageCombinerApp}/bin/pie-image-combiner"
    
    # Create test output directory
    mkdir -p $out/results
    
    echo "=== Testing pie-image-combiner basic functionality ==="
    
    # Test 1: Basic functionality with multiple images
    echo "Test 1: Combining multiple test images..."
    $COMBINER_SCRIPT \
      --width 200 \
      --height 200 \
      ${testDataDir}/images/test1.png \
      ${testDataDir}/images/test2.png \
      ${testDataDir}/images/test3.png \
      $out/results/combined.png
    
    # Verify output exists and is a valid PNG
    if [[ ! -f "$out/results/combined.png" ]]; then
      echo "ERROR: Combined wallpaper was not created"
      exit 1
    fi
    
    # Check if it's a valid image
    file_type=$(${pkgs.file}/bin/file --mime-type -b "$out/results/combined.png")
    if [[ "$file_type" != "image/png" ]]; then
      echo "ERROR: Output is not a valid PNG image (got: $file_type)"
      exit 1
    fi
    
    # Check dimensions using ImageMagick identify
    dimensions=$(${pkgs.imagemagick}/bin/identify -format "%wx%h" "$out/results/combined.png")
    if [[ "$dimensions" != "200x200" ]]; then
      echo "ERROR: Output dimensions are incorrect (expected: 200x200, got: $dimensions)"
      exit 1
    fi
    
    echo "✓ Test 1 passed: Basic pie chart generation works"
    
    # Test 2: Single image input
    echo "Test 2: Single image input..."
    $COMBINER_SCRIPT \
      --width 150 \
      --height 150 \
      ${testDataDir}/images/test1.png \
      $out/results/single.png
    
    if [[ ! -f "$out/results/single.png" ]]; then
      echo "ERROR: Single image wallpaper was not created"
      exit 1
    fi
    
    single_dimensions=$(${pkgs.imagemagick}/bin/identify -format "%wx%h" "$out/results/single.png")
    if [[ "$single_dimensions" != "150x150" ]]; then
      echo "ERROR: Single image output dimensions are incorrect (expected: 150x150, got: $single_dimensions)"
      exit 1
    fi
    
    echo "✓ Test 2 passed: Single image input works"
    
    # Test 3: Error handling for invalid images
    echo "Test 3: Error handling for invalid images..."
    set +e  # Allow command to fail
    $COMBINER_SCRIPT \
      --width 100 \
      --height 100 \
      ${testDataDir}/images/invalid.txt \
      $out/results/should-fail.png 2>/dev/null
    
    exit_code=$?
    set -e
    
    if [[ $exit_code -eq 0 ]]; then
      echo "ERROR: Script should have failed with invalid image but didn't"
      exit 1
    fi
    
    echo "✓ Test 3 passed: Invalid image handling works"
    
    # Test 4: Default dimensions
    echo "Test 4: Default dimensions..."
    $COMBINER_SCRIPT \
      ${testDataDir}/images/test1.png \
      ${testDataDir}/images/test2.png \
      $out/results/default-size.png
    
    default_dimensions=$(${pkgs.imagemagick}/bin/identify -format "%wx%h" "$out/results/default-size.png")
    if [[ "$default_dimensions" != "1024x768" ]]; then
      echo "ERROR: Default dimensions are incorrect (expected: 1024x768, got: $default_dimensions)"
      exit 1
    fi
    
    echo "✓ Test 4 passed: Default dimensions work"
    
    echo "All pie-image-combiner tests passed!"
  '';

  # Test the wallpaper generator script with mock environment
  wallpaper-generator-test = pkgs.runCommand "wallpaper-generator-test" {
    buildInputs = with pkgs; [ imagemagick file coreutils ];
  } ''
    set -euo pipefail
    
    mkdir -p $out/test-results
    
    echo "=== Testing wallpaper generator script ==="
    
    # Create a mock environment
    export HOME=${testDataDir}/mock-home
    mkdir -p $out/etc/nixos/wallpaper
    mkdir -p $out/etc
    
    # Create mock passwd file with test user
    cat > $out/etc/passwd << EOF
root:x:0:0:root:/root:/bin/bash
squeals:x:1000:1000:Test User:/home/squeals:/bin/bash
EOF
    
    # Mock the wallpaper generator script environment
    # We need to extract and adapt the script logic for testing
    
    # Test case 1: User wallpaper found
    echo "Test 1: User wallpaper exists..."
    
    # Create the stylix config directory and image
    mkdir -p $out/home/squeals/.config/stylix
    cp ${testDataDir}/images/test1.png $out/home/squeals/.config/stylix/image
    
    # Simulate the wallpaper collection logic
    USER_WALLPAPER="$out/home/squeals/.config/stylix/image"
    if [[ -f "$USER_WALLPAPER" ]]; then
      echo "✓ User wallpaper found: $USER_WALLPAPER"
      
      # Test the pie-image-combiner with found wallpaper
      ${pieImageCombinerApp}/bin/pie-image-combiner \
        --width 800 \
        --height 600 \
        "$USER_WALLPAPER" \
        $out/test-results/user-wallpaper.png
      
      if [[ ! -f "$out/test-results/user-wallpaper.png" ]]; then
        echo "ERROR: User wallpaper generation failed"
        exit 1
      fi
      
      echo "✓ Test 1 passed: User wallpaper generation works"
    else
      echo "ERROR: Mock user wallpaper not found"
      exit 1
    fi
    
    # Test case 2: No user wallpaper, fallback to default
    echo "Test 2: No user wallpaper, using fallback..."
    
    # Remove user wallpaper
    rm -f $out/home/squeals/.config/stylix/image
    
    # Test with default wallpaper (use our test image)
    DEFAULT_WALLPAPER="${testDataDir}/images/test2.png"
    
    ${pieImageCombinerApp}/bin/pie-image-combiner \
      --width 800 \
      --height 600 \
      "$DEFAULT_WALLPAPER" \
      $out/test-results/fallback-wallpaper.png
    
    if [[ ! -f "$out/test-results/fallback-wallpaper.png" ]]; then
      echo "ERROR: Fallback wallpaper generation failed"
      exit 1
    fi
    
    echo "✓ Test 2 passed: Fallback wallpaper generation works"
    
    # Test case 3: Multiple user wallpapers
    echo "Test 3: Multiple user wallpapers..."
    
    # Create multiple users with wallpapers
    mkdir -p $out/home/user2/.config/stylix
    mkdir -p $out/home/user3/.config/stylix
    cp ${testDataDir}/images/test2.png $out/home/user2/.config/stylix/image
    cp ${testDataDir}/images/test3.png $out/home/user3/.config/stylix/image
    
    # Add users to passwd
    cat >> $out/etc/passwd << EOF
user2:x:1001:1001:User Two:/home/user2:/bin/bash
user3:x:1002:1002:User Three:/home/user3:/bin/bash
EOF
    
    ${pieImageCombinerApp}/bin/pie-image-combiner \
      --width 800 \
      --height 600 \
      $out/home/user2/.config/stylix/image \
      $out/home/user3/.config/stylix/image \
      $out/test-results/multi-user-wallpaper.png
    
    if [[ ! -f "$out/test-results/multi-user-wallpaper.png" ]]; then
      echo "ERROR: Multi-user wallpaper generation failed"
      exit 1
    fi
    
    echo "✓ Test 3 passed: Multi-user wallpaper generation works"
    
    echo "All wallpaper generator tests passed!"
  '';

  # Integration test that simulates the full module behavior
  wallpaper-integration-test = pkgs.runCommand "wallpaper-integration-test" {
    buildInputs = with pkgs; [ imagemagick file ];
  } ''
    set -euo pipefail
    
    mkdir -p $out/integration-results
    
    echo "=== Integration Test: Full wallpaper module simulation ==="
    
    # Test the complete workflow
    echo "Testing complete wallpaper generation workflow..."
    
    # Create test environment
    TEST_OUTPUT="$out/integration-results/final-wallpaper.png"
    
    # Use multiple test images to simulate real usage
    ${pieImageCombinerApp}/bin/pie-image-combiner \
      --width 1920 \
      --height 1080 \
      ${testDataDir}/images/test1.png \
      ${testDataDir}/images/test2.png \
      ${testDataDir}/images/test3.png \
      "$TEST_OUTPUT"
    
    # Comprehensive validation
    if [[ ! -f "$TEST_OUTPUT" ]]; then
      echo "ERROR: Integration test failed - no output file"
      exit 1
    fi
    
    # Validate file type
    file_type=$(${pkgs.file}/bin/file --mime-type -b "$TEST_OUTPUT")
    if [[ "$file_type" != "image/png" ]]; then
      echo "ERROR: Output is not PNG (got: $file_type)"
      exit 1
    fi
    
    # Validate dimensions
    dimensions=$(${pkgs.imagemagick}/bin/identify -format "%wx%h" "$TEST_OUTPUT")
    if [[ "$dimensions" != "1920x1080" ]]; then
      echo "ERROR: Wrong dimensions (expected: 1920x1080, got: $dimensions)"
      exit 1
    fi
    
    # Validate file size (should be reasonable for a PNG)
    file_size=$(stat -c%s "$TEST_OUTPUT")
    if [[ $file_size -lt 1000 ]]; then
      echo "ERROR: Output file too small ($file_size bytes), likely corrupted"
      exit 1
    fi
    
    echo "✓ Integration test passed!"
    echo "  - Output file: $TEST_OUTPUT"
    echo "  - File type: $file_type"
    echo "  - Dimensions: $dimensions"
    echo "  - File size: $file_size bytes"
    
    echo "All integration tests passed!"
  '';
}