#!/usr/bin/env bash
# DEPRECATED: ISO signing is now handled by the flake build process
# Use: nix build .#shulkerbox-installer-signed
# This script is kept for compatibility but should not be used

echo "⚠️  DEPRECATED: This script is no longer needed."
echo ""
echo "ISO signing is now integrated into the flake build process."
echo "To build a signed ISO, use:"
echo ""
echo "    nix build .#shulkerbox-installer-signed"
echo ""
echo "The signing will happen automatically if Secure Boot keys are available at /etc/secureboot"
echo ""
exit 1
