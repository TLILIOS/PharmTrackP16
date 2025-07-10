//import XCTest
//import SwiftUI
//@testable import MediStock
//
//final class ColorExtensionsTests: XCTestCase {
//    
//    func testInitFromValidHexString() {
//        let color1 = Color(hex: "#FF0000")
//        XCTAssertNotNil(color1)
//        
//        let color2 = Color(hex: "00FF00")
//        XCTAssertNotNil(color2)
//        
//        let color3 = Color(hex: "#0000FF")
//        XCTAssertNotNil(color3)
//        
//        let color4 = Color(hex: "FFFFFF")
//        XCTAssertNotNil(color4)
//        
//        let color5 = Color(hex: "#000000")
//        XCTAssertNotNil(color5)
//    }
//    
//    func testInitFromInvalidHexString() {
//        let color1 = Color(hex: "invalid")
//        XCTAssertNil(color1)
//        
//        let color2 = Color(hex: "#ZZZZZZ")
//        XCTAssertNil(color2)
//        
//        let color3 = Color(hex: "")
//        XCTAssertNil(color3)
//        
//        let color4 = Color(hex: "#")
//        XCTAssertNil(color4)
//        
//        let color5 = Color(hex: "#FF")
//        XCTAssertNil(color5)
//        
//        let color6 = Color(hex: "#FFFF")
//        XCTAssertNil(color6)
//    }
//    
//    func testInitFromHexStringWithWhitespace() {
//        let color1 = Color(hex: " #FF0000 ")
//        XCTAssertNotNil(color1)
//        
//        let color2 = Color(hex: "\t00FF00\n")
//        XCTAssertNotNil(color2)
//        
//        let color3 = Color(hex: "  0000FF  ")
//        XCTAssertNotNil(color3)
//    }
//    
//    func testInitFromShortHexString() {
//        // These should fail as they're not 6 characters
//        let color1 = Color(hex: "#FFF")
//        XCTAssertNil(color1)
//        
//        let color2 = Color(hex: "ABC")
//        XCTAssertNil(color2)
//    }
//    
//    func testInitFromLongHexString() {
//        // These should fail as they're more than 6 characters
//        let color1 = Color(hex: "#FF000000")
//        XCTAssertNil(color1)
//        
//        let color2 = Color(hex: "ABCDEF123")
//        XCTAssertNil(color2)
//    }
//    
//    func testToHexConversion() {
//        let red = Color.red
//        let redHex = red.toHex()
//        XCTAssertTrue(redHex.hasPrefix("#"))
//        XCTAssertEqual(redHex.count, 7)
//        
//        let green = Color.green
//        let greenHex = green.toHex()
//        XCTAssertTrue(greenHex.hasPrefix("#"))
//        XCTAssertEqual(greenHex.count, 7)
//        
//        let blue = Color.blue
//        let blueHex = blue.toHex()
//        XCTAssertTrue(blueHex.hasPrefix("#"))
//        XCTAssertEqual(blueHex.count, 7)
//        
//        let black = Color.black
//        let blackHex = black.toHex()
//        XCTAssertTrue(blackHex.hasPrefix("#"))
//        XCTAssertEqual(blackHex.count, 7)
//        
//        let white = Color.white
//        let whiteHex = white.toHex()
//        XCTAssertTrue(whiteHex.hasPrefix("#"))
//        XCTAssertEqual(whiteHex.count, 7)
//    }
//    
//    func testRoundTripConversion() {
//        let testColors = [
//            "#FF0000", // Red
//            "#00FF00", // Green
//            "#0000FF", // Blue
//            "#FFFFFF", // White
//            "#000000", // Black
//            "#808080", // Gray
//            "#FFFF00", // Yellow
//            "#FF00FF", // Magenta
//            "#00FFFF"  // Cyan
//        ]
//        
//        for hexString in testColors {
//            guard let color = Color(hex: hexString) else {
//                XCTFail("Failed to create color from hex: \(hexString)")
//                continue
//            }
//            
//            let convertedHex = color.toHex()
//            XCTAssertEqual(convertedHex.uppercased(), hexString.uppercased(), "Round trip failed for \(hexString)")
//        }
//    }
//    
//    func testHexStringCaseInsensitive() {
//        let lowerCase = Color(hex: "#ff0000")
//        let upperCase = Color(hex: "#FF0000")
//        let mixedCase = Color(hex: "#Ff0000")
//        
//        XCTAssertNotNil(lowerCase)
//        XCTAssertNotNil(upperCase)
//        XCTAssertNotNil(mixedCase)
//    }
//    
//    func testPredefinedAppColors() {
//        // Test that predefined colors can be accessed without crashing
//        _ = Color.successColor
//        _ = Color.warningColor
//        _ = Color.errorColor
//        _ = Color.infoColor
//        
//        XCTAssertEqual(Color.successColor, Color.green)
//        XCTAssertEqual(Color.warningColor, Color.orange)
//        XCTAssertEqual(Color.errorColor, Color.red)
//        XCTAssertEqual(Color.infoColor, Color.blue)
//    }
//    
//    func testAppColorAccess() {
//        // These may fail if the assets don't exist, but should not crash
//        // We're testing that the extension properties are accessible
//        let _ = Color.primaryApp
//        let _ = Color.secondaryApp
//        let _ = Color.accentApp
//        let _ = Color.backgroundApp
//        
//        // If we reach here without crashing, the test passes
//        XCTAssertTrue(true)
//    }
//    
//    func testHexStringEdgeCases() {
//        let edgeCases = [
//            "#GGGGGG", // Invalid hex characters
//            "123456",   // Valid without #
//            "#123456",  // Valid with #
//            "# 123456", // Space after #
//            "#12 3456", // Space in middle
//            "#12345G",  // Invalid last character
//            "!@#$%^",   // Special characters
//            "123",      // Too short
//            "1234567",  // Too long
//        ]
//        
//        let expectedResults = [
//            nil,    // #GGGGGG
//            Color(hex: "123456"),  // 123456
//            Color(hex: "#123456"), // #123456
//            nil,    // # 123456
//            nil,    // #12 3456
//            nil,    // #12345G
//            nil,    // !@#$%^
//            nil,    // 123
//            nil     // 1234567
//        ]
//        
//        for (index, hexString) in edgeCases.enumerated() {
//            let result = Color(hex: hexString)
//            if expectedResults[index] == nil {
//                XCTAssertNil(result, "Expected nil for \(hexString)")
//            } else {
//                XCTAssertNotNil(result, "Expected non-nil for \(hexString)")
//            }
//        }
//    }
//}
