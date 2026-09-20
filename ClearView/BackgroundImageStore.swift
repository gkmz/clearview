import AppKit
import Foundation

enum CustomBackgroundKind: String, CaseIterable {
    case light
    case dark

    var fileName: String { "\(rawValue).png" }
}

struct BackgroundImportResult: Equatable {
    let pixelWidth: Int
    let pixelHeight: Int
    let isLowResolution: Bool
}

enum BackgroundImageStoreError: LocalizedError {
    case invalidImage
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无法读取这张图片，请选择有效的 PNG、JPEG、HEIC 或 TIFF 图片。"
        case .encodingFailed:
            return "图片处理失败，请更换图片后重试。"
        }
    }
}

/// 管理用户自定义背景图片，并将外部图片复制到应用自己的支持目录。
final class BackgroundImageStore {
    private let fileManager: FileManager
    private let directoryURL: URL
    private let maximumPixelDimension: CGFloat = 4096

    init(fileManager: FileManager = .default, directoryURL: URL? = nil) {
        self.fileManager = fileManager
        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.directoryURL = applicationSupport
                .appendingPathComponent("ClearView", isDirectory: true)
                .appendingPathComponent("Backgrounds", isDirectory: true)
        }
    }

    /// 返回指定主题的自定义背景；文件缺失或损坏时返回 nil。
    func image(for kind: CustomBackgroundKind) -> NSImage? {
        NSImage(contentsOf: fileURL(for: kind))
    }

    /// 导入图片并按最长边 4096 像素等比缩小，避免超大图片持续占用内存。
    func importImage(from sourceURL: URL, for kind: CustomBackgroundKind) throws -> BackgroundImportResult {
        guard let source = NSImage(contentsOf: sourceURL),
              let representation = source.representations.first else {
            throw BackgroundImageStoreError.invalidImage
        }

        let sourceWidth = max(1, representation.pixelsWide)
        let sourceHeight = max(1, representation.pixelsHigh)
        let scale = min(1, maximumPixelDimension / CGFloat(max(sourceWidth, sourceHeight)))
        let targetWidth = max(1, Int((CGFloat(sourceWidth) * scale).rounded()))
        let targetHeight = max(1, Int((CGFloat(sourceHeight) * scale).rounded()))

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: targetWidth,
            pixelsHigh: targetHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw BackgroundImageStoreError.encodingFailed
        }

        // 在固定像素画布内等比绘制，既保留透明通道，也避免改变原图比例。
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
            NSGraphicsContext.restoreGraphicsState()
            throw BackgroundImageStoreError.encodingFailed
        }
        NSGraphicsContext.current = context
        source.draw(
            in: NSRect(x: 0, y: 0, width: targetWidth, height: targetHeight),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw BackgroundImageStoreError.encodingFailed
        }
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try data.write(to: fileURL(for: kind), options: .atomic)

        return BackgroundImportResult(
            pixelWidth: sourceWidth,
            pixelHeight: sourceHeight,
            isLowResolution: sourceWidth < 1280 || sourceHeight < 720
        )
    }

    /// 删除指定主题的自定义图片，使界面回退到应用内置背景。
    func removeImage(for kind: CustomBackgroundKind) throws {
        let url = fileURL(for: kind)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    /// 删除全部自定义背景，用于恢复默认设置。
    func removeAllImages() throws {
        guard fileManager.fileExists(atPath: directoryURL.path) else { return }
        try fileManager.removeItem(at: directoryURL)
    }

    /// 判断指定主题是否已经配置自定义背景。
    func hasImage(for kind: CustomBackgroundKind) -> Bool {
        fileManager.fileExists(atPath: fileURL(for: kind).path)
    }

    private func fileURL(for kind: CustomBackgroundKind) -> URL {
        directoryURL.appendingPathComponent(kind.fileName, isDirectory: false)
    }
}
