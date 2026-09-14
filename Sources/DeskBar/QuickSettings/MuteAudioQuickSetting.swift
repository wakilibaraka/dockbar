import AppKit
import CoreAudio

final class MuteAudioQuickSetting: QuickSetting {
    let id = "mute"
    let title = "Mute"
    let symbolName = "speaker.slash.fill"
    var settingsURL: URL? { URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") }
    var isOn: Bool = false
    
    init() { refreshState() }
    
    func refreshState() {
        var defaultDeviceID = AudioObjectID(kAudioObjectUnknown)
        var propAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &size, &defaultDeviceID)
        guard defaultDeviceID != kAudioObjectUnknown else { return }
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        AudioObjectGetPropertyData(defaultDeviceID, &muteAddr, 0, nil, &muteSize, &muted)
        isOn = muted != 0
    }
    
    func toggle() {
        var defaultDeviceID = AudioObjectID(kAudioObjectUnknown)
        var propAddr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propAddr, 0, nil, &size, &defaultDeviceID)
        guard defaultDeviceID != kAudioObjectUnknown else { return }
        var muteAddr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        var newMuted: UInt32 = isOn ? 0 : 1
        AudioObjectSetPropertyData(defaultDeviceID, &muteAddr, 0, nil, muteSize, &newMuted)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in self?.refreshState() }
    }
}
