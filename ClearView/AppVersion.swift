import Foundation

enum AppVersion {
    // 开源版本信息统一由这里维护，避免 README、关于窗、发布说明出现多处不一致。
    static let productName = "ClearView"
    static let version = "0.2.2"
    static let build = "release"
    static let minimumSystemVersion = "macOS 13+"
    static let license = "Apache-2.0"

    static var displayVersion: String {
        "\(version)（\(build)）"
    }
}
