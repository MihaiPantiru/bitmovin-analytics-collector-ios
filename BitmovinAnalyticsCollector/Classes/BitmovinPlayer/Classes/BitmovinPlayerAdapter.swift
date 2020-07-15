import Foundation
import BitmovinPlayer

class BitmovinPlayerAdapter: CorePlayerAdapter, PlayerAdapter {
    private let config: BitmovinAnalyticsConfig
    private var player: BitmovinPlayer
    private var errorCode: Int?
    private var errorMessage: String?
    private var isStalling: Bool
    private var isSeeking: Bool

    init(player: BitmovinPlayer, config: BitmovinAnalyticsConfig, stateMachine: StateMachine) {
        self.player = player
        self.config = config
        self.isStalling = false
        self.isSeeking = false
        super.init(stateMachine: stateMachine)
        self.delegate = self
        startMonitoring()
    }

    func createEventData() -> EventData {
        let eventData: EventData = EventData(config: config, impressionId: stateMachine.impressionId)
        decorateEventData(eventData: eventData)
        return eventData
    }
    
    
    private func decorateEventData(eventData: EventData) {
        //PlayerType
        eventData.player = PlayerType.bitmovin.rawValue

        //PlayerTech
        eventData.playerTech = "ios:bitmovin"

        //ErrorCode
        eventData.errorCode = errorCode
        eventData.errorMessage = errorMessage

        //Duration
        if !player.duration.isNaN && !player.duration.isInfinite {
            eventData.videoDuration = Int64(player.duration * BitmovinAnalyticsInternal.msInSec)
        }

        //isCasting
        eventData.isCasting = player.isCasting

        //isLive
        eventData.isLive = self.isPlayerReady ? player.isLive : self.config.isLive

        //version
        if let sdkVersion = BitmovinPlayerUtil.playerVersion() {
            eventData.version = PlayerType.bitmovin.rawValue + "-" + sdkVersion
        }
        
        let sourceUrl = player.config.sourceItem?.url(forType: player.streamType)
        switch player.streamType {
        case .DASH:
            eventData.streamFormat = StreamType.dash.rawValue
            eventData.mpdUrl = sourceUrl?.absoluteString
        case .HLS:
            eventData.streamFormat = StreamType.hls.rawValue
            eventData.m3u8Url = sourceUrl?.absoluteString
        case .progressive:
            eventData.streamFormat = StreamType.progressive.rawValue
            eventData.progUrl = sourceUrl?.absoluteString
        default: break;
        }

        // videoBitrate
        if let bitrate = player.videoQuality?.bitrate {
            eventData.videoBitrate = Double(bitrate)
        }

        // videoPlaybackWidth
        if let videoPlaybackWidth = player.videoQuality?.width {
            eventData.videoPlaybackWidth = Int(videoPlaybackWidth)
        }

        // videoPlaybackHeight
        if let videoPlaybackHeight = player.videoQuality?.height {
            eventData.videoPlaybackHeight = Int(videoPlaybackHeight)
        }
        
        // videoCodec
        if let videoCodec = player.videoQuality?.codec {
            eventData.videoCodec = String(videoCodec)
        }

        let scale = UIScreen.main.scale
        // screenHeight
        eventData.screenHeight = Int(UIScreen.main.bounds.size.height * scale)

        // screenWidth
        eventData.screenWidth = Int(UIScreen.main.bounds.size.width * scale)

        // isMuted
        eventData.isMuted = player.isMuted
        
        eventData.subtitleEnabled = player.subtitle.identifier != "off"
        if eventData.subtitleEnabled! {
            eventData.subtitleLanguage = player.subtitle.language ?? player.subtitle.label
        }

        eventData.audioLanguage = player.audio?.language
        
        if (stateMachine.videoStartFailed) {
            eventData.videoStartFailed = stateMachine.videoStartFailed
            eventData.videoStartFailedReason = stateMachine.videoStartFailedReason ?? VideoStartFailedReason.unknown
            stateMachine.resetVideoStartFailed()
        }
    }

    func startMonitoring() {
        player.add(listener: self)
    }

    func stopMonitoring() {
        player.remove(listener: self)
        isStalling = false
    }
    
    var currentTime: CMTime? {
        get {
            return Util.timeIntervalToCMTime(_: player.currentTime)
        }
    }
}

