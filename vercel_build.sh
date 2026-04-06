#!/bin/bash
set -e

FLUTTER_VERSION="3.32.0"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

echo "==> Downloading Flutter SDK ${FLUTTER_VERSION}..."
curl -fsSL "$FLUTTER_URL" -o /tmp/flutter.tar.xz
tar xf /tmp/flutter.tar.xz -C /tmp
export PATH="/tmp/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building web release..."
flutter build web --release --base-href "/"

echo "==> Build complete. Output in build/web/"
