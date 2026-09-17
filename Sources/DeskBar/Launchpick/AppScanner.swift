import AppKit

class AppScanner {
    static let shared = AppScanner()

    struct App: Identifiable {
        let id: String
        let name: String
        let path: String
        let icon: NSImage
        let category: String
    }

    lazy var apps: [App] = {
        var result: [App] = []
        var seen = Set<String>()
        let fm = FileManager.default
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "\(NSHomeDirectory())/Applications",
        ]

        for basePath in searchPaths {
            guard let items = try? fm.contentsOfDirectory(atPath: basePath) else { continue }
            for item in items.sorted() where item.hasSuffix(".app") {
                let fullPath = "\(basePath)/\(item)"
                let name = String(item.dropLast(4))
                guard seen.insert(name).inserted else { continue }
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                var category = "Other"
                if let bundle = Bundle(path: fullPath),
                   let catType = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String {
                    category = Self.mapCategory(catType)
                }
                result.append(App(id: fullPath, name: name, path: fullPath, icon: icon, category: category))
            }
        }

        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
    private static func mapCategory(_ raw: String) -> String {
        switch raw {
        case "public.app-category.business": return "Business"
        case "public.app-category.developer-tools": return "Developer Tools"
        case "public.app-category.education": return "Education"
        case "public.app-category.entertainment": return "Entertainment"
        case "public.app-category.finance": return "Finance"
        case "public.app-category.games": return "Games"
        case "public.app-category.action-games",
             "public.app-category.adventure-games",
             "public.app-category.arcade-games",
             "public.app-category.board-games",
             "public.app-category.card-games",
             "public.app-category.casino-games",
             "public.app-category.dice-games",
             "public.app-category.educational-games",
             "public.app-category.family-games",
             "public.app-category.kids-games",
             "public.app-category.music-games",
             "public.app-category.puzzle-games",
             "public.app-category.racing-games",
             "public.app-category.role-playing-games",
             "public.app-category.simulation-games",
             "public.app-category.sports-games",
             "public.app-category.strategy-games",
             "public.app-category.trivia-games",
             "public.app-category.word-games": return "Games"
        case "public.app-category.graphics-design": return "Graphics & Design"
        case "public.app-category.healthcare-fitness": return "Health & Fitness"
        case "public.app-category.lifestyle": return "Lifestyle"
        case "public.app-category.medical": return "Medical"
        case "public.app-category.music": return "Music"
        case "public.app-category.news": return "News"
        case "public.app-category.photography": return "Photography"
        case "public.app-category.productivity": return "Productivity"
        case "public.app-category.reference": return "Reference"
        case "public.app-category.social-networking": return "Social Networking"
        case "public.app-category.sports": return "Sports"
        case "public.app-category.travel": return "Travel"
        case "public.app-category.utilities": return "Utilities"
        case "public.app-category.video": return "Video"
        case "public.app-category.weather": return "Weather"
        default: return "Other"
        }
    }
}
