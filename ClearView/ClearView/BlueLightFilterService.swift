import CoreGraphics
import Foundation

enum BlueLightLevel: CaseIterable {
    case off
    case light
    case medium
    case night

    var title: String {
        switch self {
        case .off: return "原色"
        case .light: return "轻柔"
        case .medium: return "舒缓"
        case .night: return "夜间"
        }
    }

    var iconName: String {
        switch self {
        case .off: return "circle.slash"
        case .light: return "sun.min"
        case .medium: return "sun.max"
        case .night: return "moon"
        }
    }
}

final class BlueLightFilterService {
    func apply(level: BlueLightLevel) {
        switch level {
        case .off:
            // 关闭过滤时恢复系统默认色彩设置。
            CGDisplayRestoreColorSyncSettings()
        case .light:
            applyToAllDisplays(red: 1.0, green: 0.95, blue: 0.88)
        case .medium:
            applyToAllDisplays(red: 1.0, green: 0.90, blue: 0.78)
        case .night:
            applyToAllDisplays(red: 1.0, green: 0.84, blue: 0.68)
        }
    }

    private func applyToAllDisplays(red: Float, green: Float, blue: Float) {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        var displays = Array(repeating: CGDirectDisplayID(), count: Int(count))
        CGGetOnlineDisplayList(count, &displays, &count)

        for display in displays {
            // 通过 gamma 公式修改通道比例，实现蓝光过滤效果。
            CGSetDisplayTransferByFormula(
                display,
                0, red, 1,
                0, green, 1,
                0, blue, 1
            )
        }
    }
}
