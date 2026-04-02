# Screenshot Capture Manual

## Permission Preflight (macOS)
On macOS, run the preflight helper before capture to check Screen Recording permissions:
```bash
bash ../scripts/ensure_macos_permissions.sh
```

## Platform-Specific Patterns

### macOS and Linux (Python helper)
```bash
python3 ../scripts/take_screenshot.py
```
- **Temp location**: `--mode temp`
- **Explicit location**: `--path output/screen.png`
- **App capture (macOS only)**: `--app "App Name"`
- **Pixel region**: `--region 100,200,800,600`
- **Active window**: `--active-window`

### Windows (PowerShell helper)
```powershell
powershell -ExecutionPolicy Bypass -File ../scripts/take_screenshot.ps1
```
- **Temp location**: `-Mode temp`
- **Pixel region**: `-Region 100,200,800,600`
- **Active window**: `-ActiveWindow`

## Direct OS Command Fallbacks

### macOS
- **Full screen**: `screencapture -x path/to.png`
- **Region**: `screencapture -x -R100,200,800,600 path/to.png`
- **Specific window**: `screencapture -x -l12345 path/to.png`

### Linux
- **scrot**: `scrot path/to.png`
- **gnome-screenshot**: `gnome-screenshot -f path/to.png`
- **ImageMagick**: `import -window root path/to.png`

## Error Handling
- **Sandbox blocked**: Rerun with escalated permissions if capture is blocked in the sandbox.
- **No matches (macOS)**: Run `--list-windows --app "AppName"` to verify window visibility.
- **Linux missing tools**: Check `command -v scrot` or `gnome-screenshot`.
- **Permission errors**: Ensure the agent has write access to the destination path.
