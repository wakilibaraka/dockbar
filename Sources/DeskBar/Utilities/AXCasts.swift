import ApplicationServices

// Safe runtime downcasts for Accessibility CoreFoundation payloads. The compiler
// rejects `as?` for CF types ("conditional downcast to CoreFoundation type will
// always succeed"), and `as!` crashes the taskbar on a malformed AX value, so the
// type is verified by CFTypeID and the cast is made explicit.

enum AXCast {
    /// Returns `obj` as an AXUIElement when its CFTypeID matches, else nil.
    static func element(_ obj: Any) -> AXUIElement? {
        guard CFGetTypeID(obj as AnyObject) == AXUIElementGetTypeID() else { return nil }
        return unsafeDowncast(obj as AnyObject, to: AXUIElement.self)
    }

    /// Returns `obj` as an AXValue when its CFTypeID matches, else nil.
    static func value(_ obj: Any) -> AXValue? {
        guard CFGetTypeID(obj as AnyObject) == AXValueGetTypeID() else { return nil }
        return unsafeDowncast(obj as AnyObject, to: AXValue.self)
    }
}
