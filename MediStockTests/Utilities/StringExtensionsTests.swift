import XCTest
import Foundation
@testable @preconcurrency import MediStock

// MARK: - String Extensions for Testing
extension String {
    
    // MARK: - Validation
    
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    var isValidPhoneNumber: Bool {
        let phoneRegex = #"^\+?[1-9]\d{1,14}$"#
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: self)
    }
    
    // MARK: - String Manipulation
    
    var capitalizedFirstLetter: String {
        guard !isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst().lowercased()
    }
    
    var trimmed: String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var removingWhitespace: String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
    
    // MARK: - Type Conversion
    
    var intValue: Int? {
        return Int(self)
    }
    
    var doubleValue: Double? {
        return Double(self)
    }
    
    // MARK: - Search
    
    func contains(_ string: String, ignoreCase: Bool) -> Bool {
        if ignoreCase {
            return localizedCaseInsensitiveContains(string)
        } else {
            return contains(string)
        }
    }
    
    // MARK: - Substring
    
    func substring(from: Int, to: Int) -> String {
        guard from >= 0, to >= 0, from <= to, to <= count else { return "" }
        let startIndex = index(self.startIndex, offsetBy: from)
        let endIndex = index(self.startIndex, offsetBy: to)
        return String(self[startIndex..<endIndex])
    }
    
    func substring(from: Int) -> String {
        guard from < count else { return "" }
        let startIndex = index(self.startIndex, offsetBy: from)
        return String(self[startIndex...])
    }
    
    func substring(to: Int) -> String {
        guard to > 0 else { return "" }
        let endIndex = index(self.startIndex, offsetBy: min(to, count))
        return String(self[..<endIndex])
    }
    
    // MARK: - Encoding
    
    var urlEncoded: String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
    
    var base64Encoded: String {
        return Data(self.utf8).base64EncodedString()
    }
    
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Localization
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    // MARK: - Analysis
    
    var wordCount: Int {
        let words = components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    var alphanumericOnly: String {
        return components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
    }
    
    var digitsOnly: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    // MARK: - Formatting
    
    func abbreviated(to length: Int) -> String {
        guard count > length else { return self }
        return prefix(length - 3) + "..."
    }
    
    // MARK: - File Operations
    
    var fileExtension: String {
        return (self as NSString).pathExtension
    }
    
    var fileNameWithoutExtension: String {
        return (self as NSString).deletingPathExtension
    }
    
    // MARK: - Emoji
    
    var containsEmoji: Bool {
        return unicodeScalars.contains { $0.properties.isEmoji }
    }
    
    var removingEmoji: String {
        return String(unicodeScalars.filter { !$0.properties.isEmoji })
    }
}

@MainActor
final class StringExtensionsTests: XCTestCase, Sendable {
    
    // MARK: - Validation Tests
    
    func testIsValidEmail_ValidEmails() {
        // Given
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.com",
            "user123@example.co.uk",
            "test.email@sub.domain.com",
            "a@b.co"
        ]
        
