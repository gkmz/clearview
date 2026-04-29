import AppKit
import Carbon.HIToolbox

final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private var eventHandlerRef: EventHandlerRef?
    private var registeredRefs: [ShortcutAction: EventHotKeyRef] = [:]
    private var callbacks: [ShortcutAction: () -> Void] = [:]

    private init() {
        installHotKeyHandler()
    }

    deinit {
        unregisterAllHotKeys()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    @discardableResult
    func configure(
        action: ShortcutAction,
        keyCode: UInt16,
        modifierFlagsRaw: UInt,
        onTrigger: @escaping () -> Void
    ) -> Bool {
        callbacks[action] = onTrigger
        return registerHotKey(action: action, keyCode: keyCode, modifierFlagsRaw: modifierFlagsRaw)
    }

    @discardableResult
    func updateShortcut(action: ShortcutAction, keyCode: UInt16, modifierFlagsRaw: UInt) -> Bool {
        registerHotKey(action: action, keyCode: keyCode, modifierFlagsRaw: modifierFlagsRaw)
    }

    func shortcutDisplayString(keyCode: UInt16, modifierFlagsRaw: UInt) -> String {
        let flags = normalized(NSEvent.ModifierFlags(rawValue: modifierFlagsRaw))
        var parts: [String] = []
        if flags.contains(.command) { parts.append("⌘") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.control) { parts.append("⌃") }
        parts.append(keyName(for: keyCode))
        return parts.joined(separator: "")
    }

    static func isFunctionKey(_ keyCode: UInt16) -> Bool {
        functionKeyNames.keys.contains(keyCode)
    }

    private func installHotKeyHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, eventRef, userData in
                guard
                    let eventRef,
                    let userData
                else {
                    return noErr
                }
                let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
                manager.handleHotKey(eventRef: eventRef)
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
        if status != noErr {
            eventHandlerRef = nil
        }
    }

    private func handleHotKey(eventRef: EventRef) {
        var triggeredID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &triggeredID
        )
        guard status == noErr else { return }
        guard triggeredID.signature == hotKeySignature else { return }
        guard let action = actionByHotKeyID[triggeredID.id] else { return }
        callbacks[action]?()
    }

    private func registerHotKey(action: ShortcutAction, keyCode: UInt16, modifierFlagsRaw: UInt) -> Bool {
        unregisterHotKey(action: action)
        var registeredRef: EventHotKeyRef?
        let flags = normalized(NSEvent.ModifierFlags(rawValue: modifierFlagsRaw))
        let hotKeyID = EventHotKeyID(signature: hotKeySignature, id: action.hotKeyID)
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            carbonModifiers(from: flags),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &registeredRef
        )
        if status == noErr, let registeredRef {
            registeredRefs[action] = registeredRef
            return true
        }
        return false
    }

    private func unregisterHotKey(action: ShortcutAction) {
        if let ref = registeredRefs[action] {
            UnregisterEventHotKey(ref)
            registeredRefs[action] = nil
        }
    }

    private func unregisterAllHotKeys() {
        for (action, ref) in registeredRefs {
            UnregisterEventHotKey(ref)
            registeredRefs[action] = nil
        }
    }

    private func normalized(_ flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.command, .shift, .option, .control])
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbonFlags: UInt32 = 0
        if flags.contains(.command) { carbonFlags |= UInt32(cmdKey) }
        if flags.contains(.shift) { carbonFlags |= UInt32(shiftKey) }
        if flags.contains(.option) { carbonFlags |= UInt32(optionKey) }
        if flags.contains(.control) { carbonFlags |= UInt32(controlKey) }
        return carbonFlags
    }

    private func keyName(for keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2", 20: "3",
            21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩", 37: "L", 38: "J", 39: "'",
            40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space",
            50: "`", 51: "⌫", 53: "⎋"
        ]
        return Self.functionKeyNames[keyCode] ?? keyMap[keyCode] ?? "#\(keyCode)"
    }

    private let hotKeySignature = OSType(0x43564B59) // "CVKY"

    private let actionByHotKeyID: [UInt32: ShortcutAction] = [
        1: .toggleMainPanel,
        2: .toggleReminder,
        3: .cycleBlueLightLevel,
        4: .snoozeReminder
    ]

    private static let functionKeyNames: [UInt16: String] = [
        122: "F1",
        120: "F2",
        99: "F3",
        118: "F4",
        96: "F5",
        97: "F6",
        98: "F7",
        100: "F8",
        101: "F9",
        109: "F10",
        103: "F11",
        111: "F12",
        105: "F13",
        107: "F14",
        113: "F15",
        106: "F16",
        64: "F17",
        79: "F18",
        80: "F19",
        90: "F20"
    ]
}

private extension ShortcutAction {
    var hotKeyID: UInt32 {
        switch self {
        case .toggleMainPanel: return 1
        case .toggleReminder: return 2
        case .cycleBlueLightLevel: return 3
        case .snoozeReminder: return 4
        }
    }
}
