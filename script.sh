#!/bin/bash

# Ensure we are in the directory where we want to build
cd ~/Desktop || exit 1

echo "1. Cleaning up old files..."
rm -f SnapBack.swift
rm -f GenIcon.swift
rm -f AppIcon.png
rm -rf AppIcon.iconset
rm -rf "Snap Back.tmp.app"
rm -rf "Snap Back.app"

echo "2. Creating Temporary App Bundle Structure..."
mkdir -p "Snap Back.tmp.app/Contents/MacOS"
mkdir -p "Snap Back.tmp.app/Contents/Resources"
# Ensure folders are executable
chmod 755 "Snap Back.tmp.app/Contents/MacOS"
chmod 755 "Snap Back.tmp.app/Contents/Resources"

echo "3. Creating App Icon..."
cat > GenIcon.swift <<'EOF'
import Cocoa
let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()
let context = NSGraphicsContext.current!.cgContext
let path = NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 224, yRadius: 224)
NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0).setFill()
path.fill()
context.setShadow(offset: CGSize(width: 0, height: -10), blur: 20)
let strokePath = NSBezierPath()
strokePath.lineWidth = 80
strokePath.lineCapStyle = .round
strokePath.lineJoinStyle = .round
let padding: CGFloat = 150
let legLength: CGFloat = 180
func drawCorner(start: CGPoint, corner: CGPoint, end: CGPoint) {
    strokePath.move(to: start); strokePath.line(to: corner); strokePath.line(to: end)
}
drawCorner(start: CGPoint(x: padding, y: 1024 - padding - legLength), corner: CGPoint(x: padding, y: 1024 - padding), end: CGPoint(x: padding + legLength, y: 1024 - padding))
drawCorner(start: CGPoint(x: 1024 - padding - legLength, y: 1024 - padding), corner: CGPoint(x: 1024 - padding, y: 1024 - padding), end: CGPoint(x: 1024 - padding, y: 1024 - padding - legLength))
drawCorner(start: CGPoint(x: padding, y: padding + legLength), corner: CGPoint(x: padding, y: padding), end: CGPoint(x: padding + legLength, y: padding))
drawCorner(start: CGPoint(x: 1024 - padding - legLength, y: padding), corner: CGPoint(x: 1024 - padding, y: padding), end: CGPoint(x: 1024 - padding, y: padding + legLength))
NSColor(white: 1.0, alpha: 1.0).setStroke()
strokePath.stroke()
image.unlockFocus()
if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "AppIcon.png"))
}
EOF
swiftc GenIcon.swift -o GenIcon
./GenIcon
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
mv AppIcon.icns "Snap Back.tmp.app/Contents/Resources/"
rm GenIcon.swift GenIcon AppIcon.png
rm -rf AppIcon.iconset

echo "4. Creating Info.plist..."
cat > "Snap Back.tmp.app/Contents/Info.plist" <<'EOF'
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
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
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

echo "5. Writing Swift Source..."
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
        return (true, result.stringValue)
    }
    return (false, "Failed to initialize NSAppleScript")
}

func getSavedProfiles() -> [String] {
    guard let files = try? fileManager.contentsOfDirectory(atPath: storageFolder.path) else { return [] }
    return files.filter { $0.hasSuffix(".scpt") }.map { $0.replacingOccurrences(of: ".scpt", with: "") }
}

func showSuccess(message: String) {
    let alert = NSAlert()
    alert.messageText = "Success"
    alert.informativeText = message
    alert.runModal()
}

func showError(message: String) {
    let alert = NSAlert()
    alert.messageText = "Error"
    alert.informativeText = message
    alert.runModal()
}

func showScriptError(details: String?) {
    let alert = NSAlert()
    alert.messageText = "Operation Failed"
    var info = "Snap Back encountered an error."
    if let d = details { info += "\n\nError: \(d)" }
    let err = details?.lowercased() ?? ""
    let isPermissionIssue = err.contains("not allowed") || err.contains("not authorized") || err.contains("(-1743)")
    if isPermissionIssue {
        info += "\n\nPlease check System Settings > Privacy & Security > Automation."
        alert.addButton(withTitle: "Open Settings"); alert.addButton(withTitle: "Cancel")
    } else { alert.addButton(withTitle: "OK") }
    alert.informativeText = info
    if alert.runModal() == .alertFirstButtonReturn && isPermissionIssue {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        NSWorkspace.shared.open(url)
    }
}

