#!/bin/bash

# --- CONFIGURATION ---
APP_VERSION="1.0.5"
APP_NAME="Snap Back"

# --- CYBERPUNK THEME COLORS ---
BOLD='\033[1m'
# Neon Palette (256-color)
NEON_CYAN='\033[38;5;51m'
NEON_BLUE='\033[38;5;33m'
NEON_GREEN='\033[38;5;82m'
NEON_PURPLE='\033[38;5;129m'
ALERT_RED='\033[38;5;196m'
WARN_YELLOW='\033[38;5;226m'
DIM_GREY='\033[38;5;238m'
TXT_GREY='\033[38;5;250m'
NC='\033[0m' # No Color

# --- UI UTILITIES ---

# Tactical Separator
print_line() {
    printf "${NEON_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Modular Step Function
show_step() {
    local step_num="$1"
    local desc="$2"
    # Pads number with zero if less than 10
    local fmt_num=$(printf "%02d" $step_num)
    printf "${NEON_PURPLE}❯❯ [${fmt_num}] ${NEON_CYAN}${desc}${NC}\n"
}

# Spinner with rotating slash
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    printf "  "
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "${NEON_GREEN}%c${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b"
    done
    printf " \b\b"
}

# Cyber Header
show_banner() {
    clear
    printf "${NEON_CYAN}"
    cat << "EOF"
 █▀ █▄ █ ▄▀█ █▀█  █▄▄ ▄▀█ █▀▀ █▄▀
 ▄█ █ ▀█ █▀█ █▀▀  █▄█ █▀█ █▄▄ █ █
EOF
    printf "${NC}\n"
    print_line
    printf " ${BOLD}BUILDER & INSTALLER PROTOCOL${NC}\n"
    printf " ${TXT_GREY}Author: Arun Thomas${NC}\n"
    print_line
    printf "\n"
}

# High-Impact Outcome: Success
show_success_art() {
    printf "\n${NEON_GREEN}"
    cat << "EOF"
 █▀ █ █ █▀▀ █▀▀ █▀▀ █▀ █▀
 ▄█ █▄█ █▄▄ █▄▄ ██▄ ▄█ ▄█
EOF
    printf "${NC}\n"
}

# High-Impact Outcome: Failure
show_failure_art() {
    printf "\n${ALERT_RED}"
    cat << "EOF"
 █▀▀ ▄▀█ █ █   █▀▀ █▀▄
 █▀  █▀█ █ █▄▄ ██▄ █▄▀
EOF
    printf "${NC}\n"
}

# --- WINDOW RESIZE ---
resize_window() {
    osascript -e 'tell application "Terminal" to set number of rows of front window to 42' -e 'tell application "Terminal" to set number of columns of front window to 85' &>/dev/null || \
    osascript -e 'tell application "iTerm" to set columns of current session of current window to 85' -e 'tell application "iTerm" to set rows of current session of current window to 42' &>/dev/null || true
}

# --- EXECUTION START ---

resize_window
show_banner

# --- STEP 0: SYSTEM CHECK ---
show_step 0 "Scanning system for compilation tools..."

if ! xcode-select -p &>/dev/null; then
    printf "   ${WARN_YELLOW}⚠ Tools missing. Initiating download sequence...${NC}\n"
    xcode-select --install
    print_line
    printf "   ${WARN_YELLOW}WAITING FOR USER INTERACTION...${NC}\n"
    printf "   Please complete the installer prompt.\n"
    printf "   Press [ENTER] when installation is confirmed..."
    read -r

    if ! xcode-select -p &>/dev/null; then
        show_failure_art
        printf "\n"
        printf "   ${ALERT_RED}Installation not confirmed. Xcode Command Line Tools are required.${NC}\n"
        printf "   ${TXT_GREY}Please rerun the script and complete the installation.${NC}\n"
        exit 1
    fi
else
    printf "   ${NEON_GREEN}✔ Xcode Command Line Tools detected.${NC}\n"
fi
printf "\n"

# --- STEP 1: ENVIRONMENT ---
# Create a secure temporary directory
BUILD_DIR=$(mktemp -d)

show_step 1 "Initializing clean build workspace..."
printf "   Target Path: ${TXT_GREY}$BUILD_DIR${NC}\n"

# Move into the temp directory
pushd "$BUILD_DIR" > /dev/null

# --- STEP 2: ASSET GENERATION ---
show_step 2 "Synthesizing high-resolution assets..."

(
cat > GenIcon.swift <<'EOF'
import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let context = NSGraphicsContext.current!.cgContext

// 1. Background (Dark Rounded Rect)
let bgPath = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 224, yRadius: 224)
NSColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0).setFill() // Dark Grey
bgPath.fill()

context.setShadow(offset: CGSize(width: 0, height: -10), blur: 25, color: NSColor.black.withAlphaComponent(0.6).cgColor)

// 2. Corners (Restored & Adjusted)
let strokePath = NSBezierPath()
strokePath.lineWidth = 70
strokePath.lineCapStyle = .round
strokePath.lineJoinStyle = .round
let padding: CGFloat = 160
let legLength: CGFloat = 160

func drawCorner(start: CGPoint, corner: CGPoint, end: CGPoint) {
    strokePath.move(to: start)
    strokePath.line(to: corner)
    strokePath.line(to: end)
}

// Top Left
drawCorner(start: CGPoint(x: padding, y: 1024 - padding - legLength), corner: CGPoint(x: padding, y: 1024 - padding), end: CGPoint(x: padding + legLength, y: 1024 - padding))
// Top Right
drawCorner(start: CGPoint(x: 1024 - padding - legLength, y: 1024 - padding), corner: CGPoint(x: 1024 - padding, y: 1024 - padding), end: CGPoint(x: 1024 - padding, y: 1024 - padding - legLength))
// Bottom Left
drawCorner(start: CGPoint(x: padding, y: padding + legLength), corner: CGPoint(x: padding, y: padding), end: CGPoint(x: padding + legLength, y: padding))
// Bottom Right
drawCorner(start: CGPoint(x: 1024 - padding - legLength, y: padding), corner: CGPoint(x: 1024 - padding, y: padding), end: CGPoint(x: 1024 - padding, y: padding + legLength))

let cyan = NSColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)
cyan.setStroke()
strokePath.stroke()

// 3. Central Arrow (Reduced Size & Centered)
let arrowPath = NSBezierPath()
let center = CGPoint(x: 512, y: 512)
let radius: CGFloat = 200 // Reduced radius to fit inside corners
let startAngle: CGFloat = -30
let endAngle: CGFloat = 220

arrowPath.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
arrowPath.lineWidth = 70
arrowPath.lineCapStyle = .round
arrowPath.stroke()

// 4. Arrow Head (Classic & Aligned)
let endRad = endAngle * .pi / 180.0
let tip = CGPoint(
    x: center.x + radius * cos(endRad),
    y: center.y + radius * sin(endRad)
)
let tangent = endAngle + 90

