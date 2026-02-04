cd ~/Desktop

echo "1. Deleting old files..."
rm -f WindowSaverUltimate.swift
rm -f WindowSaver.swift
rm -f SnapBack.swift

echo "2. Writing new code (Snap Back)..."
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

// Run detached shell command (does not wait)
func runShellDetached(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/zsh"
    task.arguments = ["-c", "nohup sh -c '\(command)' >/dev/null 2>&1 &"]
    task.launch()
}

func runAppleScript(_ source: String) -> (Bool, String?) {
    if let script = NSAppleScript(source: source) {
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let err = error {
            let msg = err["NSAppleScriptErrorMessage"] as? String ?? "Unknown AppleScript error"
            // Don't print if it's just the minimize/close script failing (e.g. not running in Terminal)
            if !source.contains("tell application \"Terminal\"") {
                print("Script Error: \(msg)")
            }
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
    if let d = details {
        info += "\n\nError: \(d)"
    }
    
    // Check for common permission error keywords
    let isPermissionIssue = details?.lowercased().contains("not allowed") ?? true
    
    if isPermissionIssue {
        info += "\n\nThis is likely due to missing Accessibility permissions. Please check System Settings."
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
    } else {
        alert.addButton(withTitle: "OK")
    }
    
    alert.informativeText = info
    
    let response = alert.runModal()
    if isPermissionIssue && response == .alertFirstButtonReturn {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

func showHelp() {
    let alert = NSAlert()
    alert.messageText = "Snap Back Setup Guide"
    
    // Create custom view for Help text only
    let helpViewWidth: CGFloat = 400
    let helpViewHeight: CGFloat = 200
    let helpContainer = NSView(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    
    // Instructions Text
    let textView = NSTextField(frame: NSRect(x: 0, y: 0, width: helpViewWidth, height: helpViewHeight))
    textView.isEditable = false
    textView.isBordered = false
    textView.drawsBackground = false
    textView.stringValue = """
    Snap Back needs permission to control windows and take screenshots.
    
    Usually, macOS will prompt you to "Allow" these automatically when you first run the app.
    
    If the app isn't working, please ensure 'Snap Back' is enabled in:
    
    1. System Settings > Privacy & Security > Accessibility
       (Click '+' to add Snap Back if missing)
       
    2. System Settings > Privacy & Security > Screen Recording
       (Toggle 'Snap Back' ON)
       
    If issues persist, remove and re-add the app in settings.
    """
    helpContainer.addSubview(textView)
    
    alert.accessoryView = helpContainer
    
    alert.addButton(withTitle: "Open Privacy Settings")
    alert.addButton(withTitle: "OK")
    
    if alert.runModal() == .alertFirstButtonReturn {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}

func deleteProfile(name: String) -> Bool {
    let scriptFile = storageFolder.appendingPathComponent("\(name).scpt")
    let imgFile = storageFolder.appendingPathComponent("\(name).png")
    
    do {
        if fileManager.fileExists(atPath: scriptFile.path) {
            try fileManager.removeItem(at: scriptFile)
        }
        if fileManager.fileExists(atPath: imgFile.path) {
            try fileManager.removeItem(at: imgFile)
        }
        return true
    } catch {
        showError(message: "Failed to delete profile: \(error.localizedDescription)")
        return false
    }
}

// --- CORE LOGIC ---

func saveProfile(name: String) -> Bool {
    let dataFile = storageFolder.appendingPathComponent("\(name).scpt")
    let imgFile = storageFolder.appendingPathComponent("\(name).png")
    
    // 1. Take Screenshot FIRST
    let status = runShell("screencapture -x \"\(imgFile.path)\"")
    if status != 0 {
        showError(message: "Failed to take screenshot. Check Screen Recording permissions.")
        return false
    }

    // 2. Save Window Data
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
                
                -- FILTER: Ignore background helpers
                if appName is not "app_mode_loader" and appName is not "ControlCenter" and appName is not "Snap Back" then
                    
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
    if success {
        return true
    } else {
        showScriptError(details: errorMsg)
        return false
    }
}

func restoreProfile(name: String) {
    let dataFile = storageFolder.appendingPathComponent("\(name).scpt")
    
    let script = #"""
    set theFile to POSIX file "\#(dataFile.path)"
    try
        set loadedScript to load script theFile
        set windowPositions to mainData of loadedScript
        
        -- PHASE 1: Launch all apps first
        repeat with winRecord in windowPositions
            set appName to processName of winRecord
            try
                tell application appName to activate
            end try
        end repeat
        
        -- PHASE 2: Wait loop (Give apps 2 seconds to actually open)
        delay 2
        
        -- PHASE 3: Apply Layouts
        repeat with winRecord in windowPositions
            set appName to processName of winRecord
            set theUrl to savedUrl of winRecord
            set targetPos to wPos of winRecord
            set targetSize to wSize of winRecord
            
            try
                -- SAFARI SPECIFIC FIX
                if appName is "Safari" then
                    tell application "Safari"
                        activate
                        if not (exists document 1) then make new document
                        if theUrl is not "" then set URL of document 1 to theUrl
                    end tell
                
                -- CHROME SPECIFIC FIX
                else if appName is "Google Chrome" then
                    tell application "Google Chrome"
                        activate
                        if not (exists window 1) then make new window
                        if theUrl is not "" then set URL of active tab of window 1 to theUrl
                    end tell
                    
                else
                    -- STANDARD APPS
                    tell application appName to activate
                end if
                
                -- FORCE MOVE (Try repeatedly if app is slow)
                repeat 3 times
                    try
                        tell application "System Events" to tell process appName
                            set targetIndex to winIndex of winRecord
                            if (count of windows) >= targetIndex then
                                set position of window targetIndex to targetPos
                                set size of window targetIndex to targetSize
                                exit repeat -- Success!
                            end if
                        end tell
                    end try
                    delay 0.5 -- Wait half a second and try moving again
                end repeat
                
            end try
        end repeat
    end try
    """#
    
    let (success, errorMsg) = runAppleScript(script)
    if success == false {
        showScriptError(details: errorMsg)
    }
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
deleteBtn.title = "Delete"
deleteBtn.bezelStyle = .rounded

let imgView = NSImageView(frame: NSRect(x: 0, y: 0, width: viewWidth, height: 250))
imgView.imageScaling = .scaleProportionallyUpOrDown
imgView.imageFrameStyle = .grayBezel

// --- UI HANDLERS ---

func refreshList() {
    let profiles = getSavedProfiles()
    dropdown.removeAllItems()
    dropdown.addItems(withTitles: profiles)
    if profiles.isEmpty { 
        dropdown.addItem(withTitle: "No Profiles Found")
        deleteBtn.isEnabled = false
    } else {
        deleteBtn.isEnabled = true
    }
    updateImage()
}

func updateImage() {
    guard let selected = dropdown.titleOfSelectedItem else { 
        imgView.image = nil
        return 
    }
    let imgPath = storageFolder.appendingPathComponent("\(selected).png")
    if fileManager.fileExists(atPath: imgPath.path) {
        // Force reload by creating new NSImage from file
        imgView.image = NSImage(contentsOf: imgPath)
    } else {
        imgView.image = nil
    }
}

class UIHandler: NSObject {
    @objc func dropdownChanged(_ sender: Any) { updateImage() }
    
    @objc func deleteClicked(_ sender: Any) {
        guard let name = dropdown.titleOfSelectedItem, name != "No Profiles Found" else { return }
        let confirm = NSAlert()
        confirm.messageText = "Delete '\(name)'?"
        confirm.informativeText = "This cannot be undone."
        confirm.addButton(withTitle: "Delete")
        confirm.addButton(withTitle: "Cancel")
        if confirm.runModal() == .alertFirstButtonReturn {
            if deleteProfile(name: name) {
                refreshList()
            }
        }
    }
}

let handler = UIHandler()
dropdown.target = handler
dropdown.action = #selector(UIHandler.dropdownChanged(_:))
deleteBtn.target = handler
deleteBtn.action = #selector(UIHandler.deleteClicked(_:))

refreshList()

container.addSubview(dropdown)
container.addSubview(deleteBtn)
container.addSubview(imgView)
alert.accessoryView = container

// --- MAIN EXECUTION ---

app.activate(ignoringOtherApps: true)

// TERMINAL MANAGEMENT: Capture ID and Minimize
var terminalWindowID: String? = nil
let getIDScript = "tell application \"Terminal\" to get id of front window"
let (gotID, idResult) = runAppleScript(getIDScript)

if gotID, let idStr = idResult {
    terminalWindowID = idStr
    // Force minimize immediately
    let minimizeScript = "tell application \"Terminal\" to set minimized of window id \(idStr) to true"
    _ = runAppleScript(minimizeScript)
}

// Main Event Loop Logic
while true {
    let response = alert.runModal()
    
    if response == .alertFirstButtonReturn { // Restore
        if let name = dropdown.titleOfSelectedItem, name != "No Profiles Found" {
            restoreProfile(name: name)
        }
        break // Exit
    } 
    else if response == .alertSecondButtonReturn { // Save New...
        while true {
            let nameAlert = NSAlert()
            nameAlert.messageText = "Name your profile"
            nameAlert.addButton(withTitle: "Save")
            nameAlert.addButton(withTitle: "Cancel")
            let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            nameAlert.accessoryView = input
            
            if nameAlert.runModal() == .alertFirstButtonReturn {
                let newName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if newName.isEmpty { continue }
                
                // SANITIZATION
                let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
                if newName.rangeOfCharacter(from: invalidCharacters) != nil {
                    let invalidAlert = NSAlert()
                    invalidAlert.messageText = "Invalid Name"
                    invalidAlert.informativeText = "Name cannot contain special characters like quotes or slashes."
                    invalidAlert.runModal()
                    continue
                }
                
                // DUPLICATE CHECK
                let existing = getSavedProfiles().map { $0.lowercased() }
                if existing.contains(newName.lowercased()) {
                    let dupAlert = NSAlert()
                    dupAlert.messageText = "Name already exists"
                    dupAlert.informativeText = "This name matches an existing profile."
                    dupAlert.runModal()
                    continue
                }
                
                if saveProfile(name: newName) {
                    showSuccess(message: "Profile saved successfully!")
                    break // Break inner loop (name prompt)
                } else {
                    break // Break inner loop (failed save)
                }
            } else { 
                break // Cancelled name prompt
            }
        }
        break // Exit app after save flow
    } 
    else if response == .alertThirdButtonReturn { // Cancel
        // Close Terminal Forcefully (saving no) to avoid "Terminate?" prompt
        // We do this by launching a detached background process to close the window
        // AFTER this app exits.
        if let tid = terminalWindowID {
            let closeScript = "sleep 0.2; osascript -e 'tell application \"Terminal\" to close window id \(tid) saving no'"
            runShellDetached(closeScript)
        }
        exit(0) // Exit immediately so the window has no running process
    }
    else { // Help Button
        showHelp()
        // Loop continues
    }
}
EOF

echo "3. Compiling updated app..."
swiftc SnapBack.swift -o "Snap Back"

echo "Done. You can now run the app by double-clicking 'Snap Back' on your Desktop."
