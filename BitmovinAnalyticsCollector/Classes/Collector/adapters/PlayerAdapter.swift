import CoreMedia
import Foundation

protocol PlayerAdapter {
    func createEventData() -> EventData
    func initialize()
    func stopMonitoring()
    func destroy()
    func resetSourceState()
    var drmDownloadTime: Int64? { get }
    var currentTime: CMTime? { get }
    var currentSourceMetadata: SourceMetadata? { get }
}
