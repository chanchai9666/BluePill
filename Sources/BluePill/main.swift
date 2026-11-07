import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hides from Dock, runs strictly in menu bar
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
