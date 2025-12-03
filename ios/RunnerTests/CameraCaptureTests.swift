import XCTest
import AVFoundation
@testable import Runner

/// Property-based tests for CameraCapture
/// Feature: ip-camera-streaming-platform, Property 16: Camera enumeration returns all available cameras
/// Feature: ip-camera-streaming-platform, Property 17: Each camera has valid identifier and type
/// Validates: Requirements 5.2, 5.3
class CameraCaptureTests: XCTestCase {
    
    var cameraCapture: CameraCapture!
    
    override func setUp() {
        super.setUp()
        cameraCapture = CameraCapture()
    }
    
    override func tearDown() {
        cameraCapture = nil
        super.tearDown()
    }
    
    // MARK: - Property 16: Camera enumeration returns all available cameras
    
    func testCameraEnumerationReturnsAllAvailableCameras() {
        // Get cameras from our implementation
        let enumeratedCameras = cameraCapture.enumerateCameras()
        
        // Get cameras directly from AVFoundation
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInTelephotoCamera,
                .builtInUltraWideCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera
            ],
            mediaType: .video,
            position: .unspecified
        )
        let systemCameras = discoverySession.devices
        
        // Property: The number of enumerated cameras should match the system's camera count
        XCTAssertEqual(
            enumeratedCameras.count,
            systemCameras.count,
            "Camera enumeration should return all available cameras. Expected \(systemCameras.count), got \(enumeratedCameras.count)"
        )
        
        // Property: Every system camera should be present in our enumeration
        for systemCamera in systemCameras {
            let found = enumeratedCameras.contains { camera in
                guard let id = camera["id"] as? String else { return false }
                return id == systemCamera.uniqueID
            }
            XCTAssertTrue(
                found,
                "Camera with ID \(systemCamera.uniqueID) should be in enumerated cameras"
            )
        }
        
        // Property: No duplicate cameras should be returned
        let cameraIds = enumeratedCameras.compactMap { $0["id"] as? String }
        let uniqueIds = Set(cameraIds)
        XCTAssertEqual(
            cameraIds.count,
            uniqueIds.count,
            "Camera enumeration should not contain duplicates"
        )
    }
    
    // MARK: - Property 17: Each camera has valid identifier and type
    
    func testEachCameraHasValidIdentifierAndType() {
        let cameras = cameraCapture.enumerateCameras()
        
        // Property: For all cameras, each must have a valid identifier and type
        for (index, camera) in cameras.enumerated() {
            // Property: Camera must have an ID
            guard let id = camera["id"] as? String else {
                XCTFail("Camera at index \(index) missing 'id' field")
                continue
            }
            
            // Property: ID must be non-empty
            XCTAssertFalse(
                id.isEmpty,
                "Camera at index \(index) has empty ID"
            )
            
            // Property: Camera must have a name
            guard let name = camera["name"] as? String else {
                XCTFail("Camera at index \(index) missing 'name' field")
                continue
            }
            
            // Property: Name must be non-empty
            XCTAssertFalse(
                name.isEmpty,
                "Camera at index \(index) has empty name"
            )
            
            // Property: Camera must have a position
            guard let position = camera["position"] as? String else {
                XCTFail("Camera at index \(index) missing 'position' field")
                continue
            }
            
            // Property: Position must be one of the valid types
            let validPositions = ["front", "back", "external"]
            XCTAssertTrue(
                validPositions.contains(position),
                "Camera at index \(index) has invalid position '\(position)'. Must be one of: \(validPositions)"
            )
            
            // Property: Camera must have capabilities array
            guard let capabilities = camera["capabilities"] as? [String] else {
                XCTFail("Camera at index \(index) missing 'capabilities' field or wrong type")
                continue
            }
            
            // Property: Capabilities should be valid strings (can be empty array)
            XCTAssertTrue(
                capabilities.allSatisfy { !$0.isEmpty },
                "Camera at index \(index) has empty capability strings"
            )
        }
    }
    
    // MARK: - Additional Property Tests
    
    func testCameraEnumerationIsConsistent() {
        // Property: Multiple calls to enumerate should return the same cameras
        let firstEnumeration = cameraCapture.enumerateCameras()
        let secondEnumeration = cameraCapture.enumerateCameras()
        
        XCTAssertEqual(
            firstEnumeration.count,
            secondEnumeration.count,
            "Camera enumeration should be consistent across calls"
        )
        
        // Check that the same camera IDs are present
        let firstIds = Set(firstEnumeration.compactMap { $0["id"] as? String })
        let secondIds = Set(secondEnumeration.compactMap { $0["id"] as? String })
        
        XCTAssertEqual(
            firstIds,
            secondIds,
            "Camera IDs should be consistent across enumerations"
        )
    }
    
    func testCameraResolutionEnumeration() {
        let cameras = cameraCapture.enumerateCameras()
        
        // Property: For any camera, resolution enumeration should return valid resolutions
        for camera in cameras {
            guard let cameraId = camera["id"] as? String else { continue }
            
            let resolutions = cameraCapture.getResolutions(cameraId: cameraId)
            
            // Property: Each resolution must have width and height
            for resolution in resolutions {
                guard let width = resolution["width"] as? Int else {
                    XCTFail("Resolution for camera \(cameraId) missing width")
                    continue
                }
                
                guard let height = resolution["height"] as? Int else {
                    XCTFail("Resolution for camera \(cameraId) missing height")
                    continue
                }
                
                // Property: Width and height must be positive
                XCTAssertGreaterThan(width, 0, "Resolution width must be positive")
                XCTAssertGreaterThan(height, 0, "Resolution height must be positive")
                
                // Property: Common resolutions should be present if supported
                // (720p, 1080p, 4K)
                let isCommonResolution = (width == 1280 && height == 720) ||
                                        (width == 1920 && height == 1080) ||
                                        (width == 3840 && height == 2160)
                
                if !isCommonResolution {
                    // If not a common resolution, it should still be valid
                    XCTAssertTrue(
                        width >= 640 && height >= 480,
                        "Non-standard resolution should be at least 640x480"
                    )
                }
            }
        }
    }
    
    func testInvalidCameraIdReturnsEmptyResolutions() {
        // Property: For any invalid camera ID, resolution enumeration should return empty array
        let invalidIds = ["", "invalid-id", "12345", "nonexistent"]
        
        for invalidId in invalidIds {
            let resolutions = cameraCapture.getResolutions(cameraId: invalidId)
            XCTAssertTrue(
                resolutions.isEmpty,
                "Invalid camera ID '\(invalidId)' should return empty resolutions"
            )
        }
    }
}
