import Foundation

enum Hex {
    static func toBytes(_ hex: String) -> [UInt8] {
        let cleaned = hex.replacingOccurrences(of: " ", with: "").lowercased()
        var bytes = [UInt8]()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let nextIndex = cleaned.index(index, offsetBy: 2, limitedBy: cleaned.endIndex) ?? cleaned.endIndex
            if nextIndex <= index { break }
            let byteString = String(cleaned[index..<nextIndex])
            if let b = UInt8(byteString, radix: 16) {
                bytes.append(b)
            }
            index = nextIndex
        }
        return bytes
    }

    static func fromBytes(_ bytes: [UInt8]) -> String {
        return bytes.map { String(format: "%02X", $0) }.joined()
    }
}

// Placeholder cho framing FMS nếu cần (header/length/CRC)
struct CommandCodec {
    static func frame(_ payload: [UInt8]) -> [UInt8] {
        return payload
    }
}
