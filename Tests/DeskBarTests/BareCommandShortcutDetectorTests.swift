import CoreGraphics
import Testing
@testable import DockBar

/// Builds a real key-down CGEvent for the given virtual key code so the detector can
/// read the keyboardEventKeycode field (which distinguishes left from right Command).
/// Creating events needs no special permission; only posting them to the system does.
private func commandEvent(_ keyCode: Int64) -> CGEvent {
    CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true)!
}

private let leftCommandKey: Int64 = 55

@Test
func bareCommandOpensOnSecondCommandTap() {
    var detector = BareCommandShortcutDetector()

    // The first tap only arms the detector, so a stray Command press never fires.
    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == false)
    // The second tap inside the threshold opens the bare command launcher.
    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == true)
    #expect(detector.isRightCommandTap == false)
}

@Test
func rightCommandDoubleTapIsFlaggedAsRightCommand() {
    var detector = BareCommandShortcutDetector()
    let rightCommandKey: Int64 = 54

    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(rightCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(rightCommandKey)) == false)
    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(rightCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(rightCommandKey)) == true)
    #expect(detector.isRightCommandTap)
}

@Test
func bareCommandIgnoresCommandShortcuts() {
    var detector = BareCommandShortcutDetector()

    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    detector.handleKeyDown()
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == false)
}

@Test
func bareCommandIgnoresChordedModifiers() {
    var detector = BareCommandShortcutDetector()

    #expect(detector.handleFlagsChanged([.maskCommand, .maskShift], event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == false)
}

@Test
func bareCommandIgnoresModifierPressedDuringCommandTap() {
    var detector = BareCommandShortcutDetector()

    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged([.maskCommand, .maskShift], event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == false)
}

@Test
func bareCommandIgnoresPointerCancellation() {
    var detector = BareCommandShortcutDetector()

    #expect(detector.handleFlagsChanged(.maskCommand, event: commandEvent(leftCommandKey)) == false)
    detector.cancel()
    #expect(detector.handleFlagsChanged([], event: commandEvent(leftCommandKey)) == false)
}
