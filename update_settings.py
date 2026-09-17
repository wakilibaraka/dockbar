import re

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'r') as f:
    content = f.read()

# Insert the property
property_insertion = """
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published var taskbarHeight: CGFloat {"""
content = content.replace("@Published var taskbarHeight: CGFloat {", property_insertion)

# Insert the initialization
init_insertion = """
        hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
        taskbarHeight = defaults.object(forKey: "taskbarHeight") as? CGFloat ?? 48"""
content = content.replace("taskbarHeight = defaults.object(forKey: \"taskbarHeight\") as? CGFloat ?? 48", init_insertion)

with open('Sources/DeskBar/Models/TaskbarSettings.swift', 'w') as f:
    f.write(content)
