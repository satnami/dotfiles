#!/bin/sh

# macOS system preferences, the way iTerm/setup.sh and ghostty/setup.sh set up
# their apps: plain `defaults write` calls. Idempotent; setup.sh runs it.
#
# Run as your own user, never with sudo: `defaults write` without a domain path
# targets the preferences of the user running it, so a root run would configure
# root and leave your account untouched. The one system-wide key below asks for
# sudo on its own, and only when it is not set yet.
#
# Some keys are ignored by current macOS releases and are marked below; they are
# kept because they are harmless and still work on older systems.

warn() { printf '    WARN  %s\n' "$*" >&2; }

# ------------------------------------------------------- Keyboard and input
# Key repeat instead of the accent popup, globally. The VS Code lines below are
# the per-app version of this and stay as a fallback for apps that opt out.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Fastest repeat rate; 15 = ~225ms before the repeat starts.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# No text substitution: all of these mangle code, paths and commit messages.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
# Full keyboard access: Tab reaches every control in a dialog, not just text fields.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# ------------------------------------------------------- Documents and iCloud
# New documents default to the local disk instead of iCloud Drive.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# -------------------------------------------------------------------- Safari
# Safari is sandboxed: these two writes fail with "Could not write domain"
# unless the terminal has Full Disk Access (System Settings > Privacy &
# Security > Full Disk Access). Not fatal, so only warn.
{
  # No web suggestions mixed into the Smart Search Field.
  defaults write com.apple.Safari UniversalSearchEnabled -bool false &&
  # No search suggestions sent to Apple.
  defaults write com.apple.Safari SuppressSearchSuggestions -bool true
} 2>/dev/null || warn "Safari prefs skipped: give your terminal Full Disk Access and re-run"

# ------------------------------------------------------------------ Printing
# Quit the print queue app once its jobs finish.
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# ----------------------------------------------------------------- App Store
# WebKit dev extras in App Store web views. Ignored on current macOS.
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# -------------------------------------------------------------------- Finder
# Always show file extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# Show volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
# Show dotfiles.
defaults write com.apple.finder AppleShowAllFiles -bool true
# Status bar (item count, free space) and path bar.
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true
# No warning when a filename extension changes.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Show ~/Library, which macOS hides by default.
chflags nohidden "$HOME/Library"
# List view and current-folder search in every new window.
# View styles: Nlsv list, icnv icon, clmv column, Flwv gallery.
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
# Search scopes: SCcf current folder, SCsp previous scope, SCev this Mac.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Folders before files when sorting by name.
defaults write com.apple.finder _FXSortFoldersFirst -bool true
# New windows open at $HOME. PfHm = home; NewWindowTargetPath must agree with it.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/"
# Full POSIX path in the window title, so it can be copied out.
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# No confirmation when emptying the Trash.
defaults write com.apple.finder WarnOnEmptyTrash -bool false
# Save dialogs and Get Info panels open expanded.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true

# No .DS_Store files on network shares or USB volumes.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ----------------------------------------------------------- Software Update
# Check daily instead of weekly. Ignored on current macOS; the live setting is
# System Settings > General > Software Update > Automatic updates.
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# ------------------------------------------------------------------ VS Code
# Turn off the press-and-hold accent popup so key repeat works in the editor.
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
defaults write com.microsoft.VSCodeInsiders ApplePressAndHoldEnabled -bool false

# --------------------------------------------------------------- Login window
# Show the host name on the login window. System-wide, so it needs sudo; only
# written when it is missing, so a re-run does not ask for a password.
if [ "$(defaults read /Library/Preferences/com.apple.loginwindow AdminHostInfo 2>/dev/null)" = "HostName" ]; then
  printf '    ok    loginwindow AdminHostInfo\n'
else
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName ||
    warn "loginwindow AdminHostInfo not set (sudo declined?)"
fi

# --------------------------------------------------------- Screen saver lock
# Require the password immediately after sleep or screen saver. Ignored since
# macOS Ventura; the live setting is System Settings > Lock Screen >
# "Require password after screen saver begins".
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# --------------------------------------------------------------- Screenshots
# No window drop shadow, PNG, saved to ~/Screenshots (this machine's setting;
# the target folder must exist or screencapture silently falls back to ~/Desktop).
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
# macOS 14+ keeps separate targets for stills and recordings; keep all three aligned.
defaults write com.apple.screencapture location-screenshot -string "$HOME/Screenshots"
defaults write com.apple.screencapture location-screenrecording -string "$HOME/Screenshots"
# Short file name instead of "Screenshot 2026-10-09 at 12.00.00".
defaults write com.apple.screencapture name -string "shot"
# No floating thumbnail after each capture.
defaults write com.apple.screencapture show-thumbnail -bool false

# ---------------------------------------------------------------------- Dock
# Scale minimize effect, into the app icon, no recents section, auto-hide.
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock autohide -bool true
# Dock appears on hover immediately instead of after ~0.5s.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
# No bouncing icons when an app wants attention.
defaults write com.apple.dock no-bouncing -bool true
# Group windows by application in Mission Control.
defaults write com.apple.dock expose-group-apps -bool true

# ------------------------------------------------------------------ Window UI
# Near-instant window resize and no open/close animation.
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
# Scrollbars always visible. Values: Automatic, WhenScrolling, Always.
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"
# System Settings does not restore its windows on relaunch.
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# ---------------------------------------------------------------------- Mail
# Copy bare email addresses, without the display name.
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# ------------------------------------------------------------------- Restart
# Most of the above only shows up after the owning process restarts.
killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

printf '    ok    macOS defaults written\n'
