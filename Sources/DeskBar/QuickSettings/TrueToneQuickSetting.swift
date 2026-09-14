import AppKit

final class TrueToneQuickSetting: QuickSetting {
    let id = "truetone"
    let title = "True Tone"
    let symbolName = "sun.max.fill"
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") }
    var isOn: Bool = false
    
    private var client: AnyObject?
    
    init() {
        if let bundle = Bundle(path: "/System/Library/PrivateFrameworks/CoreBrightness.framework"), bundle.load(),
           let clientClass = NSClassFromString("CBTrueToneClient") as? NSObject.Type {
            client = clientClass.init()
        }
        refreshState()
    }
    
    func refreshState() {
        guard let client = client else { return }
        isOn = (client.value(forKey: "enabled") as? Bool) ?? false
    }
    
    func toggle() {
        guard let client = client else { return }
        let newValue = !isOn
        client.setValue(newValue, forKey: "enabled")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.refreshState()
        }
    }
}
