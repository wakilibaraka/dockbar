import CoreAudio

final class MuteMicQuickSetting: QuickSetting {
    let id = "muteMic"
    let title = "Mute Mic"
    let symbolName = "mic.slash.fill"
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") }
    var isOn: Bool = false
    
    init() { refreshState() }
    
    private func defaultInputDeviceID() -> AudioObjectID {
        var deviceID = AudioObjectID(kAudioObjectUnknown)
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &addr, 0, nil, &size, &deviceID)
        return deviceID
    }
    
    func refreshState() {
        let deviceID = defaultInputDeviceID()
        guard deviceID != kAudioObjectUnknown else { return }
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(deviceID, &muteAddr, 0, nil, &size, &muted)
        isOn = muted != 0
    }
    
    func toggle() {
        let deviceID = defaultInputDeviceID()
        guard deviceID != kAudioObjectUnknown else { return }
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<UInt32>.size)
        var newMuted: UInt32 = isOn ? 0 : 1
        AudioObjectSetPropertyData(deviceID, &muteAddr, 0, nil, size, &newMuted)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.refreshState() }
    }
}
