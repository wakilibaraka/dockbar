import Foundation
import Combine
import SwiftUI

class LaunchpickConfigManager: ObservableObject {
    static let shared = LaunchpickConfigManager()
    @Published var config: LaunchpickConfig

    private init() {
        self.config = LaunchpickConfig.load()
    }

    func save() {
        LaunchpickConfig.save(config)
    }

    func addLauncher(_ launcher: ConfigLauncher) {
        config.launchers.append(launcher)
        save()
    }

    func removeLauncher(at index: Int) {
        config.launchers.remove(at: index)
        save()
    }

    func moveLauncher(from source: IndexSet, to destination: Int) {
        config.launchers.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