func showHelp() {
    let alert = NSAlert()
    alert.messageText = "Snap Back Setup Guide"
    
    let helpViewWidth: CGFloat = 450
    let helpViewHeight: CGFloat = 220
    let helpContainer = NSView(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    let textView = NSTextField(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    textView.isEditable = false
    textView.isBordered = false
    textView.drawsBackground = false
    
    textView.stringValue = """
    You must grant the following permissions in System Settings:

    1. Accessibility
    - Required to move and resize windows.
    - Go to Privacy & Security > Accessibility.
    - Click '+' (or allow in list) to add 'Snap Back'.

    2. Screen Recording
    - Required to save screenshot previews.
    - Go to Privacy & Security > Screen Recording.
    - Click '+' (or allow in list) to add 'Snap Back'.

    If the app fails to save or restore, try removing it from these lists and adding it again.
    """
    
    helpContainer.addSubview(textView)
    alert.accessoryView = helpContainer
    
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Open Privacy Settings")
    
    let response = alert.runModal()
    
    if response == .alertSecondButtonReturn {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

func deleteProfile(name: String) -> Bool {
    let scriptFile = storageFolder.appendingPathComponent("\(name).scpt")
    let jpgFile = storageFolder.appendingPathComponent("\(name).jpg")
    let pngFile = storageFolder.appendingPathComponent("\(name).png")
    do {
        if fileManager.fileExists(atPath: scriptFile.path) { try fileManager.removeItem(at: scriptFile) }
        if fileManager.fileExists(atPath: jpgFile.path) { try fileManager.removeItem(at: jpgFile) }
        if fileManager.fileExists(atPath: pngFile.path) { try fileManager.removeItem(at: pngFile) }
        return true
    } catch { return false }
}

// --- CORE LOGIC ---
func saveProfile(name: String) -> Bool {
    let dataFile = storageFolder.appendingPathComponent("\(name).scpt")
    let imgFile = storageFolder.appendingPathComponent("\(name).jpg") 
    
    let status = runShell("screencapture -x -t jpg \"\(imgFile.path)\"")
    if status != 0 { showError(message: "Screenshot failed. Check permissions."); return false }

    let script = #"""
    script DataCarrier
        property mainData : {}
    end script
    set thePath to "\#(dataFile.path)"
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
                            set wUrl to ""
                            if appName is "Safari" and i is 1 then
                                tell application "Safari" to set wUrl to URL of document 1
                            else if appName is "Google Chrome" and i is 1 then
                                tell application "Google Chrome" to set wUrl to URL of active tab of window 1
                            end if
                            set end of mainData of DataCarrier to {processName:appName, winIndex:i, wPos:wPos, wSize:wSize, savedUrl:wUrl}
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
    let dataFile = storageFolder.appendingPathComponent("\(name).scpt")
    // FIX: Removed semicolon one-liners to fix "Unknown Token" error
    let script = #"""
    set theFile to POSIX file "\#(dataFile.path)"
    try
        set loadedScript to load script theFile
        set windowPositions to mainData of loadedScript
        
        -- Phase 1: Launch
        repeat with winRecord in windowPositions
            set appName to processName of winRecord
            try
                tell application appName to activate
            end try
        end repeat
        delay 2
        
        -- Phase 2: Restore
        repeat with winRecord in windowPositions
            set appName to processName of winRecord
            set theUrl to savedUrl of winRecord
            set targetPos to wPos of winRecord
            set targetSize to wSize of winRecord
            try
                if appName is "Safari" then
                    tell application "Safari"
                        activate
                        if not (exists document 1) then make new document
                        if theUrl is not "" then set URL of document 1 to theUrl
                    end tell
                else if appName is "Google Chrome" then
                    tell application "Google Chrome"
                        activate
                        if not (exists window 1) then make new window
                        if theUrl is not "" then set URL of active tab of window 1 to theUrl
                    end tell
                else
                    tell application appName to activate
                end if
                
                repeat 3 times
                    try
                        tell application "System Events" to tell process appName
                            set targetIndex to winIndex of winRecord
                            if (count of windows) >= targetIndex then
                                set position of window targetIndex to targetPos
                                set size of window targetIndex to targetSize
                                exit repeat
                            end if
                        end tell
                    end try
                    delay 0.5
                end repeat
            end try
        end repeat
    end try
    """#
    let (success, errorMsg) = runAppleScript(script)
    if !success { showScriptError(details: errorMsg) }
}

// --- UI SETUP ---
let app = NSApplication.shared
app.setActivationPolicy(.regular)

let alert = NSAlert()
alert.messageText = appTitle
alert.informativeText = "Manage your window layouts."
alert.addButton(withTitle: "Restore")
alert.addButton(withTitle: "Save New...")
alert.addButton(withTitle: "Cancel")
alert.addButton(withTitle: "Help")

let viewWidth: CGFloat = 450
let viewHeight: CGFloat = 300
let container = NSView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: viewHeight))

let dropdown = NSPopUpButton(frame: NSRect(x: 0, y: 260, width: 340, height: 25))
let deleteBtn = NSButton(frame: NSRect(x: 350, y: 260, width: 90, height: 25))
deleteBtn.title = "Delete"; deleteBtn.bezelStyle = .rounded

// --- FRAME LOGIC ---
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
    
    let imgPath = storageFolder.appendingPathComponent("\(selected).jpg")
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
}
let handler = UIHandler()
dropdown.target = handler; dropdown.action = #selector(UIHandler.dropdownChanged(_:))
deleteBtn.target = handler; deleteBtn.action = #selector(UIHandler.deleteClicked(_:))

refreshList()

container.addSubview(dropdown)
container.addSubview(deleteBtn)
container.addSubview(imgContainer)

alert.accessoryView = container

app.finishLaunching()
app.activate(ignoringOtherApps: true)

// --- LOOP ---
while true {
    let response = alert.runModal()
    if response == .alertFirstButtonReturn { // Restore
        if let name = dropdown.titleOfSelectedItem, name != "No Profiles Found" { restoreProfile(name: name) }
        break
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
                    let dup = NSAlert(); dup.messageText = "Name Exists"; dup.runModal(); continue
                }
                if saveProfile(name: newName) { showSuccess(message: "Saved!"); break }
                else { break }
            } else { break }
        }
        break
    } else if response == .alertThirdButtonReturn { exit(0) } // Cancel
    else { showHelp() }
}
EOF

echo "6. Compiling Snap Back..."
swiftc SnapBack.swift -o "Snap Back.tmp.app/Contents/MacOS/SnapBack"

if [ $? -eq 0 ]; then
    echo "Compilation successful!"
    rm SnapBack.swift
    chmod +x "Snap Back.tmp.app/Contents/MacOS/SnapBack"
    rm -rf "Snap Back.app"
    mv "Snap Back.tmp.app" "Snap Back.app"
    touch "Snap Back.app"
    echo "Done. 'Snap Back.app' is ready on your Desktop."
else
    echo "Compilation failed."
    rm -rf "Snap Back.tmp.app"
    exit 1
fi