let headPath = NSBezierPath()
// Classic Triangular Arrowhead
headPath.move(to: CGPoint(x: 0, y: 0))      // Tip
headPath.line(to: CGPoint(x: -120, y: 100)) // Top Back
headPath.line(to: CGPoint(x: -80, y: 0))    // Center Back (Slight indent)
headPath.line(to: CGPoint(x: -120, y: -100))// Bottom Back
headPath.close()

var transform = AffineTransform()
// Move to the end of the arc
transform.translate(x: tip.x, y: tip.y)
// Rotate to tangent
transform.rotate(byDegrees: tangent)
// Push FORWARD slightly (55px) along the tangent to extend past the round cap.
// 35px is flush with cap (70/2), 55px pushes it out to the "corner".
transform.translate(x: 55, y: 0)

headPath.transform(using: transform)
cyan.setFill()
headPath.fill()

image.unlockFocus()

// Export
if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "AppIcon.png"))
}
EOF

swiftc GenIcon.swift -o GenIcon
./GenIcon

# Generate Iconset
mkdir AppIcon.iconset
sips -z 16 16     AppIcon.png --out AppIcon.iconset/icon_16x16.png > /dev/null
sips -z 32 32     AppIcon.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null
sips -z 32 32     AppIcon.png --out AppIcon.iconset/icon_32x32.png > /dev/null
sips -z 64 64     AppIcon.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null
sips -z 128 128   AppIcon.png --out AppIcon.iconset/icon_128x128.png > /dev/null
sips -z 256 256   AppIcon.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null
sips -z 256 256   AppIcon.png --out AppIcon.iconset/icon_256x256.png > /dev/null
sips -z 512 512   AppIcon.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null
sips -z 512 512   AppIcon.png --out AppIcon.iconset/icon_512x512.png > /dev/null
sips -z 1024 1024 AppIcon.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null
iconutil -c icns AppIcon.iconset
) &
show_spinner $!
printf "   ${NEON_GREEN}✔ Assets Compiled (New Logo).${NC}\n\n"

# --- STEP 3: BUNDLE STRUCTURE ---
show_step 3 "Constructing Application Bundle..."
mkdir -p "$APP_NAME.app/Contents/MacOS"
mkdir -p "$APP_NAME.app/Contents/Resources"
mv AppIcon.icns "$APP_NAME.app/Contents/Resources/"

cat > "$APP_NAME.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SnapBack</string>
    <key>CFBundleIdentifier</key>
    <string>com.aoh.snapback</string>
    <key>CFBundleName</key>
    <string>__APP_NAME__</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>__APP_VERSION__</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>__APP_NAME__ needs to control other applications to save and restore window layouts.</string>
</dict>
</plist>
EOF

# Inject Version and Name into Info.plist
sed -i '' "s/__APP_VERSION__/$APP_VERSION/g" "$APP_NAME.app/Contents/Info.plist"
sed -i '' "s/__APP_NAME__/$APP_NAME/g" "$APP_NAME.app/Contents/Info.plist"

printf "   ${NEON_GREEN}✔ Info.plist injected.${NC}\n\n"

# --- STEP 4: SOURCE INJECTION ---
show_step 4 "Injecting Source Code..."
cat > SnapBack.swift <<'EOF'
import Cocoa
import SwiftUI

struct UpdateChangelogView: View {
    let changelog: String

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Text(changelog)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.primary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
        }
        .frame(width: 340, height: 140)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// --- CONFIGURATION ---
let appTitle = "__APP_NAME__"
let fileManager = FileManager.default
let home = fileManager.homeDirectoryForCurrentUser
let storageFolder = home.appendingPathComponent("Pictures/Snap Back Profiles")
try? fileManager.createDirectory(at: storageFolder, withIntermediateDirectories: true)

