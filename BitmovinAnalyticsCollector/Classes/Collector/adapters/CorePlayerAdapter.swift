import Foundation

class CorePlayerAdapter: NSObject {
    internal var stateMachine: StateMachine
    internal var isPlayerReady: Bool
    private var isDestroyed = false
    
    internal var delegate: PlayerAdapter?
    
    init(stateMachine: StateMachine){
        self.stateMachine = stateMachine
        self.isPlayerReady = false
        
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForegroundNotification(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func destroy() {
        guard !isDestroyed else {
            return
        }
        isDestroyed = true
        self.delegate?.stopMonitoring()
        
        if (!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.onPlayAttemptFailed(withReason: VideoStartFailedReason.pageClosed)
        }
        
        self.isPlayerReady = false
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc func willResignActive(notification _: Notification){
        stateMachine.clearVideoStartFailedTimer()
    }
    
    @objc func willEnterForegroundNotification(notification _: Notification){
        if(!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.startVideoStartFailedTimer()
        }
    }
    
}
