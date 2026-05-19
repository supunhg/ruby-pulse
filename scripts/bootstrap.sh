#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Ruby dependencies..."
bundle install

echo "==> Verifying GTK4/libadwaita..."
ruby -e "require 'gtk4'; require 'adwaita'; puts 'GTK4 + libadwaita OK'"

echo "==> Creating data directories..."
mkdir -p data log tmp

echo "==> Done. Run with: ruby app/main.rb"
