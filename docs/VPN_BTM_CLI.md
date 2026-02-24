# Apple CLI for Background Items (BTM) – Undocumented Options

This doc summarizes **built-in Apple command-line tools** for "Allow in the Background" (Background Task Management / BTM). Most of this is **not** in the official `sfltool` man page.

## What `sfltool` actually supports

Running `sfltool` with no arguments shows:

```text
Usage: sfltool csinfo|dumpbtm|archive|clear|resetbtm|resetlist|list|list-info [options]
```

Only **archive**, **dumpbtm**, and **resetbtm** are documented in the man page. The rest are effectively undocumented.

| Command        | Documented? | Purpose |
|----------------|-------------|--------|
| **dumpbtm**    | Yes         | Print all login and background items, UUIDs, disposition, identifiers. |
| **resetbtm**   | Yes         | Reset **all** login and background item data (nuclear). Reboot recommended. |
| **archive**    | Yes         | Snapshot SharedFileList stores. `-z` = compress. |
| **list**       | No          | List Shared File List identifiers (e.g. `com.apple.LSSharedFileList.GlobalLoginItems`). |
| **list-info**  | No          | Same as `list` in practice. |
| **clear**      | No          | (Requires arguments; exact usage not documented.) |
| **resetlist**  | No          | Reset a **single** shared file list: `sfltool resetlist <list-identifier>`. |
| **csinfo**     | No          | (Usage not documented.) |

## Useful commands for VPN / Palo Alto

**View all BTM entries (including Palo Alto / GlobalProtect):**

```bash
sudo sfltool dumpbtm
```

**Filter for Palo Alto / GlobalProtect:**

```bash
sudo sfltool dumpbtm | grep -A 15 "Palo Alto\|GlobalProtect\|pangp"
```

**Save full BTM dump (e.g. before any reset):**

```bash
sudo sfltool dumpbtm > ~/Documents/btmdump.txt
```

## What BTM stores (from `dumpbtm`)

Each item has:

- **UUID** – unique id
- **Name** – e.g. "Palo Alto Networks", "GlobalProtect"
- **Identifier** – e.g. `8.com.paloaltonetworks.gp.pangps`, `16.com.paloaltonetworks.gp.pangpsd`
- **Disposition** – bits that drive "Allow in the Background":
  - `0x01` = enabled  
  - `0x02` = **allowed** (user has turned ON "Allow in the Background")  
  - `0x04` = hidden  
  - `0x08` = notified  

When you turn **off** "Allow in the Background" in System Settings, the **allowed** bit is cleared (e.g. you see `[enabled, disallowed, notified]`).

## Is there a CLI to turn one item on/off?

**No.** Apple does **not** ship a documented (or clearly supported) command to set a single BTM item’s "allowed" state.

- **dumpbtm** – read-only.
- **resetbtm** – resets **everything** (all login and background items), not a single app.
- **resetlist** – affects Shared File Lists (e.g. login items list), not the per-item "allowed" bit in BTM.

The BTM data lives in binary files under  
`/private/var/db/com.apple.backgroundtaskmanagement/` (e.g. `BackgroundItems-v*.btm`, NSKeyedArchive). There is no supported CLI or `defaults` key to edit those. Modifying them by hand is unsupported and can break things.

So for "enable/disable the three Palo Alto items in the background":

- **sfltool cannot enable specific items.** Only **dumpbtm** (inspect) and **resetbtm** (reset all) exist. No per-item toggle.
- **Practical options:**
  1. **launchctl** – Load/unload the three Palo Alto launchd jobs so they run in background and load at startup. Scripts in this repo:
     - `scripts/enable-paloalto-launchd.sh` – load the 3 jobs (daemon + 2 agents). Run with `sudo` to enable the daemon too.
     - `scripts/disable-paloalto-launchd.sh` – unload the 3 jobs.
     These work only if the three items are already **allowed** in System Settings → General → Login Items → Allow in the Background; otherwise BTM policy may block loading.
  2. **AppleScript + Shortcuts** – UI automation to toggle the three items in System Settings (see `docs/VPN_SHORTCUTS.md`).
  3. **Manual** – System Settings → General → Login Items → Allow in the Background.

## References

- Man page (partial): `man sfltool`
- Eclectic Light: [Diagnose and control login and background items](https://eclecticlight.co/2023/07/04/how-to-diagnose-and-control-login-and-background-items/)
- Apple: [Manage login items and background tasks](https://support.apple.com/en-gb/guide/deployment/depdca572563/web) (MDM/deployment)
- Third-party **read-only** tools: Objective See’s DumpBTM, BTMParser (parse BTM files)
