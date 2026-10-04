import SwiftUI

// MARK: - Page scaffold

/// The standard settings page: a titled, scrollable form with a comfortable measure.
///
/// Every section uses this so pages feel like one window rather than seven apps.
struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    init(title: String, subtitle: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                content()
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A titled group of rows inside a `SettingsPage`.
struct SettingsGroup<Content: View>: View {
    let title: String
    var footer: String?
    @ViewBuilder let content: () -> Content

    init(_ title: String, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
        } label: {
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Rows

/// A labelled control with the catalogue's help text underneath.
///
/// This is the single row shape for every scalar setting, which is what makes the
/// `.help()` tooltips and the search results consistent.
struct SettingsRow<Content: View>: View {
    let title: String
    var help: String?
    @ViewBuilder let control: () -> Content

    init(_ title: String, help: String? = nil, @ViewBuilder control: @escaping () -> Content) {
        self.title = title
        self.help = help
        self.control = control
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fixedSize(horizontal: false, vertical: true)
                if let help, !help.isEmpty {
                    Text(help)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            control()
        }
        .padding(.vertical, 2)
        .help(help ?? "")
    }
}

/// A slider with its live value shown alongside, e.g. "44 pt".
struct SliderRow: View {
    let title: String
    var help: String?
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    var formatter: (Double) -> String = { "\(Int($0))" }
    var suffix: String = ""

    init(
        _ title: String,
        help: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        formatter: @escaping (Double) -> String = { "\(Int($0))" },
        suffix: String = ""
    ) {
        self.title = title
        self.help = help
        self._value = value
        self.range = range
        self.step = step
        self.formatter = formatter
        self.suffix = suffix
    }

    var body: some View {
        SettingsRow(title, help: help) {
            HStack(spacing: 10) {
                Slider(value: $value, in: range, step: step)
                    .frame(width: 200)
                Text(formatter(value) + suffix)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .trailing)
            }
        }
    }
}

/// A plain toggle row: the title *is* the label, so no `LabeledContent` needed.
struct ToggleRow: View {
    let title: String
    var help: String?
    @Binding var isOn: Bool

    init(_ title: String, help: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.help = help
        self._isOn = isOn
    }

    var body: some View {
        SettingsRow(title, help: help) {
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

/// A `Picker` row that refuses to shrink into an unreadable segmented control. Two
/// options render as a switch-like segmented control; anything else gets a menu.
struct PickerRow<Value: Hashable>: View {
    let title: String
    var help: String?
    @Binding var selection: Value
    let options: [(label: String, value: Value)]
    var width: CGFloat = 220

    init(
        _ title: String,
        help: String? = nil,
        selection: Binding<Value>,
        options: [(label: String, value: Value)],
        width: CGFloat = 220
    ) {
        self.title = title
        self.help = help
        self._selection = selection
        self.options = options
        self.width = width
    }

    var body: some View {
        SettingsRow(title, help: help) {
            if options.count == 2 {
                Picker("", selection: $selection) {
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            } else {
                Picker("", selection: $selection) {
                    ForEach(options, id: \.value) { option in
                        Text(option.label).tag(option.value)
                    }
                }
                .labelsHidden()
                .frame(width: width)
            }
        }
    }
}

// MARK: - Buttons

struct ChooseApplicationButton: View {
    var title: String = "Choose Application…"
    let action: (URL) -> Void

    var body: some View {
        Button(title) {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.applicationBundle]
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.begin { response in
                guard response == .OK, let url = panel.url else { return }
                action(url)
            }
        }
    }
}

func openSystemSettingsPane(_ pane: String) {
    guard let url = URL(string: "x-apple.systempreferences:\(pane)") else { return }
    NSWorkspace.shared.open(url)
}

/// A compact permission row with a "why" hint, used on the System page.
struct PermissionRow: View {
    let title: String
    let pane: String
    let isGranted: Bool
    var request: (() -> Void)?

    var body: some View {
        SettingsRow(title, help: isGranted ? "Granted." : "DockBar needs this to work.") {
            HStack(spacing: 10) {
                Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isGranted ? .green : .orange)
                    .accessibilityHidden(true)
                if !isGranted {
                    if let request {
                        Button("Request", action: request)
                    }
                    Button("Open Settings") {
                        openSystemSettingsPane(pane)
                    }
                    .buttonStyle(.link)
                }
            }
        }
    }
}