// --- HELPERS ---
func runShell(_ command: String) -> Int32 {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", command]
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func runAppleScript(_ source: String) -> (Bool, String?) {
    if let script = NSAppleScript(source: source) {
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let err = error {
            let msg = err["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
            return (false, msg)
        }
        let resString = result.stringValue
        return (true, resString)
    }
    return (false, "Failed to initialize NSAppleScript")
}

func getSavedProfiles() -> [String] {
    guard let items = try? fileManager.contentsOfDirectory(atPath: storageFolder.path) else { return [] }
    return items.filter { item in
        let path = storageFolder.appendingPathComponent(item)
        var isDir: ObjCBool = false
        return fileManager.fileExists(atPath: path.path, isDirectory: &isDir) && isDir.boolValue && !item.hasPrefix(".")
    }
}

func showSuccess(message: String) {
    NSSound(named: "Glass")?.play()
    let script = "display notification \"\(message)\" with title \"__APP_NAME__\""
    let _ = runAppleScript(script)
}

func showError(message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func showScriptError(details: String?) {
    let alert = NSAlert()
    alert.messageText = "Operation Failed"
    var info = "__APP_NAME__ encountered an error."
    if let d = details { info += "\n\nError: \(d)" }
    
    // Check for permissions
    let err = details?.lowercased() ?? ""
    let isPermissionIssue = err.contains("not allowed") || err.contains("not authorized") || err.contains("(-1743)")
    
    alert.informativeText = info
    
    if isPermissionIssue {
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
    } else {
        alert.addButton(withTitle: "OK")
    }
    
    let response = alert.runModal()
    
    if isPermissionIssue && response == .alertFirstButtonReturn {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        NSWorkspace.shared.open(url)
    }
}

func checkForUpdates(isManual: Bool = false) {
    let now = Date()
    if !isManual {
        if let lastCheck = UserDefaults.standard.object(forKey: "lastUpdateCheckDate") as? Date,
           now.timeIntervalSince(lastCheck) < 86400 {
            return // Only check once per 24 hours on automatic launch
        }
    }
    UserDefaults.standard.set(now, forKey: "lastUpdateCheckDate")

    URLCache.shared.removeAllCachedResponses()
    let ts = Int(now.timeIntervalSince1970)
    let versionURLStr = "https://raw.githubusercontent.com/arunofhyd/SnapBack/main/version.json?t=\(ts)"
    guard let url = URL(string: versionURLStr) else { return }
    var request = URLRequest(url: url)
    request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
    request.addValue("no-cache", forHTTPHeaderField: "Cache-Control")
    request.addValue("no-cache", forHTTPHeaderField: "Pragma")

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let remoteVer = json["version"] as? String,
              let currentVer = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else { return }

        let rComponents = remoteVer.split(separator: ".").compactMap { Int($0) }
        let cComponents = currentVer.split(separator: ".").compactMap { Int($0) }

        var updateAvailable = false
        for i in 0..<max(rComponents.count, cComponents.count) {
            let r = i < rComponents.count ? rComponents[i] : 0
            let c = i < cComponents.count ? cComponents[i] : 0
            if r > c { updateAvailable = true; break }
            if r < c { break }
        }

        if updateAvailable {
            var fullChangelog = ""
            if let changes = json["changelog"] as? [[String: Any]] {
                let unreadEntries = changes.filter { entry in
                    guard let v = (entry["version"] as? String)?.replacingOccurrences(of: "v", with: "") else { return false }
                    let rComp = v.split(separator: ".").compactMap { Int($0) }
                    let cComp = currentVer.split(separator: ".").compactMap { Int($0) }
                    for i in 0..<max(rComp.count, cComp.count) {
                        let r = i < rComp.count ? rComp[i] : 0
                        let c = i < cComp.count ? cComp[i] : 0
                        if r > c { return true }
                        if r < c { return false }
                    }
                    return false
                }
                fullChangelog = unreadEntries.compactMap { entry -> String? in
                    guard let v = entry["version"] as? String,
                          let notes = entry["changes"] as? [String] else { return nil }
                    let list = notes.map { "• \($0)" }.joined(separator: "\n")
                    return "Version \(v):\n\(list)"
                }.joined(separator: "\n\n")
            }
            
            DispatchQueue.main.async {
                let alert = NSAlert()
                NSApp.activate(ignoringOtherApps: true)
                alert.messageText = "SnapBack v\(remoteVer) is available"
                alert.informativeText = "You have v\(currentVer). Here's what's new:"
                
                if !fullChangelog.isEmpty {
                    let hosting = NSHostingView(rootView: UpdateChangelogView(changelog: fullChangelog))
                    hosting.frame = NSRect(x: 0, y: 0, width: 340, height: 140)
                    alert.accessoryView = hosting
                }
                
                alert.addButton(withTitle: "Update Now")
                alert.addButton(withTitle: "Later")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    downloadAndInstallUpdate()
                }
            }
        }
    }
    task.resume()
}

func downloadAndInstallUpdate() {
    let commandURL = "https://raw.githubusercontent.com/arunofhyd/SnapBack/refs/heads/main/install-snapback.command"
    guard let url = URL(string: commandURL) else { return }
    
    let task = URLSession.shared.downloadTask(with: url) { tempURL, _, error in
        DispatchQueue.main.async {
            if let error = error {
                let err = NSAlert()
                err.alertStyle = .warning
                err.messageText = "Download Failed"
                err.informativeText = "Could not download the update:\n\(error.localizedDescription)\n\nPlease check your internet connection and try again."
                err.addButton(withTitle: "OK")
                err.runModal()
                return
            }
            
            guard let tempURL = tempURL else { return }
            
            let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let destURL = downloadsDir.appendingPathComponent("install-snapback.command")
            
            try? FileManager.default.removeItem(at: destURL)
            do {
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                try FileManager.default.setAttributes(
                    [.posixPermissions: NSNumber(value: 0o755)],
                    ofItemAtPath: destURL.path
                )
                NSWorkspace.shared.open(destURL)
            } catch {
                let err = NSAlert()
                err.alertStyle = .warning
                err.messageText = "Could Not Save Installer"
                err.informativeText = "The installer was downloaded but couldn't be saved:\n\(error.localizedDescription)"
                err.addButton(withTitle: "OK")
                err.runModal()
            }
        }
    }
    task.resume()
}

func checkFirstRun() {
    let key = "HasShownFirstRunPermissions"
    let defaults = UserDefaults.standard
    
    // Check permissions first - if all good, set flag and skip
    let axTrusted = AXIsProcessTrusted()
    var screenTrusted = false
    if #available(macOS 10.15, *) {
        screenTrusted = CGPreflightScreenCaptureAccess()
    } else {
        screenTrusted = true // Fallback for older macOS
    }
    
    if axTrusted && screenTrusted {
        defaults.set(true, forKey: key)
        return
    }
    
    // Show window if permissions are missing OR flag is not set (enforce permissions)
    if !axTrusted || !screenTrusted || !defaults.bool(forKey: key) {
        
        // Custom Window for Timer Logic - RESIZED for better fit
        let winWidth: CGFloat = 480
        let winHeight: CGFloat = 400
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: winWidth, height: winHeight),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "__APP_NAME__"
        
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: winWidth, height: winHeight))
        window.contentView = contentView
        
        // Icon (Top Left)
        let iconView = NSImageView(frame: NSRect(x: 30, y: winHeight - 85, width: 64, height: 64))
        iconView.image = NSApplication.shared.applicationIconImage
        contentView.addSubview(iconView)
        
        // Title (Right of Icon)
        let titleLabel = NSTextField(labelWithString: "Welcome to __APP_NAME__")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 110, y: winHeight - 65, width: 350, height: 26)
        contentView.addSubview(titleLabel)
        
        // Description (Main Body)
        let descLabel = NSTextField(labelWithString: "")
        descLabel.stringValue = "To save and restore window layouts, this app requires:\n\n• Accessibility: To move/resize windows.\n• Screen Recording: To capture layout previews.\n\nPlease enable these in System Settings (requires Admin privileges).\n\n⚠️ If already checked: Please remove (-) and re-add (+) __APP_NAME__ in System Settings under Accessibility and Screen Recording to reset permissions after an app update."
        descLabel.font = NSFont.systemFont(ofSize: 13)
        // Adjusted Frame to fit text without clipping
        descLabel.frame = NSRect(x: 35, y: 110, width: 420, height: 190)
        descLabel.cell?.wraps = true
        contentView.addSubview(descLabel)
        
        // Buttons
        let btnWidth: CGFloat = 200
        let btnHeight: CGFloat = 32
        
        let accessBtn = NSButton(title: "Open Accessibility", target: nil, action: nil)
        accessBtn.frame = NSRect(x: 35, y: 65, width: btnWidth, height: btnHeight)
        accessBtn.bezelStyle = .rounded
        
        let screenBtn = NSButton(title: "Open Screen Recording", target: nil, action: nil)
        screenBtn.frame = NSRect(x: 250, y: 65, width: btnWidth, height: btnHeight)
        screenBtn.bezelStyle = .rounded
        
        let quitBtn = NSButton(title: "Quit App", target: nil, action: nil)
        quitBtn.frame = NSRect(x: 35, y: 20, width: 100, height: btnHeight)
        quitBtn.bezelStyle = .rounded
        
        let continueBtn = NSButton(title: "Continue", target: nil, action: nil)
        continueBtn.frame = NSRect(x: 350, y: 20, width: 100, height: btnHeight)
        continueBtn.bezelStyle = .rounded
        continueBtn.isEnabled = false
        
        contentView.addSubview(accessBtn)
        contentView.addSubview(screenBtn)
        contentView.addSubview(quitBtn)
        contentView.addSubview(continueBtn)
        
        // Logic Class
        class FirstRunHandler: NSObject {
            var timer: Timer?
            var window: NSWindow
            var continueBtn: NSButton
            var accessBtn: NSButton
            var screenBtn: NSButton
            
            init(window: NSWindow, continueBtn: NSButton, accessBtn: NSButton, screenBtn: NSButton) {
                self.window = window
                self.continueBtn = continueBtn
                self.accessBtn = accessBtn
                self.screenBtn = screenBtn
                super.init()
                
                // IMPORTANT: Add timer to common mode to ensure it fires during modal run loop
                let t = Timer(timeInterval: 1.0, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
                RunLoop.current.add(t, forMode: .common)
                self.timer = t
                
                self.checkPermissions() // Initial check
            }
            
            @objc func tick() {
                // Poll permissions every second
                let allEnabled = checkPermissions()
                
                if allEnabled {
                    continueBtn.isEnabled = true
                } else {
                    continueBtn.isEnabled = false
                }
            }
            
            @discardableResult
            func checkPermissions() -> Bool {
                var axOk = false
                var screenOk = false
                
                // Check Accessibility
                if AXIsProcessTrusted() {
                    axOk = true
                    accessBtn.title = "Accessibility: Enabled ✅"
                    // accessBtn.bezelColor = NSColor.systemGreen 
                    // Note: bezelColor might not show on all button styles, title update is safer
                    accessBtn.isEnabled = false
                } else {
                     accessBtn.title = "Open Accessibility"
                     accessBtn.isEnabled = true
                }

                // Check Screen Recording
                if #available(macOS 10.15, *) {
                    if CGPreflightScreenCaptureAccess() {
                        screenOk = true
                        screenBtn.title = "Screen Rec: Enabled ✅"
                        screenBtn.isEnabled = false
                    } else {
                         screenBtn.title = "Open Screen Recording"
                         screenBtn.isEnabled = true
                    }
                } else { screenOk = true }
                
                return axOk && screenOk
            }
            
            @objc func openAccess(_ sender: Any) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            @objc func openScreen(_ sender: Any) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            @objc func continueClicked(_ sender: Any) {
                timer?.invalidate()
                NSApplication.shared.stopModal()
                window.close()
            }
            
            @objc func quitClicked(_ sender: Any) {
                exit(0)
            }
        }
        
        let frHandler = FirstRunHandler(window: window, continueBtn: continueBtn, accessBtn: accessBtn, screenBtn: screenBtn)
        accessBtn.target = frHandler; accessBtn.action = #selector(FirstRunHandler.openAccess(_:))
        screenBtn.target = frHandler; screenBtn.action = #selector(FirstRunHandler.openScreen(_:))
        continueBtn.target = frHandler; continueBtn.action = #selector(FirstRunHandler.continueClicked(_:))
        quitBtn.target = frHandler; quitBtn.action = #selector(FirstRunHandler.quitClicked(_:))
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApplication.shared.runModal(for: window)
        
        // Only set flag if we actually passed the checks (which we did if we are here)
        defaults.set(true, forKey: key)
    }
}

