import IsletCore
import SwiftUI

/// Recent copies: click one to put it back on the clipboard.
struct ClipboardPage: View {
    let clipboard: ClipboardMonitor

    var body: some View {
        let entries = clipboard.history.entries
        if entries.isEmpty {
            VStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                Text("Nothing copied yet", bundle: .module)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Your recent copies land here. They stay in memory and never touch the disk.", bundle: .module)
                    .font(.system(size: 11.5))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 5) {
                    ForEach(entries) { entry in
                        ClipRow(entry: entry, clipboard: clipboard)
                    }
                }
            }
        }
    }
}

private struct ClipRow: View {
    let entry: ClipboardHistory.Entry
    let clipboard: ClipboardMonitor
    @State private var hovering = false
    @State private var copied = false

    var body: some View {
        Button {
            clipboard.copy(entry)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copied = false }
        } label: {
            HStack(spacing: 10) {
                Text(preview)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if copied {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.coral.color)
                        .transition(.scale.combined(with: .opacity))
                } else if hovering {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { clipboard.remove(entry) }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .buttonStyle(PressableStyle())
                } else if let app = entry.sourceApp {
                    Text(app)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Theme.tertiaryText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 28)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.white.opacity(hovering ? 0.11 : 0.06)))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovering = $0 }
        .animation(.spring(duration: 0.25), value: copied)
        .help(String(entry.text.prefix(400)))
    }

    private var preview: String {
        entry.text.split(whereSeparator: \.isNewline).first.map { $0.trimmingCharacters(in: .whitespaces) } ?? entry.text
    }
}
