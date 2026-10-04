import Foundation
import Testing
@testable import DockBar

private let releasePage = URL(string: "https://github.com/wakilibaraka/dockbar/releases/tag/v0.3.0")!

@Test
func semanticVersionToleratesPrefixAndMissingComponents() {
    #expect(SemanticVersion(string: "v0.3.0") == SemanticVersion(major: 0, minor: 3, patch: 0))
    #expect(SemanticVersion(string: "0.3.0") == SemanticVersion(major: 0, minor: 3, patch: 0))
    #expect(SemanticVersion(string: "v1.2") == SemanticVersion(major: 1, minor: 2, patch: 0))
    #expect(SemanticVersion(string: "4") == SemanticVersion(major: 4, minor: 0, patch: 0))
    #expect(SemanticVersion(string: "1.2.3.4") == SemanticVersion(major: 1, minor: 2, patch: 3))
    #expect(SemanticVersion(string: " v0.3.0 ") == SemanticVersion(major: 0, minor: 3, patch: 0))
}

@Test
func semanticVersionRejectsNonNumericTags() {
    #expect(SemanticVersion(string: "") == nil)
    #expect(SemanticVersion(string: "v") == nil)
    #expect(SemanticVersion(string: "nightly") == nil)
    #expect(SemanticVersion(string: "1.2.beta") == nil)
    #expect(SemanticVersion(string: "1..2") == nil)
}

@Test
func semanticVersionOrdersNumericallyNotAlphabetically() {
    #expect(SemanticVersion(string: "0.2.10")! > SemanticVersion(string: "0.2.9")!)
    #expect(SemanticVersion(string: "1.0.0")! > SemanticVersion(string: "0.9.9")!)
    #expect(SemanticVersion(string: "v0.3.0")! == SemanticVersion(string: "0.3.0")!)
    #expect(!(SemanticVersion(string: "0.3.0")! > SemanticVersion(string: "0.3.0")!))
}

@Test
func latestReleaseDecodesGitHubPayload() throws {
    let json = Data(
        """
        {
          "tag_name": "v0.3.0",
          "html_url": "https://github.com/wakilibaraka/dockbar/releases/tag/v0.3.0",
          "name": "DockBar v0.3.0"
        }
        """.utf8
    )

    let release = try JSONDecoder().decode(LatestRelease.self, from: json)

    #expect(release.tagName == "v0.3.0")
    #expect(release.htmlURL == releasePage)
}

@Test
func newerPublishedReleaseIsOfferedAsUpdate() {
    let result = UpdateService.result(
        current: "0.2.2",
        latest: LatestRelease(tagName: "v0.3.0", htmlURL: releasePage)
    )

    #expect(result == .updateAvailable(current: "0.2.2", latest: "0.3.0", releaseURL: releasePage))
}

@Test
func sameOrOlderPublishedReleaseIsUpToDate() {
    #expect(
        UpdateService.result(
            current: "0.3.0",
            latest: LatestRelease(tagName: "v0.3.0", htmlURL: releasePage)
        ) == .upToDate(current: "0.3.0", latest: "0.3.0")
    )

    // A local build ahead of the feed (or a re-published older tag) is not a downgrade prompt.
    #expect(
        UpdateService.result(
            current: "0.4.0",
            latest: LatestRelease(tagName: "v0.3.0", htmlURL: releasePage)
        ) == .upToDate(current: "0.4.0", latest: "0.3.0")
    )
}

@Test
func unusableVersionOrTagFailsWithAMessage() {
    #expect(
        UpdateService.result(
            current: "not-a-version",
            latest: LatestRelease(tagName: "v0.3.0", htmlURL: releasePage)
        ) == .failed(message: "Could not read the installed version (not-a-version).")
    )

    #expect(
        UpdateService.result(
            current: "0.2.2",
            latest: LatestRelease(tagName: "nightly", htmlURL: releasePage)
        ) == .failed(message: "Could not understand the release tag nightly.")
    )
}

@Test
func installedVersionIsAlwaysComparable() {
    // The test bundle carries no CFBundleShortVersionString, so the fallback is used.
    #expect(SemanticVersion(string: UpdateService.installedVersion) != nil)
}