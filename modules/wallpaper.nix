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
  pieImageCombinerApp =
    pkgs.writers.writePython3 "pie_wallpaper_generator.py"
      {
        libraries = [ pkgs.python3Packages.pillow ];
      }
      ''
        import sys
        from PIL import Image


        def create_vertical_strip_wallpaper(output_path, resolution, wallpaper_paths):
            width, height = resolution
            num_users = len(wallpaper_paths)
            if num_users == 0:
                print("No wallpapers provided, creating a black image.")
                Image.new('RGB', (width, height), 'black').save(output_path)
                return

            # Create a new blank canvas to paste the slices onto.
            canvas = Image.new('RGB', (width, height))

            # Calculate the width of each vertical slice.
            slice_width = width // num_users

            for i, path in enumerate(wallpaper_paths):
                print(f"Processing slice {i+1}/{num_users} from: {path}")
                try:
                    # Open the user's wallpaper.
                    user_img = Image.open(path).convert('RGB')

                    source_slice_width = user_img.width // num_users
                    left = i * source_slice_width
                    top = 0
                    right = (i + 1) * source_slice_width
                    bottom = user_img.height
                    # Crop the slice from the source image.
                    source_slice = user_img.crop((left, top, right, bottom))

                    dest_width = slice_width
                    if i == num_users - 1:
                        dest_width = width - (i * slice_width)

                    resized_slice = source_slice.resize((dest_width, height),
                                                        Image.Resampling.LANCZOS)
 
                    # Calculate the position to paste the slice on the canvas.
                    paste_x_position = i * slice_width

                    # Paste the final slice onto the main canvas.
                    canvas.paste(resized_slice, (paste_x_position, 0))

                except Exception as e:
                    print(f"Error processing {path}: {e}", file=sys.stderr)

            canvas.save(output_path)
            print(f"Wallpaper successfully saved to {output_path}")

            canvas.save(output_path)
            print(f"Wallpaper successfully saved to {output_path}")


        if __name__ == "__main__":
            output_arg = sys.argv[1]
            resolution_arg = tuple(map(int, sys.argv[2].split('x')))
            paths_arg = sys.argv[3:]
            create_vertical_strip_wallpaper(output_arg, resolution_arg, paths_arg)
      '';

  wallpaperGeneratorScript = pkgs.writeShellScript "generate-wallpaper" ''

    # This script collects user wallpapers at activation time and generates the composite wallpaper

    set -euo pipefail

    # Set up variables
    OUTPUT_PATH="./system-wallpaper.png"
    DEFAULT_WALLPAPER="${toString cfg.defaultWallpaper}"
    FLAKE_ROOT_DEFAULT="${toString cfg.flakeRootDefault}"

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

    echo "Generating combined wallpaper with ${toString cfg.width}x${toString cfg.height} dimensions"

    ${pieImageCombinerApp} \
      "$OUTPUT_PATH" \
      "${toString cfg.width}x${toString cfg.height}" \
      "''${wallpapers[@]}"
      
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
      default = /etc/nixos/wallpaper/default.jpg;
      description = "Default wallpaper to use if no input wallpapers are found.";
    };

    flakeRootDefault = mkOption {
      type = types.path;
      default = /etc/nixos/wallpaper/default.jpg;
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

    # Make sure the tools we need are installed
    environment.systemPackages = [
      pkgs.python313
      pkgs.python313Packages.pillow
      pkgs.python313Packages.pip
    ];
  };
}
