import AppKit
import SwiftUI

/// First-run walkthrough.
///
/// Four steps, each answering one question. An earlier version had five and asked the
/// same thing twice — "choose your style" and then "personalise your DeskBar" both
/// covered layout — so the style and the handful of choices that really matter now live
/// on one screen, with a live preview of the actual bar.
struct OnboardingView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var calendarService = CalendarEventService.shared
    let completion: () -> Void

    final class ViewState: ObservableObject {
        @Published var step = 0
    }

    @StateObject private var state = ViewState()

    static let stepCount = 4
    private var isLastStep: Bool { state.step == Self.stepCount - 1 }

    var body: some View {
        VStack(spacing: 0) {
            banner
            content
            footer
        }
        .frame(width: 820, height: 620)
    }

    // MARK: Banner

    private var banner: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            icon
                .transition(.scale.combined(with: .opacity))
        }
        .frame(height: 190)
        .clipped()
    }

    @ViewBuilder
    private var icon: some View {
        switch state.step {
        case 0:
            Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 116, height: 116)
                .shadow(radius: 18)
        case 1:
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.white)
        case 2:
            TaskbarStylePreviewView(spec: settings.taskbarMode.spec, isSelected: true)
                    .padding(.horizontal, 60)
                    .frame(maxHeight: .infinity)
        default:
            Image(systemName: "dock.rectangle")
                .font(.system(size: 72))
                .foregroundStyle(.white)
        }
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 18) {
            switch state.step {
            case 0: welcomeStep
            case 1: permissionsStep
            case 2: styleStep
            default: dockStep
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 40)
        .padding(.top, 26)
    }

    private var welcomeStep: some View {
        VStack(spacing: 10) {
            Text("Welcome to DockBar")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("A taskbar for macOS that behaves the way you want it to. Three quick questions and you are set.")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 460)
        }
    }

    private var permissionsStep: some View {
        VStack(spacing: 14) {
            Text("Permissions")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("Each one unlocks a feature. You can grant them later in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                OnboardingPermissionCard(
                    title: "Accessibility",
                    description: "Required to move, focus, and switch between windows.",
                    isGranted: permissionsManager.isAccessibilityGranted,
                    action: { permissionsManager.requestAccessibilityPermission() }
                )
                OnboardingPermissionCard(
                    title: "Screen Recording",
                    description: "Required for live window thumbnails.",
                    isGranted: thumbnailService.isScreenRecordingGranted,
                    action: {
                        if !thumbnailService.requestScreenRecordingPermission() {
                            openSystemSettingsPane("Privacy_ScreenCapture")
                        }
                    }
                )
                OnboardingPermissionCard(
                    title: "Calendar",
                    description: "Required to show upcoming events in the widget.",
                    isGranted: calendarService.isAuthorized,
                    action: {
                        calendarService.checkPermission()
                        openSystemSettingsPane("Privacy_Calendars")
                    }
                )
            }
            .frame(maxWidth: 520)
        }
    }

    private var styleStep: some View {
        VStack(spacing: 14) {
            Text("Choose your bar")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("Pick a starting point. Every option is fully adjustable in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            TaskbarStylePicker(selection: $settings.taskbarMode)
                .frame(maxWidth: 560)

            HStack(spacing: 28) {
                OnboardingChoice(
                    title: "Group windows by app",
                    isOn: Binding(
                        get: { settings.groupingMode != .never },
                        set: { settings.groupingMode = $0 ? .always : .never }
                    )
                )
                OnboardingChoice(
                    title: "Show window titles",
                    isOn: $settings.showTitles
                )
                OnboardingChoice(
                    title: "Connectivity alerts",
                    isOn: $settings.showConnections
                )
            }
            .padding(.top, 4)
        }
    }

    private var dockStep: some View {
        VStack(spacing: 16) {
            Text("The native Dock")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("DockBar can leave the Dock alone, or take its place. You can change this later.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(NativeDockBehavior.allCases) { behavior in
                    Button {
                        settings.nativeDockBehavior = behavior
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.nativeDockBehavior == behavior
                                ? "largecircle.fill.circle"
                                : "circle")
                                .foregroundStyle(settings.nativeDockBehavior == behavior
                                    ? Color.accentColor
                                    : Color.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(behavior.displayName)
                                Text(behavior.help)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 460)
            .padding(.top, 4)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            if state.step > 0 {
                Button("Back") {
                    withAnimation { state.step -= 1 }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if state.step > 0 {
                Text("Step \(state.step + 1) of \(Self.stepCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(isLastStep ? "Finish" : "Continue") {
                if isLastStep {
                    completion()
                } else {
                    withAnimation { state.step += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 26)
    }
}

/// A compact labelled switch for the onboarding choices that are not part of the
/// style choice itself.
struct OnboardingChoice: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .toggleStyle(.switch)
            .controlSize(.small)
    }
}