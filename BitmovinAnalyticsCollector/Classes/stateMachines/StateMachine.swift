//
//  StateMachine.swift
//  BitmovinAnalyticsCollector
//
//  Created by Cory Zachman on 1/10/18.
//  Copyright © 2018 Bitmovin. All rights reserved.
//

import AVFoundation
import Foundation

public class StateMachine {
    private(set) var state: PlayerStateEnum
    private var config: BitmovinAnalyticsConfig
    private var initialTimestamp: Int
    private(set) var enterTimestamp: Int?
    var potentialSeekStart: Int = 0
    var potentialSeekVideoTimeStart: CMTime?
    var firstReadyTimestamp: Int = 0
    private(set) var videoTimeStart: CMTime?
    private(set) var videoTimeEnd: CMTime?
    private(set) var impressionId: String
    weak var delegate: StateMachineDelegate?
    private var heartbeatTimer: Timer?

    var startupTime: Int {
        return firstReadyTimestamp - initialTimestamp
    }

    init(config: BitmovinAnalyticsConfig) {
        self.config = config
        state = .setup
        initialTimestamp = Date().timeIntervalSince1970Millis
        impressionId = NSUUID().uuidString
    }

    public func reset() {
        impressionId = NSUUID().uuidString
        initialTimestamp = Date().timeIntervalSince1970Millis
        disableHeartbeat()
        state = .setup
    }

    public func transitionState(destinationState: PlayerStateEnum, time: CMTime?) {
        if state == destinationState {
            return
        } else {
            let timestamp = Date().timeIntervalSince1970Millis
            videoTimeEnd = time
            state.onExit(stateMachine: self, timestamp: timestamp, destinationState: destinationState)
            state = destinationState
            enterTimestamp = timestamp
            videoTimeStart = videoTimeEnd
            state.onEntry(stateMachine: self, timestamp: timestamp, destinationState: destinationState)
        }
    }

    public func confirmSeek() {
        enterTimestamp = potentialSeekStart
        videoTimeStart = potentialSeekVideoTimeStart
    }

    func enableHeartbeat() {
        let interval = Double(config.heartbeatInterval) / 1000.0
        heartbeatTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(StateMachine.onHeartbeat), userInfo: nil, repeats: true)
    }

    func disableHeartbeat() {
        heartbeatTimer?.invalidate()
    }

    @objc func onHeartbeat() {
        let timestamp = Date().timeIntervalSince1970Millis
        guard let enterTime = enterTimestamp else {
            return
        }
        delegate?.heartbeatFired(duration: timestamp - enterTime)
        enterTimestamp = timestamp
    }
}
