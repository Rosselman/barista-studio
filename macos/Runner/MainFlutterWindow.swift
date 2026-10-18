import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Enforce minimum window dimensions so the window cannot be collapsed or downsized until invisible
    self.minSize = NSSize(width: 800, height: 600)

    super.awakeFromNib()
  }
}
