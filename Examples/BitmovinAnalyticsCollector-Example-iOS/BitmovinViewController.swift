import Foundation
import BitmovinPlayer
import BitmovinAnalyticsCollector
import UIKit

class BitmovinViewController: UIViewController {
    var player: Player?
    private var analyticsCollector: BitmovinPlayerCollector
    private var config: BitmovinAnalyticsConfig
    private let debugger: DebugBitmovinPlayerEvents = DebugBitmovinPlayerEvents()
    let url = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")
    let corruptedUrl = URL(string: "http://bitdash-a.akamaihd.net/content/analytics-teststreams/redbull-parkour/corrupted_first_segment.mpd")
    let liveSimUrl = URL(string: "https://bitcdn-kronehit.bitmovin.com/v2/hls/playlist.m3u8")!
    @IBOutlet var playerView: UIView!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var reloadButton: UIButton!
    @IBOutlet var sourceChangeButton: UIButton!

    deinit {
        player?.destroy()
    }

    required init?(coder aDecoder: NSCoder) {
        config = BitmovinAnalyticsConfig(key: "e73a3577-d91c-4214-9e6d-938fb936818a")
        config.cdnProvider = "custom_cdn_provider"
        config.customData1 = "customData1"
        config.customData2 = "customData2"
        config.customData3 = "customData3"
        config.customData4 = "customData4"
        config.customData5 = "customData5"
        config.customData6 = "customData6"
        config.customData7 = "customData7"
        config.customerUserId = "customUserId"
        config.experimentName = "experiment-1"
        config.videoId = "iOSHLSStaticBitmovin"
        config.title = "iOS HLS Static Asset with Bitmovin Player"
        config.path = "/vod/breadcrumb/"
        config.isLive = false
        config.ads = true
        analyticsCollector = BitmovinPlayerCollector(config: config)
        print("Setup of collector finished")

        super.init(coder: aDecoder)
    }
    
    static let AD_SOURCE_1 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dredirecterror&nofb=1&correlator=";
    static let AD_SOURCE_2 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator=";
    static let AD_SOURCE_3 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator=";
    static let AD_SOURCE_4 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dredirectlinear&correlator=";
    static let AD_SOURCE_5  = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dredirecterror&nofb=1&correlator=";
    static let AD_SOURCE_VMAP = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpostoptimizedpod&cmsid=496&vid=short_onecue&correlator=";

    
    func getAdvertisingConfiguration() -> AdvertisingConfiguration {
        let adScource1 = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_1), ofType: BMPAdSourceType.IMA)
        let adScource2 = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_2), ofType: BMPAdSourceType.IMA)
        let adScource3 = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_3), ofType: BMPAdSourceType.IMA)
        let adScource4 = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_4), ofType: BMPAdSourceType.IMA)
        let adScource5 = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_5), ofType: BMPAdSourceType.IMA)
        let adScourceVMAP = AdSource(tag: urlWithCorrelator(adTag: BitmovinViewController.AD_SOURCE_VMAP), ofType: BMPAdSourceType.IMA)
        
        let preRoll = AdItem(adSources: [adScource4], atPosition: "pre")
//        let midRoll = AdItem(adSources: [adScource], atPosition: "mid")
        let customMidRoll = AdItem(adSources: [adScource4], atPosition: "10%")
//        let postRoll = AdItem(adSources: [adScource], atPosition: "post")

        return AdvertisingConfiguration(schedule: [preRoll])
    }
    
    func urlWithCorrelator(adTag: String) -> URL {
        return URL(string: String(format: "%@%d", adTag, Int(arc4random_uniform(100000))))!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.playerView.backgroundColor = .black

        // Create player configuration
        guard let config = getPlayerConfig() else {
            return
        }
            
        // Create player based on player configuration
        let player = Player(configuration: config)

        player.add(listener: debugger)
        analyticsCollector.attachPlayer(player: player)
        // Create player view and pass the player instance to it
        let playerBoundary = BMPBitmovinPlayerView(player: player, frame: .zero)

        playerBoundary.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerBoundary.frame = playerView.bounds

        playerView.addSubview(playerBoundary)
        playerView.bringSubviewToFront(playerBoundary)

        self.player = player
    }
    
    func getPlayerConfig(enableAds: Bool = false) -> PlayerConfiguration? {
        guard let streamUrl = url else {
            return nil
        }
        
        // Create player configuration
        let config = PlayerConfiguration()
        
        if (enableAds) {
            config.advertisingConfiguration = getAdvertisingConfiguration()
        }
        
        do {
            try config.setSourceItem(url: streamUrl)
            
            config.playbackConfiguration.isMuted = true
            config.playbackConfiguration.isAutoplayEnabled = false
        } catch {
            
        }
        
        return config
    }

    override func viewWillAppear(_ animated: Bool) {
        // Add ViewController as event listener
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Remove ViewController as event listener
        super.viewWillDisappear(animated)
    }
    
    @IBAction func sourceChangeButtonWasPressed(_: UIButton) {
        analyticsCollector.detachPlayer()
        player!.unload()
        
        config.title = "New video Title"
        let sourceConfig = SourceConfiguration()
        do {
            try sourceConfig.addSourceItem(url: liveSimUrl)
        }
        catch {}
        analyticsCollector.attachPlayer(player: self.player!)
        self.player!.load(sourceConfiguration: sourceConfig)
    }

    @IBAction func doneButtonWasPressed(_: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func reloadButtonWasPressed(_: UIButton) {
        analyticsCollector.detachPlayer()

        guard let player = player else {
            return
        }

        guard let config = getPlayerConfig() else {
            return
        }
        
        // Create player based on player configuration
        self.player?.load(sourceConfiguration: config.sourceConfiguration)

        analyticsCollector.attachPlayer(player: player)
    }
}
