{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.dots.wallpaper;

  # 1. Define the pie-image-combiner script directly within the module
  pieImageCombinerApp = pkgs.writeShellApplication {
    name = "pie-image-combiner";
    runtimeInputs = [
      pkgs.imagemagick
      pkgs.file
    ]; # Added file for mime type checks
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
      # Parse command line options for width and height before processing image paths.
      # Positional arguments (image paths and output file) are collected into 'args'.
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
      set -- "''${args[@]}" # Restore positional parameters for further processing

      # Check for minimum arguments: at least one input image and one output file
      if [[ "$#" -lt 2 ]]; then
          echo "Usage: $(basename "$0") [--width <pixels>] [--height <pixels>] <image1.jpg> [image2.png ...] <output.png>"
          echo ""
          echo "  --width   Set the canvas width (default: ''${CANVAS_WIDTH})"
          echo "  --height  Set the canvas height (default: ''${CANVAS_HEIGHT})"
          echo ""
          echo "Combines input images into a circular composite, where each image"
          echo "occupies an equal angular slice like a pie chart."
          echo "The last argument after options is assumed to be the output file name."
          exit 1
      fi

      # Fix: Use more robust array handling to prevent ShellCheck warnings
      output_file="''${!#}" # The last argument is the output file name

      # Fix: Use declare and a loop instead of array slice syntax
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
          
          # Check if file is a valid image (basic check)
          mime_type=$(file --mime-type -b "''${img}")
          if [[ ! "''${mime_type}" =~ ^image/ ]]; then
              echo "Error: Not a valid image file: ''${img} (''${mime_type})" >&2
              exit 1
          fi
      done

      # --- Calculate dimensions for the inscribed circle ---
      # The circular pie chart will fit within the smaller of the two canvas dimensions.
      MIN_DIM=$((CANVAS_WIDTH < CANVAS_HEIGHT ? CANVAS_WIDTH : CANVAS_HEIGHT))
      RADIUS=$((MIN_DIM / 2))
      CIRCLE_CENTER_X=$((CANVAS_WIDTH / 2))
      CIRCLE_CENTER_Y=$((CANVAS_HEIGHT / 2))
      # Bounding box for drawing the circle/arcs.
      # This defines a square within which the circle is inscribed.
      CIRCLE_BOUNDING_BOX_X1=$((CIRCLE_CENTER_X - RADIUS))
      CIRCLE_BOUNDING_BOX_Y1=$((CIRCLE_CENTER_Y - RADIUS))
      CIRCLE_BOUNDING_BOX_X2=$((CIRCLE_CENTER_X + RADIUS))
      CIRCLE_BOUNDING_BOX_Y2=$((CIRCLE_CENTER_Y + RADIUS))

      # Create a temporary directory for intermediate files
      tmp_dir="$(mktemp -d)"
      trap 'rm -rf "''${tmp_dir}"' EXIT # Clean up on script exit

      current_angle=0
      # Calculate the angle for each slice. If only one image, it takes the full 360 degrees.
      if [[ "''${num_images}" -gt 0 ]]; then
          angle_per_slice=$((360 / num_images))
      else
          angle_per_slice=360
      fi

      # Array to hold paths to the final masked image slices
      masked_slice_files=()

      # Process each input image
      for i in "''${!input_images[@]}"; do
          img_path="''${input_images[$i]}"
          slice_start_angle="''${current_angle}"
          slice_end_angle=$((current_angle + angle_per_slice))

          # For the last slice, ensure the end angle is exactly 360 to close the circle,
          # compensating for potential integer division inaccuracies.
          if [[ "''${i}" -eq $((num_images - 1)) ]]; then
              slice_end_angle=360
          fi
          
          # 1. Resize and crop the image to fit the rectangular canvas.
          #    '-resize "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}^"' scales to fill, maintaining aspect ratio.
          #    '-gravity Center -crop ...' then crops to the exact canvas dimensions from the center.
          resized_img="''${tmp_dir}/img_''${i}_resized.png"
          magick "''${img_path}" \
              -resize "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}^" \
              -gravity Center -crop "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}+0+0" +repage \
              -format png "''${resized_img}"

          # 2. Create a full circular mask, centered within the canvas, limited by MIN_DIM.
          #    'circle center_x,center_y radius_x,radius_y' draws a circle.
          #    'radius_x,radius_y' is a point on the circumference from the center.
          circular_mask="''${tmp_dir}/circular_mask_''${i}.png"
          magick -size "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}" xc:black \
              -fill white \
              -draw "circle ''${CIRCLE_CENTER_X},''${CIRCLE_CENTER_Y} ''${CIRCLE_CENTER_X},''${CIRCLE_CENTER_Y-RADIUS}" \
              "''${circular_mask}"

          # 3. Apply the circular mask to the resized image.
          #    '-alpha set -channel A -evaluate set 0% +channel' properly initializes alpha channel.
          #    '-compose DstIn -composite' effectively "cuts out" the circular shape from the image.
          circular_cropped_img="''${tmp_dir}/img_''${i}_circular_cropped.png"
          magick "''${resized_img}" "''${circular_mask}" \
              -alpha set -channel A -evaluate set 0% +channel \
              -compose DstIn -composite "''${circular_cropped_img}"

          # 4. Create the specific pie slice mask for the current image.
          #    'arc x1,y1 x2,y2 start_angle end_angle' draws an arc within a bounding box.
          #    The bounding box here is for the inscribed circle.
          slice_mask="''${tmp_dir}/slice_mask_''${i}.png"
          magick -size "''${CANVAS_WIDTH}x''${CANVAS_HEIGHT}" xc:transparent \
              -fill white \
              -draw "arc ''${CIRCLE_BOUNDING_BOX_X1},''${CIRCLE_BOUNDING_BOX_Y1} ''${CIRCLE_BOUNDING_BOX_X2},''${CIRCLE_BOUNDING_BOX_Y2} ''${slice_start_angle} ''${slice_end_angle}" \
              "''${slice_mask}"

          # 5. Apply the pie slice mask to the circular-cropped image.
          #    This step cuts the final pie slice shape from the circular image.
          masked_slice="''${tmp_dir}/masked_slice_''${i}.png"
          magick "''${circular_cropped_img}" "''${slice_mask}" \
              -alpha set -channel A -evaluate set 0% +channel \
              -compose DstIn -composite "''${masked_slice}"

          masked_slice_files+=("''${masked_slice}") # Add this slice to an array for final combination

          current_angle="''${slice_end_angle}" # Update the starting angle for the next slice
      done

      # 6. Assemble all the masked slices into a final image.
      #    Start with a transparent background of the defined CANVAS_WIDTH x CANVAS_HEIGHT.
      final_composite_command="magick -size ''${CANVAS_WIDTH}x''${CANVAS_HEIGHT} xc:transparent"

      for slice_file in "''${masked_slice_files[@]}"; do
          final_composite_command+=" \"''${slice_file}\" -composite"
      done
      final_composite_command+=" \"''${output_file}\""

      echo "Executing: ''${final_composite_command}"
      eval "''${final_composite_command}" # Use eval to execute the dynamically built command string

      echo "Composite image saved to: ''${output_file}"
    '';
  };

  # Script that runs during activation to collect and generate the wallpaper
  wallpaperGeneratorScript = pkgs.writeShellScript "generate-wallpaper" ''
    # This script collects user wallpapers at activation time and generates the composite wallpaper

    set -euo pipefail

    # Set up variables
    WALLPAPER_DIR="/etc/nixos/wallpaper"
    OUTPUT_PATH="$WALLPAPER_DIR/combined-wallpaper.png"
    DEFAULT_WALLPAPER="${toString cfg.defaultWallpaper}"
    FLAKE_ROOT_DEFAULT="${toString cfg.flakeRootDefault}"

    # Create wallpaper directory if it doesn't exist
    mkdir -p "$WALLPAPER_DIR"

    # Function to find wallpapers in user HOME directories
    collect_user_wallpapers() {
      local -a wallpapers=()
      
      # Check each user's home directory
      while IFS=: read -r username _ uid _ _ home_dir _; do
        # Skip system users and users with UID < 1000
        if [[ "$uid" -lt 1000 ]]; then
          continue
        fi
        
        # Look for stylix config in user's home
        if [[ -f "$home_dir/.config/stylix/image" ]]; then
          # This might be a path or a symlink to the actual wallpaper
          user_wallpaper=$(readlink -f "$home_dir/.config/stylix/image")
          if [[ -f "$user_wallpaper" ]]; then
            echo "Found wallpaper for user $username: $user_wallpaper"
            wallpapers+=("$user_wallpaper")
          fi
        fi
      done < /etc/passwd
      
      # If no wallpapers found, use default
      if [[ "''${#wallpapers[@]}" -eq 0 ]]; then
        # Try flake root default first
        if [[ -f "$FLAKE_ROOT_DEFAULT" ]]; then
          echo "No user wallpapers found. Using flake root default: $FLAKE_ROOT_DEFAULT"
          wallpapers+=("$FLAKE_ROOT_DEFAULT")
        else
          # Fall back to configured default
          echo "No user wallpapers found. Using configured default: $DEFAULT_WALLPAPER"
          wallpapers+=("$DEFAULT_WALLPAPER")
        fi
      fi
      
      # Fix: Print array elements properly quoted
      for wp in "''${wallpapers[@]}"; do
        printf "%s\n" "$wp"
      done
    }

    # Collect wallpapers - Fix: Use read to handle paths with spaces
    mapfile -t wallpapers < <(collect_user_wallpapers)

    # Generate the pie chart wallpaper
    echo "Generating combined wallpaper with ${toString cfg.width}x${toString cfg.height} dimensions"
    ${pieImageCombinerApp}/bin/pie-image-combiner \
      --width ${toString cfg.width} \
      --height ${toString cfg.height} \
      "''${wallpapers[@]}" \
      "$OUTPUT_PATH"
      
    # Update stylix to use the new wallpaper
    # We need to create a symlink that matches the expected stylix path pattern
    echo "Setting system wallpaper to: $OUTPUT_PATH"
    ln -sf "$OUTPUT_PATH" "/etc/nixos/wallpaper.png"

    # Force stylix to reload the wallpaper
    if command -v "dconf" &> /dev/null; then
      echo "Refreshing desktop wallpaper..."
      
      # If using GNOME
      dconf reset /org/gnome/desktop/background/picture-uri || true
      sleep 1
      dconf write /org/gnome/desktop/background/picture-uri "'file:///etc/nixos/wallpaper.png'" || true
      
      # If using KDE Plasma
      if command -v "plasma-apply-wallpaperimage" &> /dev/null; then
        plasma-apply-wallpaperimage "/etc/nixos/wallpaper.png" || true
      fi
    fi

    echo "Wallpaper generation complete!"
  '';

in
{
  # Define module options under the 'dots.wallpaper' path
  options.dots.wallpaper = {
    enable = mkEnableOption "NixOS Pie Chart Wallpaper Generator";

    width = mkOption {
      type = types.int;
      default = 1920;
      description = "Width of the generated wallpaper in pixels.";
      apply =
        value: if value <= 0 then throw "dots.wallpaper: Width must be a positive integer" else value;
    };

    height = mkOption {
      type = types.int;
      default = 1080;
      description = "Height of the generated wallpaper in pixels.";
      apply =
        value: if value <= 0 then throw "dots.wallpaper: Height must be a positive integer" else value;
    };

    defaultWallpaper = mkOption {
      type = types.path;
      default = ../../../assets/wallpaper.jpg;
      description = "Default wallpaper to use if no input wallpapers are found.";
    };

    flakeRootDefault = mkOption {
      type = types.path;
      default = ../../../assets/wallpaper.jpg;
      description = "Path to the default wallpaper in your flake root.";
      example = literalExpression "../../../assets/wallpaper.jpg";
    };
  };

  # Configure the module's behavior
  config = mkIf cfg.enable {
    # Ensure stylix is enabled
    assertions = [
      {
        assertion = hasAttrByPath [ "stylix" "enable" ] config && config.stylix.enable;
        message = "dots.wallpaper requires stylix to be enabled";
      }
    ];

    # Create a system-level directory for storing the wallpaper
    system.activationScripts.setupWallpaperDir = ''
      mkdir -p /etc/nixos/wallpaper
    '';

    # Use our script to generate the wallpaper during activation
    system.activationScripts.generatePieChartWallpaper = ''
      # Run the wallpaper generator script
      echo "Generating pie chart wallpaper from user wallpapers..."
      ${wallpaperGeneratorScript}
    '';

    # Tell stylix to use our image path
    # This won't create a circular dependency because the path is fixed ahead of time
    stylix.image = ../assets/wallpaper.jpg;

    # Make sure the tools we need are installed
    environment.systemPackages = with pkgs; [
      imagemagick
      file
    ];
  };
}