func showHelp() {
    let alert = NSAlert()
    alert.messageText = "How to Use __APP_NAME__"
    
    let helpViewWidth: CGFloat = 520
    let helpViewHeight: CGFloat = 430
    let helpContainer = NSView(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    
    let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    scrollView.hasVerticalScroller = true
    scrollView.drawsBackground = false
    
    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: helpViewWidth - 15, height: helpViewHeight))
    textView.isEditable = false
    textView.isRichText = true
    textView.drawsBackground = false
    textView.textContainer?.lineFragmentPadding = 0
    
    let headerFont = NSFont.boldSystemFont(ofSize: 14)
    let bodyFont = NSFont.systemFont(ofSize: 13)
    let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    
    let headerStyle = NSMutableParagraphStyle()
    headerStyle.paragraphSpacing = 6
    headerStyle.paragraphSpacingBefore = 12
    
    let bodyStyle = NSMutableParagraphStyle()
    bodyStyle.paragraphSpacing = 20
    bodyStyle.lineHeightMultiple = 1.2
    
    let centerStyle = NSMutableParagraphStyle()
    centerStyle.alignment = .center
    centerStyle.paragraphSpacingBefore = 40
    
    let linkStyle = NSMutableParagraphStyle()
    linkStyle.alignment = .center
    linkStyle.paragraphSpacingBefore = 2
    
    let content = NSMutableAttributedString()
    
    func addHeader(_ text: String, icon: String? = nil) {
        let titleText = icon != nil ? "\(icon!)  \(text)" : text
        content.append(NSAttributedString(string: titleText + "\n", attributes: [
            .font: headerFont, 
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: headerStyle
        ]))
    }
    
    func addBody(_ text: String) {
        content.append(NSAttributedString(string: text + "\n", attributes: [
            .font: bodyFont, 
            .foregroundColor: NSColor.labelColor, 
            .paragraphStyle: bodyStyle
        ]))
    }
    
    func addDetailedItem(_ title: String, _ items: [String]) {
        content.append(NSAttributedString(string: title + "\n", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 13),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: bodyStyle
        ]))
        
        let listStyle = NSMutableParagraphStyle()
        listStyle.paragraphSpacing = 4
        listStyle.headIndent = 15
        
        for item in items {
             content.append(NSAttributedString(string: item + "\n", attributes: [
                .font: NSFont.systemFont(ofSize: 12),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: listStyle
            ]))
        }
        content.append(NSAttributedString(string: "\n", attributes: [.font: NSFont.systemFont(ofSize: 8)]))
    }
    
    // --- AUTHOR & LINK SECTION ---
    content.append(NSAttributedString(string: "      by Arun Thomas\n", attributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: centerStyle
    ]))
    
    content.append(NSAttributedString(string: "For updates visit : ", attributes: [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: linkStyle
    ]))

    content.append(NSAttributedString(string: "snapbackapp.vercel.app\n\n", attributes: [
        .font: NSFont.systemFont(ofSize: 11),
        .foregroundColor: NSColor.linkColor,
        .link: URL(string: "https://snapbackapp.vercel.app")!,
        .paragraphStyle: linkStyle
    ]))
    // ----------------------------

addHeader("Required Permissions", icon: "🔐")
    addBody("Ensure these are enabled in System Settings:")
    
    addDetailedItem("1. Accessibility", [
        "- Required to move and resize windows.",
        "- Go to Privacy & Security > Accessibility.",
        "- Click '+' (or allow in list) to add '__APP_NAME__'."
    ])
    
    addDetailedItem("2. Screen Recording", [
        "- Required to save screenshot previews.",
        "- Go to Privacy & Security > Screen Recording.",
        "- Click '+' (or allow in list) to add '__APP_NAME__'."
    ])
    
    addDetailedItem("3. Automation", [
        "- Required to control Browser tabs/ Apps.",
        "- Accept the system prompt when it appears."
    ])
    
    addHeader("Troubleshooting", icon: "🛠")
    addBody("If a window fails to move, remove __APP_NAME__ from Privacy & Security settings and re-add it to reset permissions.")
    addHeader("Capture State", icon: "📸")
    addBody("Click 'Save New...' to instantly record the geometry & state of any open app window and browser tab. This tool is designed for Power Users.")
    
    addHeader("Restore Layout", icon: "⚡️")
    addBody("Select a profile and click 'Restore'. Windows snap to their grid coordinates; URLs reload automatically.")
    
    addHeader("File Management", icon: "📂")
    addBody("Profiles are stored locally. You can rename or delete them directly via folder icon in app, or find them using Finder at:")
    content.append(NSAttributedString(string: "~/Pictures/Snap Back Profiles\n", attributes: [
        .font: codeFont,
        .foregroundColor: NSColor.labelColor,
        .paragraphStyle: bodyStyle
    ]))

    textView.textStorage?.setAttributedString(content)
    
    scrollView.documentView = textView
    helpContainer.addSubview(scrollView)
    
    alert.accessoryView = helpContainer
    alert.addButton(withTitle: "Got it")
    alert.addButton(withTitle: "Open Permissions")
    alert.addButton(withTitle: "Contact Developer")
    
    let response = alert.runModal()
    
    if response == .alertSecondButtonReturn {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    } else if response == .alertThirdButtonReturn {
        if let url = URL(string: "mailto:arunthomas04042001@gmail.com") {
            NSWorkspace.shared.open(url)
        }
    }
}

