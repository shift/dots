#!/usr/bin/env bash
# ISO signing is now integrated into the flake build process
# Use: nix build .#shulkerbox-installer-signed

set -euo pipefail

echo "🚀 ISO signing is now integrated into the flake!"
echo ""
echo "To build a signed ISO, use:"
echo ""
echo "    nix build .#shulkerbox-installer-signed"
echo ""
echo "The signing will happen automatically if Secure Boot keys are available at ./secrets/secureboot"
echo ""
echo "Available commands:"
echo "  nix flake show                           - Show available packages"
echo "  nix build .#shulkerbox-installer-signed  - Build signed ISO"
echo "  nix build .#nixosConfigurations.shulkerbox-installer.config.system.build.isoImage  - Build unsigned ISO"
echo ""

# If user insists on running this script, show them how to build
read -r -p "Would you like to build the signed ISO now? (y/N): " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	echo "Building signed ISO..."
	nix build .#shulkerbox-installer-signed
	echo "✅ Done! Check result/ for the signed ISO"
else
	echo "Exiting. Use the nix build command above when ready."
fi
