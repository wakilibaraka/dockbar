import SwiftUI

struct WidgetsSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @StateObject private var quickSettingsEditor = QuickSettingsEditorState()

    var body: some View {
        SettingsPage(
            title: "Widgets",
            subtitle: "Status widgets can live in the bar, the menu bar, or both. Order is preserved wherever they sit."
        ) {
            SettingsGroup(
                "Placement",
                footer: "Menu bar widgets appear next to the system status items; bar widgets appear at the trailing edge of the bar."
            ) {
                PickerRow(
                    "Calendar & Quick Settings",
                    help: "The combined calendar and quick settings control.",
                    selection: $settings.connectivityTrayLocation,
                    options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                )
                ToggleRow(
                    "Split Calendar and Quick Settings",
                    help: "Show them as two separate items so each can live somewhere different.",
                    isOn: $settings.splitCalendarAndQuickSettings
                )
                if settings.splitCalendarAndQuickSettings {
                    PickerRow(
                        "Calendar",
                        help: "Where the calendar widget appears.",
                        selection: $settings.calendarLocation,
                        options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                    )
                    PickerRow(
                        "Quick Settings",
                        help: "Where the quick settings widget appears.",
                        selection: $settings.quickSettingsLocation,
                        options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                    )
                }
            }

            SettingsGroup("Order", footer: "Drag to reorder. The order follows each widget between the bar and the menu bar.") {
                ForEach(settings.dockWidgetOrder, id: \.self) { rawValue in
                    if let widget = DockWidgetID(rawValue: rawValue) {
                        HStack(spacing: 10) {
                            Image(systemName: "line.3.horizontal")
                                .foregroundStyle(.tertiary)
                            Text(widget.displayName)
                            Spacer()
                            Text(SettingsCatalog.descriptor(for: widgetSettingID(for: widget)) == nil
                                ? ""
                                : currentLocationLabel(for: widget))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 1)
                    }
                }
                .onMove { source, destination in
                    settings.dockWidgetOrder.move(fromOffsets: source, toOffset: destination)
                }
            }

            SettingsGroup("Battery") {
                PickerRow(
                    "Location",
                    help: "Where the battery widget appears.",
                    selection: $settings.batteryWidgetLocation,
                    options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                )
                ToggleRow(
                    "Percentage Next to Icon",
                    help: "Show the charge percentage beside the icon.",
                    isOn: $settings.showBatteryPercentage
                )
                ToggleRow(
                    "Percentage Inside Icon",
                    help: "Draw the percentage inside the icon instead. Cleaner, but harder to read at small sizes.",
                    isOn: $settings.showPercentageInsideIcon
                )
                PickerRow(
                    "Icon Style",
                    help: "Shape of the battery indicator.",
                    selection: $settings.batteryIconStyle,
                    options: BatteryIconStyle.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Icon Size",
                    help: "Size of the battery indicator.",
                    selection: $settings.batteryIconSize,
                    options: BatteryIconSize.allCases.map { ($0.displayName, $0) }
                )
            }

            SettingsGroup("System Resources") {
                ToggleRow(
                    "Show System Resources",
                    help: "Show live CPU, memory, GPU, and network activity.",
                    isOn: $settings.showSystemResourceWidget
                )
                PickerRow(
                    "Location",
                    help: "Where the resources widget appears.",
                    selection: $settings.systemResourceWidgetLocation,
                    options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Display",
                    help: "Bars are cheap; graphs show the last few minutes of activity.",
                    selection: $settings.resourceDisplayStyle,
                    options: ResourceDisplayStyle.allCases.map { ($0.displayName, $0) }
                )
            }

            SettingsGroup("Weather") {
                ToggleRow(
                    "Enable Weather",
                    help: "Show current conditions and the forecast.",
                    isOn: $settings.weatherEnabled
                )
                PickerRow(
                    "Location",
                    help: "Where the weather widget appears.",
                    selection: $settings.weatherWidgetLocation,
                    options: WidgetLocation.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Units",
                    help: "Celsius or Fahrenheit.",
                    selection: $settings.weatherUnit,
                    options: WeatherUnit.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Refresh",
                    help: "How often the forecast is refreshed. More often costs battery.",
                    selection: $settings.weatherPollingInterval,
                    options: [
                        ("15 minutes", TimeInterval(900)),
                        ("30 minutes", TimeInterval(1800)),
                        ("1 hour", TimeInterval(3600)),
                    ]
                )
                PickerRow(
                    "Place",
                    help: "Use the location macOS knows, or enter coordinates yourself.",
                    selection: $settings.weatherLocationMode,
                    options: WeatherLocationMode.allCases.map { ($0.displayName, $0) }
                )
                if settings.weatherLocationMode == .manual {
                    TextField("Latitude", value: $settings.weatherManualLatitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                    TextField("Longitude", value: $settings.weatherManualLongitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
            }

            SettingsGroup("Quick Settings Toggles", footer: "Drag to reorder. Unchecked toggles are hidden from the flyout.") {
                ForEach($quickSettingsEditor.items) { $item in
                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(.tertiary)
                        Image(systemName: item.symbol)
                            .frame(width: 22)
                            .foregroundStyle(.secondary)
                        Text(item.title)
                        Spacer()
                        Toggle("", isOn: $item.isEnabled)
                            .labelsHidden()
                            .onChange(of: item.isEnabled) {
                                quickSettingsEditor.persist(into: settings)
                            }
                    }
                    .padding(.vertical, 1)
                }
                .onMove { source, destination in
                    quickSettingsEditor.items.move(fromOffsets: source, toOffset: destination)
                    quickSettingsEditor.persist(into: settings)
                }
            }

            SettingsGroup("Connectivity", footer: "Alerts appear as notifications. macOS only allows them once you grant permission.") {
                ToggleRow(
                    "Connectivity Icon",
                    help: "Show Wi-Fi and Bluetooth status in the menu bar.",
                    isOn: $settings.showConnections
                )
                ToggleRow(
                    "Bluetooth Connected",
                    help: "Notify when a Bluetooth device connects or disconnects.",
                    isOn: $settings.notifyBluetoothConnect
                )
                ToggleRow(
                    "Bluetooth Low Battery",
                    help: "Notify when a Bluetooth device runs low on battery.",
                    isOn: $settings.notifyBluetoothLowBattery
                )
                ToggleRow(
                    "Network Changed",
                    help: "Notify when the machine joins a different network.",
                    isOn: $settings.notifyWiFiChange
                )
                ToggleRow(
                    "Weak Signal",
                    help: "Notify when the Wi-Fi signal degrades.",
                    isOn: $settings.notifyWiFiWeak
                )
                HStack {
                    Button("Send Test Notification") {
                        NotificationManager.shared.requestAuthorization { granted in
                            guard granted else { return }
                            DispatchQueue.main.async {
                                NotificationManager.shared.sendNotification(
                                    title: "DockBar",
                                    body: "This is a test notification from Settings.",
                                    identifier: UUID().uuidString
                                )
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            quickSettingsEditor.load(settings: settings)
        }
    }

    private func widgetSettingID(for widget: DockWidgetID) -> String {
        switch widget {
        case .connectivity: return "connectivityTrayLocation"
        case .calendar: return "calendarLocation"
        case .quickSettings: return "quickSettingsLocation"
        case .systemResources: return "systemResourceWidgetLocation"
        case .battery: return "batteryWidgetLocation"
        case .weather: return "weatherWidgetLocation"
        }
    }

    private func currentLocationLabel(for widget: DockWidgetID) -> String {
        let location: WidgetLocation
        switch widget {
        case .connectivity: location = settings.connectivityTrayLocation
        case .calendar: location = settings.calendarLocation
        case .quickSettings: location = settings.quickSettingsLocation
        case .systemResources: location = settings.systemResourceWidgetLocation
        case .battery: location = settings.batteryWidgetLocation
        case .weather: location = settings.weatherWidgetLocation
        }
        return location.displayName
    }
}