        // When & Then
        for email in validEmails {
            XCTAssertTrue(email.isValidEmail, "Email '\(email)' should be valid")
        }
    }
    
    func testIsValidEmail_InvalidEmails() {
        // Given
        let invalidEmails = [
            "",
            "invalid-email",
            "@example.com",
            "user@",
            "user@localhost",
            "user@.com",
            "user@com",
            "user name@example.com",
            "user@exam ple.com"
        ]
        
        // When & Then
        for email in invalidEmails {
            XCTAssertFalse(email.isValidEmail, "Email '\(email)' should be invalid")
        }
    }
    
    func testIsValidPhoneNumber_ValidNumbers() {
        // Given
        let validNumbers = [
            "+1234567890",
            "+33123456789",
            "1234567890"
        ]
        
        // When & Then
        for number in validNumbers {
            XCTAssertTrue(number.isValidPhoneNumber, "Phone number '\(number)' should be valid")
        }
    }
    
    func testIsValidPhoneNumber_InvalidNumbers() {
        // Given
        // Regex: ^\+?[1-9]\d{1,14}$ means:
        // - Optional +, then digit 1-9, then 1-14 more digits = 2-15 total digits
        let invalidNumbers = [
            "",
            "1", // too short - needs at least 2 digits total
            "abcdefghij",
            "+",
            "123-45", // contains dashes
            "123 456 789 012 345", // contains spaces
            "0123456789", // starts with 0, regex requires [1-9]
            "123456789012345678" // too long - more than 15 digits total
        ]
        
        // When & Then
        for number in invalidNumbers {
            XCTAssertFalse(number.isValidPhoneNumber, "Phone number '\(number)' should be invalid")
        }
    }
    
    // MARK: - Formatting Tests
    
    func testCapitalized_FirstLetter() {
        // Given
        let input = "hello world"
        
        // When
        let result = input.capitalizedFirstLetter
        
        // Then
        XCTAssertEqual(result, "Hello world")
    }
    
    func testCapitalized_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.capitalizedFirstLetter
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testCapitalized_SingleCharacter() {
        // Given
        let input = "a"
        
        // When
        let result = input.capitalizedFirstLetter
        
        // Then
        XCTAssertEqual(result, "A")
    }
    
    func testCapitalized_AlreadyCapitalized() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.capitalizedFirstLetter
        
        // Then
        XCTAssertEqual(result, "Hello world")
    }
    
    // MARK: - Trimming Tests
    
    func testTrimmed_WhitespaceAndNewlines() {
        // Given
        let input = "  \n  Hello World  \n  "
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "Hello World")
    }
    
    func testTrimmed_NoWhitespace() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "Hello World")
    }
    
    func testTrimmed_OnlyWhitespace() {
        // Given
        let input = "   \n\t   "
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testTrimmed_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    // MARK: - Numeric Conversion Tests
    
    func testIntValue_ValidInteger() {
        // Given
        let input = "123"
        
        // When
        let result = input.intValue
        
        // Then
        XCTAssertEqual(result, 123)
    }
    
    func testIntValue_InvalidInteger() {
        // Given
        let input = "abc"
        
        // When
        let result = input.intValue
        
        // Then
        XCTAssertNil(result)
    }
    
    func testIntValue_NegativeInteger() {
        // Given
        let input = "-456"
        
        // When
        let result = input.intValue
        
        // Then
        XCTAssertEqual(result, -456)
    }
    
    func testDoubleValue_ValidDouble() {
        // Given
        let input = "123.45"
        
        // When
        let result = input.doubleValue
        
        // Then
        XCTAssertEqual(result ?? 0.0, 123.45, accuracy: 0.001)
    }
    
    func testDoubleValue_InvalidDouble() {
        // Given
        let input = "abc"
        
        // When
        let result = input.doubleValue
        
        // Then
        XCTAssertNil(result)
    }
    
    func testDoubleValue_Integer() {
        // Given
        let input = "789"
        
        // When
        let result = input.doubleValue
        
        // Then
        XCTAssertEqual(result ?? 0.0, 789.0, accuracy: 0.001)
    }
    
    // MARK: - String Manipulation Tests
    
    func testRemoveWhitespace() {
        // Given
        let input = "Hello World Test"
        
        // When
        let result = input.removingWhitespace
        
        // Then
        XCTAssertEqual(result, "HelloWorldTest")
    }
    
    func testRemoveWhitespace_WithTabs() {
        // Given
        let input = "Hello\tWorld\nTest"
        
        // When
        let result = input.removingWhitespace
        
        // Then
        XCTAssertEqual(result, "HelloWorldTest")
    }
    
    func testRemoveWhitespace_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.removingWhitespace
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testRemoveWhitespace_OnlyWhitespace() {
        // Given
        let input = "   \t\n   "
        
        // When
        let result = input.removingWhitespace
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    // MARK: - Contains Tests
    
    func testContainsIgnoreCase_Found() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.contains("WORLD", ignoreCase: true)
        
        // Then
        XCTAssertTrue(result)
    }
    
    func testContainsIgnoreCase_NotFound() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.contains("UNIVERSE", ignoreCase: true)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testContainsIgnoreCase_CaseSensitive() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.contains("WORLD", ignoreCase: false)
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testContainsIgnoreCase_EmptyString() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.contains("", ignoreCase: true)
        
        // Then
        XCTAssertFalse(result) // Empty string is not found in non-empty string with current implementation
    }
    
    // MARK: - Substring Tests
    
    func testSubstring_ValidRange() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.substring(from: 6, to: 11)
        
        // Then
        XCTAssertEqual(result, "World")
    }
    
    func testSubstring_StartOfString() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.substring(from: 0, to: 5)
        
        // Then
        XCTAssertEqual(result, "Hello")
    }
    
    func testSubstring_InvalidRange() {
        // Given
        let input = "Hello"
        
        // When
        let result = input.substring(from: 10, to: 15)
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testSubstring_FromIndex() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.substring(from: 6)
        
        // Then
        XCTAssertEqual(result, "World")
    }
    
    func testSubstring_ToIndex() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.substring(to: 5)
        
        // Then
        XCTAssertEqual(result, "Hello")
    }
    
    // MARK: - URL Encoding Tests
    
    func testURLEncoded() {
        // Given
        let input = "Hello World!"
        
        // When
        let result = input.urlEncoded
        
        // Then
        XCTAssertEqual(result, "Hello%20World!")
    }
    
    func testURLEncoded_SpecialCharacters() {
        // Given
        let input = "test@example.com"
        
        // When
        let result = input.urlEncoded
        
        // Then
        // The @ symbol is allowed in .urlQueryAllowed, so it won't be encoded
        XCTAssertEqual(result, "test@example.com")
    }
    
    func testURLEncoded_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.urlEncoded
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    // MARK: - Base64 Tests
    
    func testBase64Encoded() {
        // Given
        let input = "Hello World"
        
        // When
        let result = input.base64Encoded
        
        // Then
        XCTAssertEqual(result, "SGVsbG8gV29ybGQ=")
    }
    
    func testBase64Decoded() {
        // Given
        let input = "SGVsbG8gV29ybGQ="
        
        // When
        let result = input.base64Decoded
        
        // Then
        XCTAssertEqual(result, "Hello World")
    }
    
    func testBase64RoundTrip() {
        // Given
        let input = "Hello World! 🌍"
        
        // When
        let encoded = input.base64Encoded
        let decoded = encoded.base64Decoded
        
        // Then
        XCTAssertEqual(decoded, input)
    }
    
    func testBase64Decoded_InvalidInput() {
        // Given
        let input = "Invalid Base64!"
        
        // When
        let result = input.base64Decoded
        
        // Then
        XCTAssertNil(result)
    }
    
    // MARK: - Localization Tests
    
    func testLocalized() {
        // Given
        let input = "Hello"
        
        // When
        let result = input.localized
        
        // Then
        XCTAssertEqual(result, input) // Should return the same string if no localization found
    }
    
    // MARK: - Character Count Tests
    
    func testWordCount() {
        // Given
        let input = "Hello beautiful world"
        
        // When
        let result = input.wordCount
        
        // Then
        XCTAssertEqual(result, 3)
    }
    
    func testWordCount_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.wordCount
        
        // Then
        XCTAssertEqual(result, 0)
    }
    
    func testWordCount_SingleWord() {
        // Given
        let input = "Hello"
        
        // When
        let result = input.wordCount
        
        // Then
        XCTAssertEqual(result, 1)
    }
    
    func testWordCount_MultipleSpaces() {
        // Given
        let input = "Hello    world   test"
        
        // When
        let result = input.wordCount
        
        // Then
        XCTAssertEqual(result, 3)
    }
    
    // MARK: - Character Filtering Tests
    
    func testAlphanumericOnly() {
        // Given
        let input = "Hello123!@#World456"
        
        // When
        let result = input.alphanumericOnly
        
        // Then
        XCTAssertEqual(result, "Hello123World456")
    }
    
    func testAlphanumericOnly_EmptyString() {
        // Given
        let input = ""
        
        // When
        let result = input.alphanumericOnly
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testAlphanumericOnly_SpecialCharactersOnly() {
        // Given
        let input = "!@#$%^&*()"
        
        // When
        let result = input.alphanumericOnly
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testDigitsOnly() {
        // Given
        let input = "abc123def456ghi"
        
        // When
        let result = input.digitsOnly
        
        // Then
        XCTAssertEqual(result, "123456")
    }
    
    func testDigitsOnly_NoDigits() {
        // Given
        let input = "abcdef"
        
        // When
        let result = input.digitsOnly
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    // MARK: - Abbreviation Tests
    
    func testAbbreviated_LongString() {
        // Given
        let input = "This is a very long string that should be abbreviated"
        
        // When
        let result = input.abbreviated(to: 20)
        
        // Then
        XCTAssertEqual(result, "This is a very lo...")
        XCTAssertLessThanOrEqual(result.count, 20)
    }
    
    func testAbbreviated_ShortString() {
        // Given
        let input = "Short"
        
        // When
        let result = input.abbreviated(to: 20)
        
        // Then
        XCTAssertEqual(result, "Short")
    }
    
    func testAbbreviated_ExactLength() {
        // Given
        let input = "Exactly twenty chars"
        
        // When
        let result = input.abbreviated(to: 20)
        
        // Then
        XCTAssertEqual(result, "Exactly twenty chars")
    }
    
    // MARK: - File Extension Tests
    
    func testFileExtension() {
        // Given
        let input = "document.pdf"
        
        // When
        let result = input.fileExtension
        
        // Then
        XCTAssertEqual(result, "pdf")
    }
    
    func testFileExtension_NoExtension() {
        // Given
        let input = "document"
        
        // When
        let result = input.fileExtension
        
        // Then
        XCTAssertEqual(result, "")
    }
    
    func testFileExtension_MultipleDots() {
        // Given
        let input = "document.backup.pdf"
        
        // When
        let result = input.fileExtension
        
        // Then
        XCTAssertEqual(result, "pdf")
    }
    
    func testFileNameWithoutExtension() {
        // Given
        let input = "document.pdf"
        
        // When
        let result = input.fileNameWithoutExtension
        
        // Then
        XCTAssertEqual(result, "document")
    }
    
    func testFileNameWithoutExtension_NoExtension() {
        // Given
        let input = "document"
        
        // When
        let result = input.fileNameWithoutExtension
        
        // Then
        XCTAssertEqual(result, "document")
    }
    
    // MARK: - Unicode and Emoji Tests
    
    func testContainsEmoji() {
        // Given
        let inputWithEmoji = "Hello 👋 World 🌍"
        let inputWithoutEmoji = "Hello World"
        
        // When & Then
        XCTAssertTrue(inputWithEmoji.containsEmoji)
        XCTAssertFalse(inputWithoutEmoji.containsEmoji)
    }
    
    func testRemoveEmoji() {
        // Given
        let input = "Hello 👋 World 🌍 Test"
        
        // When
        let result = input.removingEmoji
        
        // Then
        XCTAssertEqual(result, "Hello  World  Test")
    }
    
    // MARK: - Edge Cases Tests
    
    func testVeryLongString() {
        // Given
        let input = String(repeating: "a", count: 10000)
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result.count, 10000)
    }
    
    func testSpecialUnicodeCharacters() {
        // Given
        let input = "Héllo Wörld 测试 🌍"
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "Héllo Wörld 测试 🌍")
    }
    
    func testNullCharacters() {
        // Given
        let input = "Hello\0World"
        
        // When
        let result = input.trimmed
        
        // Then
        XCTAssertEqual(result, "Hello\0World")
    }
}
