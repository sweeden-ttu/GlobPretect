# VPN Background Shortcuts (macOS)

Automated shortcuts to **enable** or **disable** the three Palo Alto Networks "Allow in the Background" items in **System Settings → General → Login Items**. Enabling them lets the VPN run in the background; disabling them turns off the VPN.

## Scripts

| Script | Purpose |
|--------|--------|
| `scripts/enable-vpn-background.applescript` | Enable the three Palo Alto background items (VPN on) |
| `scripts/disable-vpn-background.applescript` | Disable the three Palo Alto background items (VPN off) |

## Prerequisites

1. **Palo Alto Networks GlobalProtect** installed, with the three items visible under **System Settings → General → Login Items → Allow in the Background**.
2. **Accessibility permission** for the app that runs the script (Shortcuts or Script Editor):
   - **System Settings → Privacy & Security → Accessibility**
   - Add **Shortcuts** and/or **Script Editor** (or **Automator**) and ensure they are enabled.

## Create the Shortcuts

### Option A: Shortcuts app (recommended)

1. **Open Shortcuts** (Applications or Spotlight).
2. **Create "Enable VPN Background":**
   - New Shortcut → **+** → search for **Run AppleScript** → add it.
   - In the script box, paste the contents of `scripts/enable-vpn-background.applescript` (or use **File → Open** in Script Editor to open that file, then copy all).
   - Name the shortcut **Enable VPN Background**.
3. **Create "Disable VPN Background":**
   - New Shortcut → **Run AppleScript** → paste the contents of `scripts/disable-vpn-background.applescript`.
   - Name it **Disable VPN Background**.
4. **Optional:** For each shortcut:
   - Right‑click → **Add to Menu Bar** (quick access).
   - Or **Add to Dock**.
   - Or **File → Quick Action** and assign a keyboard shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Shortcuts**.

### Option B: Run the AppleScript files directly

1. **Script Editor** (Applications → Utilities):
   - **File → Open** → choose `enable-vpn-background.applescript` or `disable-vpn-background.applescript`.
   - Click **Run** (▶).
2. **Terminal:**
   ```bash
   cd ~/projects/GlobPretect
   osascript scripts/enable-vpn-background.applescript
   osascript scripts/disable-vpn-background.applescript
   ```

### Option C: Quick Actions (Finder / Services)

1. Open **Automator** → **New** → **Quick Action**.
2. **Workflow receives:** no input. **In:** Any Application.
3. Add action **Run AppleScript**.
4. Paste the contents of `enable-vpn-background.applescript` or `disable-vpn-background.applescript`.
5. Save as **Enable VPN Background** or **Disable VPN Background**.
6. Assign a keyboard shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Shortcuts → Services**.

## Behavior

- **Enable:** Opens System Settings to Login Items, finds the three Palo Alto "Allow in the Background" toggles, and turns them **on**. Shows a notification when done.
- **Disable:** Same, but turns the three toggles **off** (VPN background off).
- If the toggles are not found (e.g. different macOS version or UI), an alert explains how to change them manually in System Settings.

## Permissions

- **Accessibility** is required so the script can control System Settings (UI scripting).
- The first time you run a shortcut, macOS may prompt for Accessibility; approve it for Shortcuts (or Script Editor / Automator).

## Troubleshooting

- **Error -10814 (kLSApplicationNotFoundErr)**  
  This means LaunchServices could not find the app that handles the System Settings URL. The scripts use the correct URL scheme `x-apple.systempreferences:` (with a **dot**) and, if that fails, a fallback using the shell `open` command. If you still see -10814, run the shortcut from the **Shortcuts** app (with Shortcuts allowed in Accessibility) or open System Settings → General → Login Items manually, then run the script again.

- **"Could not open Login Items"**  
  Open **System Settings → General → Login Items** once manually, then run the shortcut again.

- **"Could not find Palo Alto toggles"**  
  Scroll to **Allow in the Background** in Login Items and enable/disable the three **Palo Alto Networks** items by hand. If your Mac uses different labels, the script may need the name/description updated in the AppleScript.

- **Script runs but nothing changes**  
  Confirm **Shortcuts** (or the app you use) is listed and enabled under **Privacy & Security → Accessibility**.

- **Different number of Palo Alto items**  
  Edit the script: set `maxPaloAltoItems` to the correct number (default is 3).
