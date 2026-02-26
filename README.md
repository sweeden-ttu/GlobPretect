# Key Executables and Components (For X-Code project)

## Ollama port mapping (canonical)

Same mapping across GlobPretect and all Ollama projects (OllamaHpcc, ollama-rocky, ollama-podman, ollama-mac, ollama-hpcc, langflow-ollama-podman). Workflows that use **@granite**, **@deepseek**, **@qwen-coder**, or **@codellama** call Ollama on the port for that model and environment.

| Environment        | granite | deepseek | qwen-coder | codellama |
|--------------------|---------|----------|------------|-----------|
| Debug (VPN)        | 55077   | 55088    | 66044      | 66033     |
| Testing +1 (macOS) | 55177   | 55188    | 66144      | 66133     |
| Testing +2 (Rocky) | 55277   | 55288    | 66244      | 66233     |
| Release +3        | 55377   | 55388    | 66344      | 66333     |

See **docs/AGENTS.md** for details.

| Path | Size | Description
|------|------|----------------
| GlobalPretect | 13 MB | Main GUI app
| PanGPS | 15 MB | VPN daemon/service
| PanGpHipMp | 6.7 MB | HIP multi-process agent |
| DEM.pkg | 77 MB | Data Endpoint Management (DEM) agent |
| pangpd.kext | 43 KB | Virtual network adapter (kext) |
| gplock.kext | 137 KB | Enforcer kext |
| gpsplit.kext | 88 KB | Split-tunnel kext |
| gplogin.bundle | 255 KB | Login plugin |
| gpsplit-helper | 82 KB | Split-

## Libraries
Libraries
- libwalocal.dylib (10.4 MB)
- libwautils.dylib (17.6 MB)
- libwaapi.dylib (1.7 MB)
- libwaresource.dylib (1.8 MB)

## UI Assets
- Icons, PNG images (dark/light themes)
- NIB files for dialogs (Gateway, Password, SAML, etc.)
- Animation frames (gp-animation_*.png)