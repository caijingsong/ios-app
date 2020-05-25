import UIKit
import AVFoundation
import UserNotifications
import CallKit
import MixinServices

class MixinCallInterface {
    
    private let callObserver = CXCallObserver()
    
    private var pendingIncomingUuid: UUID?
    
    private unowned var service: CallService!
    
    private var isLineIdle: Bool {
        service.call == nil && callObserver.calls.isEmpty
    }
    
    required init(manager: CallService) {
        self.service = manager
    }
    
    private func requestRecordPermission(completion: @escaping (Bool) -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
                completion(granted)
            }
        case .denied:
            completion(false)
        case .granted:
            completion(true)
        @unknown default:
            completion(false)
        }
    }
    
}

extension MixinCallInterface: CallInterface {
    
    func requestStartCall(uuid: UUID, handle: CallHandle, completion: @escaping CallInterfaceCompletion) {
        guard WebSocketService.shared.isConnected else {
            completion(CallError.networkFailure)
            return
        }
        guard isLineIdle else {
            completion(CallError.busy)
            return
        }
        requestRecordPermission { (granted) in
            if granted {
                self.service.startCall(uuid: uuid, handle: handle, completion: { (success) in
                    if success {
                        self.service.ringtonePlayer?.play()
                    }
                })
                completion(nil)
            } else {
                completion(CallError.microphonePermissionDenied)
            }
        }
    }
    
    func requestEndCall(uuid: UUID, completion: @escaping CallInterfaceCompletion) {
        if uuid == pendingIncomingUuid {
            pendingIncomingUuid = nil
        }
        UNUserNotificationCenter.current().removeNotifications(withIdentifiers: [uuid.uuidString])
        service.endCall(uuid: uuid)
        completion(nil)
    }
    
    func requestSetMute(uuid: UUID, muted: Bool, completion: @escaping CallInterfaceCompletion) {
        service.isMuted = muted
        completion(nil)
    }
    
    func reportNewIncomingCall(uuid: UUID, handle: CallHandle, localizedCallerName: String, completion: @escaping CallInterfaceCompletion) {
        guard isLineIdle else {
            completion(CallError.busy)
            return
        }
        requestRecordPermission { (granted) in
            guard granted else {
                completion(CallError.microphonePermissionDenied)
                return
            }
            if self.pendingIncomingUuid == nil, let call = self.service.pendingOffers[uuid]?.call {
                let user = call.opponentUser
                DispatchQueue.main.sync {
                    if UIApplication.shared.applicationState == .active {
                        try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                        try? AVAudioSession.sharedInstance().setCategory(.playback)
                        self.service.ringtonePlayer?.play()
                    } else {
                        NotificationManager.shared.requestCallNotification(messageId: call.uuidString, callerName: user.fullName)
                    }
                    self.service.showCallingInterface(user: user, style: .incoming)
                }
                self.pendingIncomingUuid = uuid
                completion(nil)
            } else {
                completion(CallError.busy)
            }
        }
    }
    
    func reportCall(uuid: UUID, endedByReason reason: CXCallEndedReason) {
        if uuid == pendingIncomingUuid {
            pendingIncomingUuid = nil
        }
        UNUserNotificationCenter.current().removeNotifications(withIdentifiers: [uuid.uuidString])
        DispatchQueue.main.sync(execute: service.dismissCallingInterface)
    }
    
    func reportOutgoingCallStartedConnecting(uuid: UUID) {
        if uuid == pendingIncomingUuid {
            pendingIncomingUuid = nil
        }
    }
    
    func reportOutgoingCall(uuid: UUID, connectedAtDate date: Date) {
        
    }
    
    func reportIncomingCall(uuid: UUID, connectedAtDate date: Date) {
        
    }
    
}
