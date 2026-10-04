import Foundation

// Dependency-free update checking. DockBar ships zero third-party packages, so instead of
// pulling in an auto-updater framework the app asks the GitHub Releases API for its own
// latest release and compares the tag with the version stamped into the bundle by
// scripts/package.sh. Every decision here is pure, so it is unit-testable without network.

/// A dotted numeric version that tolerates a leading "v" and a missing patch component.
struct SemanticVersion: Comparable, CustomStringConvertible, Equatable {
    let major: Int
    let minor: Int
    let patch: Int

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses "v1.2", "1.2.3" and "1.2.3.4" (extra components ignored).
    /// Returns nil for anything that is not numeric after an optional leading "v".
    init?(string: String) {
        var text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text.hasPrefix("v") || text.hasPrefix("V") {
            text.removeFirst()
        }

        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard (1...4).contains(parts.count) else { return nil }

        var numbers: [Int] = []
        for part in parts {
            guard let number = Int(part) else { return nil }
            numbers.append(number)
        }

        self.init(
            major: numbers[0],
            minor: numbers.count > 1 ? numbers[1] : 0,
            patch: numbers.count > 2 ? numbers[2] : 0
        )
    }

    var description: String { "\(major).\(minor).\(patch)" }

    // Numeric, component by component: 0.2.10 is newer than 0.2.9.
    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

/// The slice of the GitHub "latest release" payload DockBar needs.
struct LatestRelease: Decodable, Equatable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }
}

/// Outcome of an update check.
enum UpdateCheckResult: Equatable {
    /// The installed build is current or ahead of the published release.
    case upToDate(current: String, latest: String)
    /// A newer release is published; `releaseURL` points at its page.
    case updateAvailable(current: String, latest: String, releaseURL: URL)
    /// The check could not be completed.
    case failed(message: String)
}

struct UpdateService {
    static let defaultFeedURL = URL(string: "https://api.github.com/repos/wakilibaraka/dockbar/releases/latest")!

    let feedURL: URL
    let currentVersion: String

    init(
        feedURL: URL = UpdateService.defaultFeedURL,
        currentVersion: String = UpdateService.installedVersion
    ) {
        self.feedURL = feedURL
        self.currentVersion = currentVersion
    }

    /// The version `scripts/package.sh` stamped into the bundle at packaging time.
    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// Pure comparison of the installed build against a fetched release, so the decision
    /// can be tested without touching the network.
    static func result(current: String, latest: LatestRelease) -> UpdateCheckResult {
        guard let currentVersion = SemanticVersion(string: current) else {
            return .failed(message: "Could not read the installed version (\(current)).")
        }
        guard let latestVersion = SemanticVersion(string: latest.tagName) else {
            return .failed(message: "Could not understand the release tag \(latest.tagName).")
        }

        if latestVersion > currentVersion {
            return .updateAvailable(
                current: currentVersion.description,
                latest: latestVersion.description,
                releaseURL: latest.htmlURL
            )
        }
        return .upToDate(current: currentVersion.description, latest: latestVersion.description)
    }

    /// Fetches the latest release and compares it with the installed version.
    func check() async -> UpdateCheckResult {
        var request = URLRequest(url: feedURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("DockBar/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                return .failed(message: "GitHub answered with HTTP \(http.statusCode).")
            }
            let release = try JSONDecoder().decode(LatestRelease.self, from: data)
            return Self.result(current: currentVersion, latest: release)
        } catch {
            return .failed(message: error.localizedDescription)
        }
    }
}