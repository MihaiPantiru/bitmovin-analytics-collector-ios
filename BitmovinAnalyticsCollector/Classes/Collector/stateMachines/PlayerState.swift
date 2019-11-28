import Foundation

public enum PlayerState: String {
    case setup
    case buffering
    case error
    case playing
    case paused
    case qualitychange
    case seeking
    case subtitlechange
    case audiochange

    func onEntry(stateMachine: StateMachine, timestamp _: Int64, destinationState _: PlayerState, data: [AnyHashable: Any]?) {
        switch self {
        case .setup:
            return
        case .buffering:
            return
        case .error:
            stateMachine.delegate?.stateMachineDidEnterError(stateMachine, data: data)
            return
        case .playing, .paused:
            if stateMachine.firstReadyTimestamp == nil {
                stateMachine.firstReadyTimestamp = Date().timeIntervalSince1970Millis
                stateMachine.delegate?.stateMachine(stateMachine, didStartupWithDuration: stateMachine.startupTime)
            }
            if (self == .playing){
                stateMachine.enableHeartbeat()
            }
            return
        case .qualitychange:
            return
        case .seeking:
            return
        case .subtitlechange:
            return
        case .audiochange:
            return
        }
    }

    func onExit(stateMachine: StateMachine, timestamp: Int64, destinationState: PlayerState) {
        // Get the duration we were in the state we are exiting
        let enterTimestamp = stateMachine.enterTimestamp ?? 0
        let duration = timestamp - enterTimestamp

        switch self {
        case .setup:
            stateMachine.delegate?.stateMachineDidExitSetup(stateMachine)
            return
        case .buffering:
            stateMachine.delegate?.stateMachine(stateMachine, didExitBufferingWithDuration: duration)
            return
        case .error:
            return
        case .playing:
            stateMachine.delegate?.stateMachine(stateMachine, didExitPlayingWithDuration: duration)
            stateMachine.disableHeartbeat()
            return
        case .paused:
            stateMachine.delegate?.stateMachine(stateMachine, didExitPauseWithDuration: duration)
            return
        case .qualitychange:
            stateMachine.delegate?.stateMachineDidQualityChange(stateMachine)
            return
        case .seeking:
            stateMachine.delegate?.stateMachine(stateMachine, didExitSeekingWithDuration: duration, destinationPlayerState: destinationState)
            return
        case .subtitlechange:
            stateMachine.delegate?.stateMachineDidSubtitleChange(stateMachine)
            return
        case .audiochange:
            stateMachine.delegate?.stateMachineDidAudioChange(stateMachine)
            return
        }
    }
}
