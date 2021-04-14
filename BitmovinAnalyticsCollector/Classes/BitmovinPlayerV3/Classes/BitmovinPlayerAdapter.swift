import BitmovinPlayer

class BitmovinPlayerAdapter: CorePlayerAdapter, PlayerAdapter {
    private let config: BitmovinAnalyticsConfig
    private var player: Player
    internal var drmPerformanceInfo: DrmPerformanceInfo?
    private var isStalling: Bool
    private var isSeeking: Bool
    /// DRM certificate download time in milliseconds
    private var drmCertificateDownloadTime: Int64?
    private var isMonitoring = false

    init(player: Player, config: BitmovinAnalyticsConfig, stateMachine: StateMachine) {
        self.player = player
        self.config = config
        self.isStalling = false
        self.isSeeking = false
        super.init(stateMachine: stateMachine)
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

        //isCasting
        eventData.isCasting = player.isCasting

        //version
        if let sdkVersion = BitmovinPlayerUtil.playerVersion() {
            eventData.version = PlayerType.bitmovin.rawValue + "-" + sdkVersion
        }
        
        if let source = player.source {
            let sourceConfig = source.sourceConfig
            // streamFormat & urls
            switch sourceConfig.type {
                case SourceType.dash:
                    eventData.streamFormat = StreamType.dash.rawValue
                    eventData.mpdUrl = sourceConfig.url.absoluteString
                case SourceType.hls:
                    eventData.streamFormat = StreamType.hls.rawValue
                    eventData.m3u8Url = sourceConfig.url.absoluteString
                case SourceType.progressive:
                    eventData.streamFormat = StreamType.progressive.rawValue
                    eventData.progUrl = sourceConfig.url.absoluteString
                default: break;
            }
            
            // isLive & duration
            let duration = source.duration
            if (duration == 0) {
                eventData.isLive = config.isLive
            } else {
                if (duration.isInfinite) {
                    eventData.isLive = true;
                } else {
                    eventData.isLive = false;
                    eventData.videoDuration = duration.milliseconds ?? 0
                }
            }
            
            // drmType
            if let drmConfig = sourceConfig.drmConfig {
                if (drmConfig is WidevineConfig) {
                    eventData.drmType = DrmType.widevine.rawValue
                } else if (drmConfig is PlayReadyConfig) {
                    eventData.drmType = DrmType.playready.rawValue
                } else if (drmConfig is FairplayConfig) {
                    eventData.drmType = DrmType.fairplay.rawValue
                } else if (drmConfig is ClearKeyConfig) {
                    eventData.drmType = DrmType.clearkey.rawValue
                }
            }
        } else {
            // player active Source is not available
            eventData.isLive = config.isLive
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
    }

    func startMonitoring() {
        if isMonitoring {
            stopMonitoring()
        }
        isMonitoring = true
        player.add(listener: self)
    }

    override func stopMonitoring() {
        guard isMonitoring else {
            return
        }
        player.remove(listener: self)
        isStalling = false
    }
    
    func getDrmPerformanceInfo() -> DrmPerformanceInfo? {
        return self.drmPerformanceInfo
    }
    
    var currentTime: CMTime? {
        get {
            return Util.timeIntervalToCMTime(_: player.currentTime)
        }
    }
    
    func onErrorEvent(_ errorData: ErrorData) {
        if (!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.onPlayAttemptFailed(withError: errorData)
        } else {
            stateMachine.error(withError: errorData, time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }
}

extension BitmovinPlayerAdapter: PlayerListener {
    func onPlay(_ event: PlayEvent, player: Player) {
        stateMachine.play(time: nil)
        
        if (isStalling && stateMachine.state != .seeking && stateMachine.state != .buffering) {
             stateMachine.transitionState(destinationState: .buffering, time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }
    
    func onPlaying(_ event: PlayingEvent, player: Player) {
        if (!isSeeking && !isStalling) {
            stateMachine.playing(time: Util.timeIntervalToCMTime(_: player.currentTime))
        }
    }

    func onAdBreakStarted(_ event: AdBreakStartedEvent, player: Player) {
        stateMachine.transitionState(destinationState: .ad, time: currentTime)
    }
    
    func onAdBreakFinished(_ event: AdBreakFinishedEvent, player: Player) {
        stateMachine.transitionState(destinationState: .adFinished, time: currentTime)
    }
    
    func onPaused(_ event: PausedEvent, player: Player) {
        isSeeking = false
        stateMachine.pause(time: currentTime)
    }

    func onReady(_ event: ReadyEvent, player: Player) {
        self.isPlayerReady = true
    }

    func onStallStarted(_ event: StallStartedEvent, player: Player) {
        isStalling = true
        stateMachine.transitionState(destinationState: .buffering, time: Util.timeIntervalToCMTime(_: player.currentTime))
        
    }

    func onStallEnded(_ event: StallEndedEvent, player: Player) {
        isStalling = false
        transitionToPausedOrBufferingOrPlaying()
    }

    func onSeek(_ event: SeekEvent, player: Player) {
        isSeeking = true
        stateMachine.transitionState(destinationState: .seeking, time: Util.timeIntervalToCMTime(_: player.currentTime))
    }

    func onDownloadFinished(_ event: DownloadFinishedEvent, player: Player) {
        let downloadTimeInMs = event.downloadTime.milliseconds

        switch event.downloadType {
        case BMPHttpRequestTypeDrmCertificateFairplay:
            // This request is the first that happens when initializing the DRM system
            self.drmCertificateDownloadTime = downloadTimeInMs
        case BMPHttpRequestTypeDrmLicenseFairplay:
            let drmLoadTimeMs = (self.drmCertificateDownloadTime ?? 0) + (downloadTimeInMs ?? 0)
            self.drmPerformanceInfo = DrmPerformanceInfo(drmType: DrmType.fairplay.rawValue, drmLoadTime: drmLoadTimeMs)
            self.drmCertificateDownloadTime = nil
        default:
            return
        }
    }

    func didVideoBitrateChange(old: VideoQuality?, new: VideoQuality?) -> Bool {
        return old?.bitrate != new?.bitrate
    }

    func onVideoDownloadQualityChanged(_ event: VideoDownloadQualityChangedEvent, player: Player) {
        let videoBitrateDidChange = didVideoBitrateChange(old: event.videoQualityOld, new: event.videoQualityNew)
        // there is a qualityChange event happening before the `onReady` method. Do not transition into any state.
        if isPlayerReady && !isStalling && !isSeeking && videoBitrateDidChange {
            stateMachine.videoQualityChange(time: currentTime)
            transitionToPausedOrBufferingOrPlaying()
        }
    }
    
    // No check if audioBitrate changes because no data available
    func onAudioChanged(_ event: AudioChangedEvent, player: Player) {
        if isPlayerReady && !isStalling && !isSeeking {
            stateMachine.audioQualityChange(time: currentTime)
            transitionToPausedOrBufferingOrPlaying()
        }
    }

    func onSeeked(_ event: SeekedEvent, player: Player) {
        isSeeking = false
        if (!isStalling) {
            transitionToPausedOrBufferingOrPlaying()
        }
    }

    func onPlaybackFinished(_ event: PlaybackFinishedEvent, player: Player) {
        stateMachine.transitionState(destinationState: .paused, time: Util.timeIntervalToCMTime(_: player.duration))
        stateMachine.disableHeartbeat()
    }

    func onPlayerError(_ event: PlayerErrorEvent, player: Player) {
        let errorData = ErrorData(code: Int(event.code.rawValue), message: event.message, data: nil)
        onErrorEvent(errorData)
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
    
    func onSourceUnload(_ event: SourceUnloadEvent, player: Player) {
        if (!stateMachine.didStartPlayingVideo && stateMachine.didAttemptPlayingVideo) {
            stateMachine.onPlayAttemptFailed(withReason: VideoStartFailedReason.pageClosed)
        }
    }
    
    func onSourceUnloaded(_ event: SourceUnloadedEvent, player: Player) {
        stateMachine.reset()
    }
    
    func onSubtitleChanged(_ event: SubtitleChangedEvent, player: Player) {
        guard stateMachine.state == .paused || stateMachine.state == .playing else {
            return
        }
        stateMachine.transitionState(destinationState: .subtitlechange, time: Util.timeIntervalToCMTime(_: player.currentTime))
        transitionToPausedOrBufferingOrPlaying()
    }

}

extension BitmovinPlayerAdapter: SourceListener {
    func onSourceError(_ event: SourceErrorEvent, player: Player) {
        let errorData = ErrorData(code: Int(event.code.rawValue), message: event.message, data: nil)
        onErrorEvent(errorData)
    }
}
