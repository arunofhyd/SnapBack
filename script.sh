#!/bin/bash

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
 █▀ █▄░█ ▄▀█ █▀█  █▄▄ ▄▀█ █▀▀ █▄▀
 ▄█ █░▀█ █▀█ █▀▀  █▄█ █▀█ █▄▄ █░█
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
 █▀ █░█ █▀▀ █▀▀ █▀▀ █▀ █▀
 ▄█ █▄█ █▄▄ █▄▄ ██▄ ▄█ ▄█
EOF
    printf "${NC}\n"
}

# High-Impact Outcome: Failure
show_failure_art() {
    printf "\n${ALERT_RED}"
    cat << "EOF"
 █▀▀ ▄▀█ █ █░░ █▀▀ █▀▄
 █▀░ █▀█ █ █▄▄ ██▄ █▄▀
EOF
    printf "${NC}\n"
}

# --- EXECUTION START ---

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
else
    printf "   ${NEON_GREEN}✔ Xcode Command Line Tools detected.${NC}\n"
fi
printf "\n"

# --- STEP 1: ENVIRONMENT ---
# Create a secure temporary directory
BUILD_DIR=$(mktemp -d)
DEST_DIR="$HOME/Desktop"

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
mkdir -p "Snap Back.app/Contents/MacOS"
mkdir -p "Snap Back.app/Contents/Resources"
mv AppIcon.icns "Snap Back.app/Contents/Resources/"

cat > "Snap Back.app/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SnapBack</string>
    <key>CFBundleIdentifier</key>
    <string>com.snapback.app</string>
    <key>CFBundleName</key>
    <string>Snap Back</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>5.3</string>
    <key>CFBundleVersion</key>
    <string>53</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Snap Back needs to control other applications to save and restore window layouts.</string>
</dict>
</plist>
EOF
printf "   ${NEON_GREEN}✔ Info.plist injected.${NC}\n\n"

# --- STEP 4: SOURCE INJECTION ---
show_step 4 "Injecting Source Code..."
cat > SnapBack.swift <<'EOF'
import Cocoa

// --- CONFIGURATION ---
let appTitle = "Snap Back"
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
    let script = "display notification \"\(message)\" with title \"Snap Back\""
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
    var info = "Snap Back encountered an error."
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

func showHelp() {
    let alert = NSAlert()
    alert.messageText = "How to Use Snap Back"
    
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
        "- Click '+' (or allow in list) to add 'Snap Back'."
    ])
    
    addDetailedItem("2. Screen Recording", [
        "- Required to save screenshot previews.",
        "- Go to Privacy & Security > Screen Recording.",
        "- Click '+' (or allow in list) to add 'Snap Back'."
    ])
    
    addDetailedItem("3. Automation", [
        "- Required to control Browser tabs/ Apps.",
        "- Accept the system prompt when it appears."
    ])
    
    addHeader("Troubleshooting", icon: "🛠")
    addBody("If a window fails to move, remove Snap Back from Privacy & Security settings and re-add it to reset permissions.")
    addHeader("Capture State", icon: "📸")
    addBody("Click 'Save New...' to instantly record the geometry & state of all open windows/apps and browser tabs (Safari, Chrome, Arc, etc).")
    
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
                if appName is not "Snap Back" and appName is not "app_mode_loader" and appName is not "ControlCenter" then
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
                if (count of urlList) > 0 then
                    if not (exists document 1) then make new document
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
            set visible of (every process where visible is true and name is not "Snap Back") to false
        end tell
        delay 0.5
        
        tell application "Finder" to set screenBounds to bounds of window of desktop
        set screenW to item 3 of screenBounds
        set screenH to item 4 of screenBounds
        
        -- Phase 1: Launch & Open Tabs
        repeat with winRecord in windowPositions
            set appName to procName of winRecord
            set urlList to savedUrls of winRecord
            
            try
                -- Activate generic app (no dictionary needed)
                tell application appName to activate
                delay 1
                
                -- Delegate specific logic to Handlers
                if appName is "Safari" then
                      my restoreSafari(urlList)
                      
                else if appName is in chromiumVariants then
                      my restoreChrome(appName, urlList)
                      
                else if appName is "Firefox" then
                      my restoreFirefox(appName, urlList)
                end if
            end try
        end repeat
        
        delay 2
        
        -- Phase 2: Restore Geometry
        repeat with winRecord in windowPositions
            set appName to procName of winRecord
            
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
            
            set rawIndex to winIndex of winRecord

            try
                tell application "System Events" to tell process appName
                    set targetIndex to rawIndex
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
alert.messageText = appTitle
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
printf "   ${NEON_GREEN}✔ Core Logic Integrated.${NC}\n\n"

# --- STEP 5: COMPILATION & CLEANUP ---
show_step 5 "Compiling Binary Executable..."

(
swiftc SnapBack.swift -o "Snap Back.app/Contents/MacOS/SnapBack"
) &
show_spinner $!

if [ $? -eq 0 ]; then
    printf "   ${NEON_GREEN}✔ Compilation Complete.${NC}\n\n"
    
    show_step 6 "Finalizing and Signing..."
    
    # Ensure binary is executable
    chmod +x "Snap Back.app/Contents/MacOS/SnapBack"
    chmod +x "Snap Back.app/Contents/Resources"
    
    # --- Ad-Hoc Signing ---
    printf "   ${TXT_GREY}Applying local signature...${NC} "
    codesign --force --deep -s - "Snap Back.app" &>/dev/null
    printf "${NEON_GREEN}Secure.${NC}\n"
    
    # Return to previous directory
    popd > /dev/null
    
    # Move app to Desktop (Replace existing)
    if [ -d "$DEST_DIR/Snap Back.app" ]; then
        rm -rf "$DEST_DIR/Snap Back.app"
    fi
    
    mv "$BUILD_DIR/Snap Back.app" "$DEST_DIR/"
    
    # Clean up temp dir
    rm -rf "$BUILD_DIR"
    
    print_line
    show_success_art
    print_line
    printf "\n"
    printf "   ${NEON_CYAN}DEPLOYMENT COMPLETE:${NC} Snap Back.app is now on your Desktop.\n"
    printf "   ${NEON_PURPLE}SUGGESTION:${NC} Drag to Applications and assign launch shortcut.\n"
    printf "   ${TXT_GREY}EXECUTION TIME: $(date +%T)${NC}\n"
    printf "\n"
    # Audio Feedback
    afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || tput bel
else
    show_failure_art
    printf "\n"
    printf "${ALERT_RED}CRITICAL ERROR:${NC} Compilation protocol failed.\n"
    printf "${TXT_GREY}DEBUGGING:${NC} Review output log above for trace data.\n"
    popd > /dev/null
    exit 1
fi
