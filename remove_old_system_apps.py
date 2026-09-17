import re

with open('Sources/DeskBar/Launchpick/ContentView.swift', 'r') as f:
    content = f.read()

pattern = re.compile(r'                    // System apps section.*?                    // Phase 2: All Apps \(Grouped & Searchable\)', re.DOTALL)

content = pattern.sub('                    // Phase 2: All Apps (Grouped & Searchable)', content)

with open('Sources/DeskBar/Launchpick/ContentView.swift', 'w') as f:
    f.write(content)
