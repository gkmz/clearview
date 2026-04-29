import Foundation

enum AppVersion {
    static let productName = "ClearView"
    static let version = "0.1.0"
    static let build = "dev"
    static let minimumSystemVersion = "macOS 13+"
    static let license = "Apache-2.0"

    static var displayVersion: String {
        "\(version)（\(build)）"
    }
}
