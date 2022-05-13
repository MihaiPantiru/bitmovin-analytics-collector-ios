import Foundation
import XCTest

#if !SWIFT_PACKAGE
@testable import BitmovinAnalyticsCollector
#endif

#if SWIFT_PACKAGE
@testable import CoreCollector
#endif


class DownloadSpeedMeterTest: XCTestCase {
    
    func testAdd_should_addNewItem() throws {
        // arrange
        let dsm = DownloadSpeedMeter()
        let measurement = SpeedMeasurement()
        
        // act
        dsm.add(measurement: measurement)
        
        // assert
        XCTAssertEqual(dsm.measures.count, 1)
    }
    
    func testReset_should_removeAllItems() throws  {
        // arrange
        let dsm = DownloadSpeedMeter()
        let measurement = SpeedMeasurement()
        dsm.add(measurement: measurement)
        XCTAssertEqual(dsm.measures.count, 1)
        
        // act
        dsm.reset()
        
        // assert
        XCTAssertEqual(dsm.measures.count, 0)
    }
    
    func testGetInfo_should_returnZeroValues_when_noMeasurements() throws {
        // arrange
        let dsm = DownloadSpeedMeter()
        
        // act
        let info = dsm.getInfo()
        
        // assert
        XCTAssertEqual(info.segmentsDownloadSize, 0)
        XCTAssertEqual(info.segmentsDownloadTime, 0)
        XCTAssertEqual(info.segmentsDownloadCount, 0)
    }
    
    func testGetInfo_should_returnCorrectValues() throws  {
        // arrange
        let dsm = DownloadSpeedMeter()
        var measurement = SpeedMeasurement()
        measurement.size = 50
        measurement.duration = 1000
        measurement.segmentCount = 1
        dsm.add(measurement: measurement)
        
        var measurement2 = SpeedMeasurement()
        measurement2.size = 100
        measurement2.duration = 1000
        measurement2.segmentCount = 2
        dsm.add(measurement: measurement2)
        
        // act
        let info = dsm.getInfo()
        
        // assert
        XCTAssertEqual(info.segmentsDownloadSize, 150)
        XCTAssertEqual(info.segmentsDownloadTime, 2000)
        XCTAssertEqual(info.segmentsDownloadCount, 3)
    }
}
