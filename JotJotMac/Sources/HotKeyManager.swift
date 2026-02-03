import SwiftUI
import Carbon.HIToolbox

final class HotKeyManager: ObservableObject {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    var onHotKey: (() -> Void)?
    
    init() {
        registerGlobalHotKey()
    }
    
    deinit {
        unregister()
    }
    
    private func registerGlobalHotKey() {
        // ⌘ + Shift + J
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = 0x4A4F5421 // "JOT!"
        hotKeyID.id = 1
        
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = 38 // J
        
        let status = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID,
            GetApplicationEventTarget(), 0, &hotKeyRef
        )
        
        guard status == noErr else { return }
        
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handler: EventHandlerUPP = { _, event, userData in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotKeyManager>
                .fromOpaque(userData)
                .takeUnretainedValue()
            
            DispatchQueue.main.async {
                manager.onHotKey?()
            }
            return noErr
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler, 1, &eventSpec,
            selfPtr, &eventHandlerRef
        )
    }
    
    private func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
    }
}
