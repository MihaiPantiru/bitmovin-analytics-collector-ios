//
//  AdBreakMapper.swift
//  BitmovinAnalyticsCollector-iOS
//
//  Created by Thomas Sabe on 13.12.19.
//

import Foundation
import BitmovinPlayer
public class AdBreakMapper {
    
    func fromPlayerAdConfiguration(adConfiguration: AdConfig?) -> AnalyticsAdBreak {
        let collectorAdBreak = AnalyticsAdBreak(id: "notset",  ads: Array<AnalyticsAd>() );
        if(adConfiguration != nil){
            fromPlayerAdConfiguration(collectorAdBreak: collectorAdBreak, adConfiguration: adConfiguration!);
        }
        
        return collectorAdBreak;
    }
    
    func fromPlayerAdConfiguration(collectorAdBreak: AnalyticsAdBreak, adConfiguration: AdConfig){
        
if (!adConfiguration.replaceContentDuration.isNaN) {
            collectorAdBreak.replaceContentDuration = Int64(adConfiguration.replaceContentDuration * 1000)
        }
        
        
        if(adConfiguration is AdBreak) {
            fromPlayerAdBreak(collectorAdBreak: collectorAdBreak, playerAdBreak:adConfiguration as! AdBreak);
        }
    }
    
    func fromPlayerAdBreak(collectorAdBreak: AnalyticsAdBreak, playerAdBreak:AdBreak){
        
        var ads = Array<AnalyticsAd>();
        if(playerAdBreak.ads != nil && playerAdBreak.ads.count != 0){
            for ad in playerAdBreak.ads {
                ads.append(ad as! AnalyticsAd);
            }
        }
        
        collectorAdBreak.id = playerAdBreak.identifier;
        collectorAdBreak.ads = ads;
        
        collectorAdBreak.scheduleTime = Int64(playerAdBreak.scheduleTime);
        if(playerAdBreak is ImaAdBreak){
            fromImaAdBreak(collectorAdBreak: collectorAdBreak, imaAdBreak:  playerAdBreak as! ImaAdBreak);
        }
    }
    
    func fromImaAdBreak(collectorAdBreak: AnalyticsAdBreak, imaAdBreak: ImaAdBreak){
        collectorAdBreak.position = BitmovinPlayerUtil.getAdPositionFromString(string: imaAdBreak.position);
//        collectorAdBreak.fallbackIndex = Int(truncating: imaAdBreak.currentFallbackIndex ?? 0);
        collectorAdBreak.tagType = BitmovinPlayerUtil.getAdTagTypeFromAdTag(adTag: imaAdBreak.tag);
        collectorAdBreak.tagUrl = imaAdBreak.tag.url.absoluteString;
    }
    
}
