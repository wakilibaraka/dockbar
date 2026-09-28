import AppKit
import SwiftUI

struct DownloadsFlyoutView: View {
    @ObservedObject var monitor = DownloadsMonitor.shared
    @EnvironmentObject var settings: TaskbarSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Downloads")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button(action: {
                    NSWorkspace.shared.open(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!)
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    monitor.clearRecents()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 4)
            
            if monitor.activeDownloads.isEmpty && monitor.recentDownloads.isEmpty {
                Text("No recent downloads")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                if !monitor.activeDownloads.isEmpty {
                    Text("Downloading")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ForEach(monitor.activeDownloads) { item in
                        DownloadRowView(item: item)
                    }
                }
                
                if !monitor.recentDownloads.isEmpty {
                    Text("Recent")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .padding(.top, 4)
                    
                    ForEach(monitor.recentDownloads) { item in
                        DownloadRowView(item: item)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

struct DownloadRowView: View {
    let item: DownloadItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: item.url.path))
                .resizable()
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(cleanFilename(item.filename))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                if !item.isFinished {
                    ProgressView(value: item.progress)
                        .progressViewStyle(.linear)
                        .frame(height: 4)
                }
            }
            Spacer()
            
            if item.isFinished {
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            NSWorkspace.shared.open(item.url)
        }
        .onDrag {
            NSItemProvider(object: item.url as NSURL)
        }
    }
    
    private func cleanFilename(_ name: String) -> String {
        if name.hasSuffix(".crdownload") {
            return String(name.dropLast(".crdownload".count))
        } else if name.hasSuffix(".part") {
            return String(name.dropLast(".part".count))
        } else if name.hasSuffix(".download") {
            return String(name.dropLast(".download".count))
        }
        return name
    }
}
