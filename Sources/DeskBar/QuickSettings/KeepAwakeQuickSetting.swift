import IOKit.pwr_mgt

final class KeepAwakeQuickSetting: QuickSetting {
    let id = "keepAwake"
    let title = "Keep Awake"
    let symbolName = "cup.and.heat.waves.fill"
    var isOn: Bool = false
    private var assertionID: IOPMAssertionID = 0
    
    init() { refreshState() }
    
    func refreshState() {
        isOn = assertionID != 0
    }
    
    func toggle() {
        if isOn {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        } else {
            IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "DeskBar Keep Awake" as CFString,
                &assertionID
            )
        }
        refreshState()
    }
    
    deinit {
        if assertionID != 0 { IOPMAssertionRelease(assertionID) }
    }
}
