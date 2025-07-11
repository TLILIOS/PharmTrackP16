import Foundation

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