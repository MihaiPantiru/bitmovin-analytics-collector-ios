//
//  BitmovinAdAdapter.swift
//  Pods
//
//  Created by Thomas Sabe on 03.12.19.
//

import BitmovinPlayer
import Foundation
public class BitmovinAdAdapter: NSObject, AdAdapter{
    
    private var bitmovinPlayer: BitmovinPlayer
    private var adAnalytics: BitmovinAdAnalytics
    
    internal init(bitmovinPlayer: BitmovinPlayer, adAnalytics: BitmovinAdAnalytics){
        self.adAnalytics = adAnalytics;
        self.bitmovinPlayer = bitmovinPlayer;
        super.init()
        self.bitmovinPlayer.add(listener: self)
    }

    func releaseAdapter() {
        self.bitmovinPlayer.remove(listener: self)
    }
    
    func getModuleInformation()-> AdModuleInformation{
        let playerVersion = Util.playerVersion() ?? ""
        return AdModuleInformation(name: "DefaultAdvertisingService", version: playerVersion)
    }
    
    func isAutoPlayEnabled() -> Bool{
        self.bitmovinPlayer.config.playbackConfiguration.isAutoplayEnabled
    }
}

extension BitmovinAdAdapter : PlayerListener {
    public func onAdManifestLoaded(_ event: AdManifestLoadedEvent) {
        self.adAnalytics.onAdManifestLoaded()
    }
    
    public func onAdStarted(_ event: AdStartedEvent) {
        self.adAnalytics.onAdStarted()
    }
    
    public func onAdFinished(_ event: AdFinishedEvent) {
        self.adAnalytics.onAdFinished()
    }
    
    public func onAdBreakStarted(_ event: AdBreakStartedEvent) {
        self.adAnalytics.onAdBreakStarted()
    }
    
    public func onAdBreakFinished(_ event: AdBreakFinishedEvent) {
        self.adAnalytics.onAdBreakFinished()
    }
    
    public func onAdClicked(_ event: AdClickedEvent) {
        self.adAnalytics.onAdClicked(clickThroughUrl: event.clickThroughUrl?.absoluteString)
    }
    
    public func onAdSkipped(_ event: AdSkippedEvent) {
        self.adAnalytics.onAdSkipped()
    }
        
    public func onAdError(_ event: AdErrorEvent) {
        self.adAnalytics.onAdError(code: Int(event.code), message: event.message)
    }
}

