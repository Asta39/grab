import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Grab keeps its phone shape: a tall, narrow window that can shrink a little
    // or grow a little, but never fill the screen.
    self.title = "Grab"
    self.contentMinSize = NSSize(width: 380, height: 640)
    self.contentMaxSize = NSSize(width: 520, height: 1000)
    self.setContentSize(NSSize(width: 460, height: 900))
    self.center()

    // No full screen and no zoom-to-fill: the green button stays inactive.
    self.collectionBehavior.insert(.fullScreenNone)
    self.collectionBehavior.remove(.fullScreenPrimary)
    self.standardWindowButton(.zoomButton)?.isEnabled = false

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