func deleteProfile(name: String) -> Bool {
    let profileDir = storageFolder.appendingPathComponent(name)
    do {
        if fileManager.fileExists(atPath: profileDir.path) {
            try fileManager.removeItem(at: profileDir)
            return true
        }
        return false
    } catch { return false }
}

// --- CORE LOGIC ---
func saveProfile(name: String) -> Bool {
    let profileDir = storageFolder.appendingPathComponent(name)
    try? fileManager.createDirectory(at: profileDir, withIntermediateDirectories: true)
    
    let dataFile = profileDir.appendingPathComponent("data.scpt")
    let imgFile = profileDir.appendingPathComponent("preview.jpg") 
    
    let status = runShell("screencapture -x -t jpg \"\(imgFile.path)\"")
    if status != 0 { showError(message: "Screenshot failed. Check permissions."); return false }

    // UPGRADE: Handlers with strict 'using terms from' to fix identifier errors
    let script = #"""
    script DataCarrier
        property mainData : {}
    end script
    
    -- HANDLERS
    on getSafariUrls(winIdx)
        set uList to {}
        try
            tell application "Safari"
                if (count of windows) >= winIdx then
                    set tabList to every tab of window winIdx
                    repeat with t in tabList
                        set end of uList to (get URL of t)
                    end repeat
                end if
            end tell
        end try
        return uList
    end getSafariUrls

    on getChromeUrls(theApp, winIdx)
        try
            set scriptSrc to "on run {wIdx}" & return
            set scriptSrc to scriptSrc & "tell application \"" & theApp & "\"" & return
            set scriptSrc to scriptSrc & "set uList to {}" & return
            set scriptSrc to scriptSrc & "if (count of windows) >= wIdx then" & return
            set scriptSrc to scriptSrc & "tell window wIdx" & return
            set scriptSrc to scriptSrc & "set tabList to every tab" & return
            set scriptSrc to scriptSrc & "repeat with t in tabList" & return
            set scriptSrc to scriptSrc & "set end of uList to (URL of t)" & return
            set scriptSrc to scriptSrc & "end repeat" & return
            set scriptSrc to scriptSrc & "end tell" & return
            set scriptSrc to scriptSrc & "end if" & return
            set scriptSrc to scriptSrc & "return uList" & return
            set scriptSrc to scriptSrc & "end tell" & return
            set scriptSrc to scriptSrc & "end run"
            return run script scriptSrc with parameters {winIdx}
        on error
            return {}
        end try
    end getChromeUrls
    
    set thePath to "\#(dataFile.path)"
    
    set chromiumVariants to {"Google Chrome", "Brave Browser", "Microsoft Edge", "Arc", "Vivaldi", "Opera"}
    
    tell application "Finder" to set screenBounds to bounds of window of desktop
    set screenW to item 3 of screenBounds
    set screenH to item 4 of screenBounds

    tell application "System Events"
        set processList to (every process where background only is false)
        repeat with proc in processList
            try
                set appName to name of proc
                if appName is not "__APP_NAME__" and appName is not "app_mode_loader" and appName is not "ControlCenter" then
                    tell proc
                        set allWindows to every window
                        repeat with i from 1 to count of allWindows
                            set thisWindow to item i of allWindows
                            
                            set wPos to position of thisWindow
                            set wSize to size of thisWindow
                            set absX to item 1 of wPos
                            set absY to item 2 of wPos
                            set absW to item 1 of wSize
                            set absH to item 2 of wSize
                            
                            set relX to absX / screenW
                            set relY to absY / screenH
                            set relW to absW / screenW
                            set relH to absH / screenH
                            
                            set wUrls to {}
                            
                            if appName is "Safari" then
                                set wUrls to my getSafariUrls(i)
                            else if appName is in chromiumVariants then
                                set wUrls to my getChromeUrls(appName, i)
                            else if appName is "Firefox" then
                                try
                                    set rawUrl to value of attribute "AXValue" of combo box 1 of toolbar "Navigation" of thisWindow
                                    if rawUrl starts with "http" then set end of wUrls to rawUrl
                                end try
                            end if
                            
                            set end of mainData of DataCarrier to {procName:appName, winIndex:i, relPos:{relX, relY}, relSize:{relW, relH}, savedUrls:wUrls}
                        end repeat
                    end tell
                end if
            end try
        end repeat
    end tell
    set theFile to POSIX file thePath
    store script DataCarrier in theFile replacing yes
    """#
    let (success, errorMsg) = runAppleScript(script)
    if success { return true }
    else { showScriptError(details: errorMsg); return false }
}

func restoreProfile(name: String) {
    let profileDir = storageFolder.appendingPathComponent(name)
    let dataFile = profileDir.appendingPathComponent("data.scpt")
    
    let script = #"""
    set theFile to POSIX file "\#(dataFile.path)"
    set chromiumVariants to {"Google Chrome", "Brave Browser", "Microsoft Edge", "Arc", "Vivaldi", "Opera"}
    
    -- HANDLERS FOR RESTORE (Isolates Dictionaries)
    on restoreSafari(urlList)
        try
            tell application "Safari"
                set shouldReuse to false
                if (count of windows) = 0 then
                    make new document
                    set shouldReuse to true
                else if (count of windows) = 1 then
                     try
                        if not (exists URL of document 1) or (URL of document 1 is "") then set shouldReuse to true
                     end try
                end if
                
                if not shouldReuse then make new document
                
                if (count of urlList) > 0 then
                    set URL of document 1 to (item 1 of urlList)
                    if (count of urlList) > 1 then
                        repeat with k from 2 to count of urlList
                            tell window 1 to make new tab with properties {URL:(item k of urlList)}
                        end repeat
                    end if
                end if
            end tell
        end try
    end restoreSafari

    on restoreChrome(theApp, urlList)
        try
            set scriptSrc to "on run {urls}" & return & "tell application \"" & theApp & "\"" & return
            set scriptSrc to scriptSrc & "if (count of urls) > 0 then" & return
            set scriptSrc to scriptSrc & "set reuse to false" & return
            set scriptSrc to scriptSrc & "if (count of windows) = 1 and (count of tabs of window 1) = 1 then" & return
            set scriptSrc to scriptSrc & "set u to URL of active tab of window 1" & return
            set scriptSrc to scriptSrc & "if u is \"\" or u starts with \"chrome://\" then set reuse to true" & return
            set scriptSrc to scriptSrc & "end if" & return
            set scriptSrc to scriptSrc & "if not reuse then make new window" & return
            set scriptSrc to scriptSrc & "set URL of active tab of window 1 to (item 1 of urls)" & return
            set scriptSrc to scriptSrc & "if (count of urls) > 1 then" & return
            set scriptSrc to scriptSrc & "repeat with k from 2 to count of urls" & return
            set scriptSrc to scriptSrc & "make new tab at end of tabs of window 1 with properties {URL:(item k of urls)}" & return
            set scriptSrc to scriptSrc & "end repeat" & return
            set scriptSrc to scriptSrc & "end if" & return
            set scriptSrc to scriptSrc & "end if" & return
            set scriptSrc to scriptSrc & "end tell" & return
            set scriptSrc to scriptSrc & "end run"
            run script scriptSrc with parameters {urlList}
        end try
    end restoreChrome
    
    on restoreFirefox(theApp, urlList)
        try
            tell application theApp
                if (count of urlList) > 0 then
                    repeat with k from 1 to count of urlList
                        open location (item k of urlList)
                        delay 0.2
                    end repeat
                end if
            end tell
        end try
    end restoreFirefox

    try
        set loadedScript to load script theFile
        set windowPositions to mainData of loadedScript
        
        tell application "System Events"
            set visible of (every process where visible is true and name is not "__APP_NAME__") to false
        end tell
        delay 0.5
        
        tell application "Finder" to set screenBounds to bounds of window of desktop
        set screenW to item 3 of screenBounds
        set screenH to item 4 of screenBounds
        
        -- MERGED RESTORATION LOOP
        repeat with winRecord in windowPositions
            set appName to procName of winRecord
            set urlList to savedUrls of winRecord
            set rawIndex to winIndex of winRecord
            
            -- Geometry Calcs
            set relPos to relPos of winRecord
            set relSize to relSize of winRecord
            set relX to item 1 of relPos
            set relY to item 2 of relPos
            set relW to item 1 of relSize
            set relH to item 2 of relSize
            
            set targetX to (relX * screenW)
            set targetY to (relY * screenH)
            set targetW to (relW * screenW)
            set targetH to (relH * screenH)
            
            if targetX < 0 then set targetX to 0
            if targetY < 0 then set targetY to 25
            
            set targetPos to {targetX, targetY}
            set targetSize to {targetW, targetH}
            
            try
                -- 1. Activate & Restore Content
                tell application appName to activate
                delay 0.2
                
                if appName is "Safari" then
                      my restoreSafari(urlList)
                      delay 0.5 -- Allow window creation
                else if appName is in chromiumVariants then
                      my restoreChrome(appName, urlList)
                      delay 0.5
                else if appName is "Firefox" then
                      my restoreFirefox(appName, urlList)
                      delay 0.5
                else
                      -- Generic App: Just wait
                      delay 0.2
                end if
                
                -- 2. Restore Geometry
                tell application "System Events" to tell process appName
                    set targetIndex to rawIndex
                    -- For browsers, target the frontmost window (Window 1) as we just created/touched it
                    if (appName is "Safari" or appName is "Firefox" or appName is in chromiumVariants) then set targetIndex to 1
                    
                    repeat 3 times
                        if (count of windows) >= targetIndex then
                            set position of window targetIndex to targetPos
                            set size of window targetIndex to targetSize
                            exit repeat
                        end if
                        delay 0.2
                    end repeat
                end tell
            end try
        end repeat
    end try
    """#
    let (success, errorMsg) = runAppleScript(script)
    if !success { 
        showScriptError(details: errorMsg) 
    } else {
        showSuccess(message: "Restored!")
    }
}

// --- UI SETUP (PRESERVED) ---
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let alert = NSAlert()
alert.messageText = "\(appTitle) v__APP_VERSION__"
alert.informativeText = "Instantly save and restore your workspace, Never lose your layout again."
alert.addButton(withTitle: "Restore")
alert.addButton(withTitle: "Save New...")
alert.addButton(withTitle: "Close")
alert.addButton(withTitle: "Help")

if alert.buttons.count > 2 {
    alert.buttons[2].keyEquivalent = "\u{1b}"
}

let viewWidth: CGFloat = 450
let viewHeight: CGFloat = 300
let container = NSView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight))

let dropdown = NSPopUpButton(frame: NSRect(x: 0, y: 260, width: 300, height: 25))
let revealBtn = NSButton(frame: NSRect(x: 310, y: 260, width: 40, height: 25))
revealBtn.title = "📂"
revealBtn.bezelStyle = .rounded
revealBtn.toolTip = "Reveal Profiles in Finder"

let deleteBtn = NSButton(frame: NSRect(x: 360, y: 260, width: 80, height: 25))
deleteBtn.title = "Delete"; deleteBtn.bezelStyle = .rounded

// --- ADAPTIVE FRAME LOGIC ---
let maxW: CGFloat = 450
let maxH: CGFloat = 250
let imgContainer = NSView(frame: NSRect(x: 0, y: 0, width: maxW, height: maxH)) 
imgContainer.wantsLayer = true
imgContainer.layer?.borderWidth = 1.0
imgContainer.layer?.borderColor = NSColor.clear.cgColor 
imgContainer.layer?.cornerRadius = 6.0

let gap: CGFloat = 4
let imgView = NSImageView(frame: NSRect(x: gap, y: gap, width: maxW - (gap*2), height: maxH - (gap*2)))
imgView.imageScaling = .scaleAxesIndependently 
imgView.imageFrameStyle = .none
imgView.wantsLayer = true
imgView.layer?.cornerRadius = 4.0
imgView.layer?.masksToBounds = true
imgContainer.addSubview(imgView)

// --- HANDLERS ---
func refreshList() {
    let profiles = getSavedProfiles()
    dropdown.removeAllItems()
    dropdown.addItems(withTitles: profiles)
    if profiles.isEmpty { dropdown.addItem(withTitle: "No Profiles Found"); deleteBtn.isEnabled = false }
    else { deleteBtn.isEnabled = true }
    updateImage()
}

func updateImage() {
    guard let selected = dropdown.titleOfSelectedItem else { 
        imgView.image = nil
        imgContainer.layer?.borderColor = NSColor.clear.cgColor 
        return 
    }
    let profileDir = storageFolder.appendingPathComponent(selected)
    let imgPath = profileDir.appendingPathComponent("preview.jpg")
    
    if fileManager.fileExists(atPath: imgPath.path), let img = NSImage(contentsOf: imgPath) {
        imgView.image = img
        imgContainer.layer?.borderColor = NSColor.tertiaryLabelColor.cgColor
        let imgSize = img.size
        let ratio = imgSize.width / imgSize.height
        var targetW = maxW
        var targetH = maxW / ratio
        if targetH > maxH {
            targetH = maxH
            targetW = maxH * ratio
        }
        imgContainer.frame = NSRect(x: (viewWidth - targetW) / 2, y: (maxH - targetH) / 2, width: targetW, height: targetH)
        imgView.frame = NSRect(x: gap, y: gap, width: targetW - (gap*2), height: targetH - (gap*2))
    } else { 
        imgView.image = nil
        imgContainer.layer?.borderColor = NSColor.clear.cgColor 
    }
}

class UIHandler: NSObject {
    @objc func dropdownChanged(_ sender: Any) { updateImage() }
    @objc func deleteClicked(_ sender: Any) {
        guard let name = dropdown.titleOfSelectedItem, name != "No Profiles Found" else { return }
        let confirm = NSAlert()
        confirm.messageText = "Delete '\(name)'?"; confirm.addButton(withTitle: "Delete"); confirm.addButton(withTitle: "Cancel")
        if confirm.runModal() == .alertFirstButtonReturn { if deleteProfile(name: name) { refreshList() } }
    }
    @objc func revealClicked(_ sender: Any) {
        NSWorkspace.shared.activateFileViewerSelecting([storageFolder])
    }
}
let handler = UIHandler()
dropdown.target = handler; dropdown.action = #selector(UIHandler.dropdownChanged(_:))
deleteBtn.target = handler; deleteBtn.action = #selector(UIHandler.deleteClicked(_:))
revealBtn.target = handler; revealBtn.action = #selector(UIHandler.revealClicked(_:))

refreshList()

container.addSubview(dropdown)
container.addSubview(revealBtn)
container.addSubview(deleteBtn)
container.addSubview(imgContainer)

alert.accessoryView = container

app.finishLaunching()
app.activate(ignoringOtherApps: true)

checkFirstRun()
checkForUpdates()

// --- LOOP ---
while true {
    let response = alert.runModal()
    if response == .alertFirstButtonReturn { // Restore
        if let name = dropdown.titleOfSelectedItem, name != "No Profiles Found" { 
            restoreProfile(name: name)
            Thread.sleep(forTimeInterval: 1.0)
            exit(0)
        }
    } else if response == .alertSecondButtonReturn { // Save
        while true {
            let nameAlert = NSAlert()
            nameAlert.messageText = "Name Profile"; nameAlert.addButton(withTitle: "Save"); nameAlert.addButton(withTitle: "Cancel")
            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            nameAlert.accessoryView = input
            if nameAlert.runModal() == .alertFirstButtonReturn {
                let newName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if newName.isEmpty { continue }
                let existing = getSavedProfiles().map { $0.lowercased() }
                
                if existing.contains(newName.lowercased()) {
                    let dup = NSAlert()
                    dup.messageText = "Replace '\(newName)'?"
                    dup.informativeText = "This will overwrite the existing profile."
                    dup.addButton(withTitle: "Replace")
                    dup.addButton(withTitle: "Cancel")
                    if dup.runModal() == .alertSecondButtonReturn { continue }
                }
                
                if saveProfile(name: newName) { 
                    showSuccess(message: "Saved!")
                    refreshList() 
                    break
                } else { break }
            } else { break }
        }
    } else if response == .alertThirdButtonReturn { exit(0) }
    else { showHelp() }
}
EOF

# Inject Version and Name into Swift Source
sed -i '' "s/__APP_VERSION__/$APP_VERSION/g" SnapBack.swift
sed -i '' "s/__APP_NAME__/$APP_NAME/g" SnapBack.swift

printf "   ${NEON_GREEN}✔ Core Logic Integrated.${NC}\n\n"

# --- STEP 5: COMPILATION & CLEANUP ---
show_step 5 "Compiling Binary Executable..."

(
swiftc SnapBack.swift -o "$APP_NAME.app/Contents/MacOS/SnapBack"
) &
show_spinner $!

if [ $? -eq 0 ]; then
    printf "   ${NEON_GREEN}✔ Compilation Complete.${NC}\n\n"
    
    show_step 6 "Finalizing and Signing..."
    
    # Ensure binary is executable
    chmod +x "$APP_NAME.app/Contents/MacOS/SnapBack"
    chmod +x "$APP_NAME.app/Contents/Resources"
    
    # --- Ad-Hoc Signing ---
    printf "   ${TXT_GREY}Applying local signature...${NC} "
    codesign --force --deep -s - --requirements '=designated => identifier "com.aoh.snapback"' "$APP_NAME.app" &>/dev/null
    printf "${NEON_GREEN}Secure.${NC}\n"
    
    # --- STEP 6: DIRECT AUTO-INSTALL OR FALLBACK ---
    show_step 6 "Installing Snap Back to /Applications..."
    
    DEST="/Applications/$APP_NAME.app"
    pkill -x "$APP_NAME" >/dev/null 2>&1 || true
    INSTALLED=false

    if [ "$FORCE_MODAL" = "1" ] || [ "$1" = "--modal" ] || [ "$1" = "--gui" ] || [ "$2" = "--modal" ]; then
        INSTALLED=false
    elif [ -w "/Applications" ]; then
        rm -rf "$DEST" 2>/dev/null || true
        if cp -R "$APP_NAME.app" "$DEST" 2>/dev/null; then
            INSTALLED=true
        fi
    fi

    if [ "$INSTALLED" = "true" ]; then
        xattr -dr com.apple.quarantine "$DEST" >/dev/null 2>&1 || true
        printf "   ${NEON_GREEN}✔ Snap Back installed to /Applications.${NC}\n\n"
        print_line
        show_success_art
        print_line
        printf "\n"
        printf "   ${NEON_CYAN}DEPLOYMENT COMPLETE:${NC} $APP_NAME (v$APP_VERSION) is now running in your menu bar.\n"
        open "$DEST"
        afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
        popd > /dev/null
        rm -rf "$BUILD_DIR"
        exit 0
    fi

    # Fallback to Drag Window
    cat > Installer.swift <<'EOF'
import Cocoa
import QuartzCore

class DraggableIconView: NSImageView, NSDraggingSource {
    var fileURL: URL?

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    override func mouseDown(with event: NSEvent) {
        guard let url = fileURL, let originalImg = self.image else { return }
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(url.path, forType: .fileURL)
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        let dragRect = self.bounds
        
        let dragImg = NSImage(size: bounds.size)
        dragImg.lockFocus()
        if let ctx = NSGraphicsContext.current {
            ctx.imageInterpolation = .high
        }
        originalImg.draw(in: bounds)
        dragImg.unlockFocus()

        draggingItem.setDraggingFrame(dragRect, contents: dragImg)
        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

class DropTargetView: NSImageView {
    override func awakeFromNib() { registerForDraggedTypes([.fileURL]) }
    override init(frame frameRect: NSRect) { super.init(frame: frameRect); registerForDraggedTypes([.fileURL]) }
    required init?(coder: NSCoder) { super.init(coder: coder); registerForDraggedTypes([.fileURL]) }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let board = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String else { return false }
        let sourceURL = URL(fileURLWithPath: board)
        let appName = sourceURL.lastPathComponent
        let destURL = URL(fileURLWithPath: "/Applications").appendingPathComponent(appName)
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            let clean = Process()
            clean.launchPath = "/usr/bin/xattr"
            clean.arguments = ["-dr", "com.apple.quarantine", destURL.path]
            clean.standardOutput = Pipe(); clean.standardError = Pipe()
            try? clean.run(); clean.waitUntilExit()
            
            NSSound(named: "Glass")?.play()
            let alert = NSAlert()
            alert.messageText = "Installation Successful"
            alert.informativeText = "Snap Back has been installed to Applications."
            alert.addButton(withTitle: "Launch App")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(destURL)
            }
            NSApplication.shared.terminate(nil)
        } catch {
            let script = "do shell script \"cp -R '\(sourceURL.path)' /Applications/\" with administrator privileges"
            var errorDict: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&errorDict)
                if errorDict == nil {
                    NSWorkspace.shared.open(destURL)
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        return true
    }
}

class InstallerWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable], backing: backingStoreType, defer: flag)
        self.title = "__APP_NAME__ v__APP_VERSION__"
        self.center()
        self.backgroundColor = NSColor(white: 0.15, alpha: 1.0)
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let winW: CGFloat = 600, winH: CGFloat = 350
let window = InstallerWindow(contentRect: NSRect(x: 0, y: 0, width: winW, height: winH), styleMask: [.titled, .closable], backing: .buffered, defer: false)

let iconSize: CGFloat = 128
let appIconView = DraggableIconView(frame: NSRect(x: 80, y: (winH - iconSize)/2 + 20, width: iconSize, height: iconSize))
let appPath = Bundle.main.bundlePath.replacingOccurrences(of: "Install __APP_NAME__.app", with: "__APP_NAME__.app")
if let image = NSImage(contentsOfFile: appPath + "/Contents/Resources/AppIcon.icns") {
    appIconView.image = image
}
appIconView.fileURL = URL(fileURLWithPath: appPath)
appIconView.imageScaling = .scaleProportionallyUpOrDown
window.contentView?.addSubview(appIconView)

let folderIconView = DropTargetView(frame: NSRect(x: winW - 80 - iconSize, y: (winH - iconSize)/2 + 20, width: iconSize, height: iconSize))
folderIconView.image = NSWorkspace.shared.icon(forFile: "/Applications")
folderIconView.imageScaling = .scaleProportionallyUpOrDown
window.contentView?.addSubview(folderIconView)

let label = NSTextField(labelWithString: "Drag Snap Back to Applications or click Instant Install below")
label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
label.textColor = NSColor.secondaryLabelColor
label.sizeToFit()
label.frame.origin.x = (winW - label.frame.width) / 2
label.frame.origin.y = 65
window.contentView?.addSubview(label)

class InstallerActionTarget: NSObject {
    @objc static func oneClickInstall() {
        let sourceURL = URL(fileURLWithPath: Bundle.main.bundlePath.replacingOccurrences(of: "Install __APP_NAME__.app", with: "__APP_NAME__.app"))
        let destURL = URL(fileURLWithPath: "/Applications/__APP_NAME__.app")
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            let clean = Process()
            clean.launchPath = "/usr/bin/xattr"
            clean.arguments = ["-dr", "com.apple.quarantine", destURL.path]
            clean.standardOutput = Pipe(); clean.standardError = Pipe()
            try? clean.run(); clean.waitUntilExit()
            
            NSSound(named: "Glass")?.play()
            let alert = NSAlert()
            alert.messageText = "Installation Successful"
            alert.informativeText = "Snap Back has been installed to Applications."
            alert.addButton(withTitle: "Launch App")
            alert.addButton(withTitle: "Quit")
            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(destURL)
            }
            NSApplication.shared.terminate(nil)
        } catch {
            let sanitizedPath = sourceURL.path.replacingOccurrences(of: "'", with: "'\\''")
            let script = "do shell script \"cp -R '\(sanitizedPath)' /Applications/\" with administrator privileges"
            var errorDict: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&errorDict)
                if errorDict == nil {
                    NSWorkspace.shared.open(destURL)
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }
}

class AnimatedInstallButton: NSButton {
    private var trackingArea: NSTrackingArea?
    private var isHovered = false { didSet { animateState() } }
    private var isPressed = false { didSet { animateState() } }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    private func setup() {
        wantsLayer = true
        isBordered = false
        focusRingType = .none
        layer?.cornerRadius = 10
        layer?.backgroundColor = NSColor.systemBlue.cgColor
        contentTintColor = .white
    }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { removeTrackingArea(area) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
        trackingArea = area
    }
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        NSCursor.pointingHand.set()
    }
    override func mouseExited(with event: NSEvent) {
        isHovered = false
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        isPressed = true
        super.mouseDown(with: event)
    }
    override func mouseUp(with event: NSEvent) {
        isPressed = false
        super.mouseUp(with: event)
    }
    private func animateState() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            ctx.allowsImplicitAnimation = true
            if isPressed {
                layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.75).cgColor
                layer?.transform = CATransform3DMakeScale(0.95, 0.95, 1.0)
            } else if isHovered {
                layer?.backgroundColor = NSColor(calibratedRed: 0.15, green: 0.52, blue: 1.0, alpha: 1.0).cgColor
                layer?.transform = CATransform3DMakeScale(1.04, 1.04, 1.0)
                layer?.shadowColor = NSColor.systemBlue.cgColor
                layer?.shadowRadius = 10
                layer?.shadowOpacity = 0.6
                layer?.shadowOffset = .zero
            } else {
                layer?.backgroundColor = NSColor.systemBlue.cgColor
                layer?.transform = CATransform3DIdentity
                layer?.shadowOpacity = 0
            }
        }
    }
}

let oneClickBtn = AnimatedInstallButton(frame: NSRect(x: (winW - 270)/2, y: 20, width: 270, height: 42))
oneClickBtn.title = "⚡ One-Click Install to /Applications"
oneClickBtn.font = NSFont.systemFont(ofSize: 13, weight: .bold)
oneClickBtn.target = InstallerActionTarget.self
oneClickBtn.action = #selector(InstallerActionTarget.oneClickInstall)
window.contentView?.addSubview(oneClickBtn)

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)
app.run()
EOF

    sed -i '' "s/__APP_NAME__/$APP_NAME/g" Installer.swift
    sed -i '' "s/__APP_VERSION__/$APP_VERSION/g" Installer.swift

    mkdir -p "Install $APP_NAME.app/Contents/MacOS"
    mkdir -p "Install $APP_NAME.app/Contents/Resources"
    cp "$APP_NAME.app/Contents/Resources/AppIcon.icns" "Install $APP_NAME.app/Contents/Resources/"
    swiftc Installer.swift -o "Install $APP_NAME.app/Contents/MacOS/Install $APP_NAME"
    chmod +x "Install $APP_NAME.app/Contents/MacOS/Install $APP_NAME"

    cat > "Install $APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Install $APP_NAME</string>
    <key>CFBundleIdentifier</key><string>com.aoh.snapback.installer</string>
    <key>CFBundleName</key><string>Install $APP_NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
</dict>
</plist>
EOF

    INSTALLER_DIR=$(mktemp -d)
    mv "$APP_NAME.app" "$INSTALLER_DIR/"
    mv "Install $APP_NAME.app" "$INSTALLER_DIR/"
    popd > /dev/null
    rm -rf "$BUILD_DIR"

    open "$INSTALLER_DIR/Install $APP_NAME.app"
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
else
    show_failure_art
    printf "\n"
    printf "${ALERT_RED}CRITICAL ERROR:${NC} Compilation protocol failed.\n"
    printf "${TXT_GREY}DEBUGGING:${NC} Review output log above for trace data.\n"
    popd > /dev/null
    exit 1
fi
