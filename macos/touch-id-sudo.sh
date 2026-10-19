#!/usr/bin/env bash
set -euo pipefail

# Only run on macOS
if [[ "$(uname)" != "Darwin" ]]; then
  exit 0
fi

TEMPLATE="/etc/pam.d/sudo_local.template"
TARGET="/etc/pam.d/sudo_local"

# Ensure macOS supports sudo_local
if [[ ! -f "$TEMPLATE" ]]; then
  echo "Touch ID sudo configuration is not supported."
  exit 0
fi

ENABLED='^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)'

# Skip if already enabled
if [[ -f "$TARGET" ]] && grep -Eq "$ENABLED" "$TARGET"; then
  echo "Touch ID for sudo is already enabled."
  exit 0
fi

# sudo needs a terminal to prompt for the password
if [[ ! -t 0 ]]; then
  echo "No terminal for the sudo prompt, skipping Touch ID for sudo. Re-run: sh $0" >&2
  exit 0
fi

echo "Enabling Touch ID for sudo..."

# Preserve existing configuration, if present.
# Otherwise initialize from Apple's template.
if [[ ! -f "$TARGET" ]]; then
  sudo cp "$TEMPLATE" "$TARGET"
fi

# Uncomment Apple's Touch ID authentication line.
sudo sed -i '' \
  -E 's/^#[[:space:]]*(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)/\1/' \
  "$TARGET"

# sudo_local may exist without the line (even commented out): append it.
if ! grep -Eq "$ENABLED" "$TARGET"; then
  echo "auth       sufficient     pam_tid.so" | sudo tee -a "$TARGET" >/dev/null
fi

grep -Eq "$ENABLED" "$TARGET" || { echo "Failed to enable Touch ID for sudo in $TARGET" >&2; exit 1; }
echo "Touch ID for sudo enabled."