extension BitmovinPlayerAdapter: PlayerListener {
    func onPlay(_ event: PlayEvent) {
        print("onPlay")
        stateMachine.play(time: nil)
        
        if (isStalling && stateMachine.state != .seeking && stateMachine.state != .buffering) {
             stateMachine.transitionState(destinationState: .buffering, time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }

    func onAdBreakStarted(_ event: AdBreakStartedEvent) {
        stateMachine.transitionState(destinationState: .ad, time: currentTime)
    }
    
    func onAdBreakFinished(_ event: AdBreakFinishedEvent) {
        stateMachine.transitionState(destinationState: .adFinished, time: currentTime)
    }
    
    func onPaused(_ event: PausedEvent) {
        isSeeking = false
        stateMachine.pause(time: currentTime)
    }

    func onReady(_ event: ReadyEvent) {
        print("onReady")
        self.isPlayerReady = true
    }

    func onStallStarted(_ event: StallStartedEvent) {
        isStalling = true
        stateMachine.transitionState(destinationState: .buffering, time: Util.timeIntervalToCMTime(_: player.currentTime))
        
    }

    func onStallEnded(_ event: StallEndedEvent) {
        isStalling = false
        transitionToPausedOrBufferingOrPlaying()
    }

    func onSeek(_ event: SeekEvent) {
        isSeeking = true
        stateMachine.transitionState(destinationState: .seeking, time: Util.timeIntervalToCMTime(_: player.currentTime))
    }

    func didVideoBitrateChange(old: VideoQuality?, new: VideoQuality?) -> Bool {
        return old?.bitrate != new?.bitrate
    }

    func onVideoDownloadQualityChanged(_ event: VideoDownloadQualityChangedEvent) {
        let videoBitrateDidChange = didVideoBitrateChange(old: event.videoQualityOld, new: event.videoQualityNew)
        if (!isStalling && !isSeeking && videoBitrateDidChange) {
            stateMachine.transitionState(destinationState: .qualitychange, time: Util.timeIntervalToCMTime(_: player.currentTime))
            transitionToPausedOrBufferingOrPlaying()
        }
    }

    func onSeeked(_ event: SeekedEvent) {
        isSeeking = false
        if (!isStalling){
            transitionToPausedOrBufferingOrPlaying()
        }
    }

    func onPlaybackFinished(_ event: PlaybackFinishedEvent) {
        stateMachine.transitionState(destinationState: .paused, time: Util.timeIntervalToCMTime(_: player.duration))
        stateMachine.disableHeartbeat()
    }

    func onError(_ event: ErrorEvent) {
        errorCode = Int(event.code)
        errorMessage = event.message
        if (!stateMachine.didStartPlayingVideo) {
            stateMachine.setVideoStartFailed(withReason: VideoStartFailedReason.playerError)
        }
        stateMachine.transitionState(destinationState: .error, time: Util.timeIntervalToCMTime(_: player.currentTime))
    }

    func transitionToPausedOrBufferingOrPlaying() {
        if(!stateMachine.didStartPlayingVideo) {
            return
        }
        
        if isStalling {
            // Player reports isPlaying=true although onStallEnded has not been called yet -- still stalling
            stateMachine.transitionState(destinationState: .buffering, time: Util.timeIntervalToCMTime(_: player.currentTime))
        } else if player.isPaused {
            stateMachine.transitionState(destinationState: .paused, time: Util.timeIntervalToCMTime(_: player.currentTime))
        } else {
            stateMachine.transitionState(destinationState: .playing, time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }
    
    func onSourceWillUnload(_ event: SourceWillUnloadEvent) {
        if (!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.onPlayAttemptFailed(withReason: VideoStartFailedReason.pageClosed, time: delegate.currentTime)
        }
    }
    
    func onSourceUnloaded(_ event: SourceUnloadedEvent) {
        stateMachine.reset()
    }
    
    func onSubtitleChanged(_ event: SubtitleChangedEvent) {
        guard stateMachine.state == .paused || stateMachine.state == .playing else {
            return
        }
        stateMachine.transitionState(destinationState: .subtitlechange, time: Util.timeIntervalToCMTime(_: player.currentTime))
        transitionToPausedOrBufferingOrPlaying()
    }

    func onAudioChanged(_ event: AudioChangedEvent) {
        guard stateMachine.state == .paused || stateMachine.state == .playing else {
            return
        }
        stateMachine.transitionState(destinationState: .audiochange, time: Util.timeIntervalToCMTime(_: player.currentTime))
        transitionToPausedOrBufferingOrPlaying()
    }
    
    func onPlaying(_ event: PlayingEvent) {
        if (!isSeeking && !isStalling) {
            stateMachine.playing(time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }
}
