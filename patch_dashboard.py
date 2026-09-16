import re

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'r') as f:
    content = f.read()

# Add smPluginService property
content = content.replace("    @ObservedObject var systemStats = SystemStatsService.shared", "    var smPluginService: SMPluginService?\n    @ObservedObject var systemStats = SystemStatsService.shared")

# Add SMStatsView at the end of the file
sm_view = """
struct SMStatsView: View {
    @ObservedObject var service: SMPluginService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Session Manager")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.top, 4)
            
            HStack(spacing: 8) {
                SMStatTile(title: "ACT", value: service.watchSummary.workingCount, color: .green)
                SMStatTile(title: "THK", value: service.watchSummary.thinkingCount, color: .blue)
                SMStatTile(title: "IDL", value: service.watchSummary.idleCount, color: .secondary)
            }
        }
    }
}

struct SMStatTile: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Spacer()
            Text("\(value)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
"""
content += sm_view

# Insert it after Hardware Tiles
hardware_tiles_end = """            }
            .frame(height: 56)
            
            Divider()"""

sm_section = """            }
            .frame(height: 56)
            
            if let service = smPluginService {
                Divider()
                SMStatsView(service: service)
            }
            
            Divider()"""

content = content.replace(hardware_tiles_end, sm_section)

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)

