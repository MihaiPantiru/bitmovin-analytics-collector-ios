@objc
@objcMembers
public class SourceMetadata: NSObject {
    @objc public init(videoId: String? = nil, title: String? = nil, path: String? = nil, cdnProvider: String? = nil, customData1: String? = nil, customData2: String? = nil, customData3: String? = nil, customData4: String? = nil, customData5: String? = nil, customData6: String? = nil, customData7: String? = nil, experimentName: String? = nil) {
        self.videoId = videoId
        self.title = title
        self.path = path
        self.isLive = nil
        self.cdnProvider = cdnProvider
        self.customData1 = customData1
        self.customData2 = customData2
        self.customData3 = customData3
        self.customData4 = customData4
        self.customData5 = customData5
        self.customData6 = customData6
        self.customData7 = customData7
        self.experimentName = experimentName
    }
    
    public init(videoId: String? = nil, title: String? = nil, path: String? = nil, isLive: Bool? = nil, cdnProvider: String? = nil, customData1: String? = nil, customData2: String? = nil, customData3: String? = nil, customData4: String? = nil, customData5: String? = nil, customData6: String? = nil, customData7: String? = nil, experimentName: String? = nil) {
        self.videoId = videoId
        self.title = title
        self.path = path
        self.isLive = isLive
        self.cdnProvider = cdnProvider
        self.customData1 = customData1
        self.customData2 = customData2
        self.customData3 = customData3
        self.customData4 = customData4
        self.customData5 = customData5
        self.customData6 = customData6
        self.customData7 = customData7
        self.experimentName = experimentName
    }
    
    /**
     * ID of the video in the CMS system
     */
    @objc public private(set) var videoId: String?

    /**
     * Human readable title of the video asset currently playing
     */
    @objc public private(set) var title: String?
    
    /**
     * Breadcrumb path to show where in the app the user is
     */
    @objc public private(set) var path: String?

    /**
     * Flag to see if stream is live before stream metadata is available (default: false)
     */
    public private(set) var isLive: Bool?
    
    /**
     * CDN Provide that the video playback session is using
     */
    @objc public private(set) var cdnProvider: String?

    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData1: String?

    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData2: String?

    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData3: String?

    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData4: String?

    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData5: String?
    
    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData6: String?
    
    /**
     * Optional free-form custom data
     */
    @objc public private(set) var customData7: String?
    
    /**
     * Experiment name needed for A/B testing
     */
    @objc public private(set) var experimentName: String?
    
}
