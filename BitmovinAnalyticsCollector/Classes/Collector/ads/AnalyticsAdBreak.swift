import Foundation

public class AnalyticsAdBreak {
    var id: String
    var ads: Array<AnalyticsAd>
    var position: AdPosition?
    var offset: String?
    var scheduleTime: Int64?
    var replaceContentDuration: Int64?
    var preloadOffset: Int64?
    var tagType: AdTagType?
    var tagUrl: String?
    var persistent: Bool?
    var fallbackIndex: Int = 0
    
    init(id: String, ads: Array<AnalyticsAd>) {
        self.id = id
        self.ads = ads
    }
}
