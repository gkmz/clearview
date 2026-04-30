import SwiftUI

private struct HoverTooltipModifier: ViewModifier {
    let text: String
    let delay: TimeInterval

    @State private var isHovering = false
    @State private var isTooltipVisible = false
    @State private var pendingWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isTooltipVisible {
                    Text(text)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.94))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.black.opacity(0.76))
                        )
                        .compositingGroup()
                        .offset(y: -10)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .onHover { hovering in
                isHovering = hovering
                if hovering {
                    // 进入悬停后延迟 1 秒显示提示，缩短等待时间。
                    pendingWorkItem?.cancel()
                    let item = DispatchWorkItem {
                        guard isHovering else { return }
                        withAnimation(.easeOut(duration: 0.12)) {
                            isTooltipVisible = true
                        }
                    }
                    pendingWorkItem = item
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
                } else {
                    // 离开按钮时立即隐藏提示并取消待执行任务。
                    pendingWorkItem?.cancel()
                    pendingWorkItem = nil
                    withAnimation(.easeOut(duration: 0.08)) {
                        isTooltipVisible = false
                    }
                }
            }
            .onDisappear {
                pendingWorkItem?.cancel()
                pendingWorkItem = nil
                isTooltipVisible = false
            }
    }
}

extension View {
    func hoverTooltip(_ text: String, delay: TimeInterval = 1.0) -> some View {
        modifier(HoverTooltipModifier(text: text, delay: delay))
    }
}
