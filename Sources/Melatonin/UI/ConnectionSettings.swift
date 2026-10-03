import SwiftUI

/// "Stay online": the networks to fall back to, in order, whether they're in
/// range, and the macOS settings that decide the rest.
struct ConnectionSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var connection = model.connection
        let wifi = connection.wifi
        VStack(alignment: .leading, spacing: 0) {
            header(isOn: $connection.isEnabled)
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 16)

            HStack(spacing: 10) {
                StatusLine(connection: connection)
                Spacer()
                Button { connection.testNow() } label: {
                    Label("Restart Wi-Fi", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(connection.isRecovering || model.helperStatus != .ready)
                .help("Wi-Fi turns off for a few seconds, then your Mac rejoins the best saved network.")
            }
            .padding(.horizontal, 22)

            if let recovery = connection.lastRecovery {
                let time = recovery.date.formatted(date: .omitted, time: .shortened)
                Text("Last reconnected at \(time), back online in \(recovery.seconds) s")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
            }

            if model.helperStatus != .ready {
                Label("Needs the helper. Set it up from the menu bar.", systemImage: "lock.shield")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.ember)
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
            }

            if wifi.access != .granted {
                LocationCard(wifi: wifi)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
            }

            HStack(spacing: 8) {
                Text("Priority")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if wifi.access == .granted {
                    Button { Task { await wifi.refresh() } } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .symbolEffect(.pulse, isActive: wifi.isScanning)
                    }
                    .buttonStyle(.borderless)
                    .help("Scan again")
                }
                AddNetworkMenu(connection: connection)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 8)

            NetworkList(connection: connection)
                .padding(.horizontal, 16)

            if let ssid = wifi.askingPasswordFor {
                Label("In the macOS dialog, enter your Mac account name (\(NSUserName())) and login password.", systemImage: "key.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.ember)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .id(ssid)
            } else if wifi.access == .granted, !connection.notReady.isEmpty {
                PasswordNotice(connection: connection)
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
            }

            Text("Melatonin joins the first network in range, top to bottom. If none of them works, it restarts Wi-Fi and lets macOS choose.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .padding(.top, 8)

            Divider().padding(.horizontal, 22).padding(.vertical, 18)

            HotspotTips()
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
        }
        .frame(width: 460)
        .background(alignment: .top) {
            RadialGradient(
                colors: [Color.blue.opacity(connection.isEnabled ? 0.16 : 0.06), .clear],
                center: UnitPoint(x: 0.15, y: 0), startRadius: 0, endRadius: 320
            )
            .frame(height: 260)
            .allowsHitTesting(false)
        }
        .onAppear {
            connection.reloadSavedNetworks()
            connection.checkReady()
            Task { await wifi.refresh() }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.networks)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.isEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: wifi.access)
    }

    private func header(isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "wifi")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.55, blue: 1.0), Color(red: 0.22, green: 0.33, blue: 0.86)],
                                             startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Stay online")
                    .font(.system(size: 20, weight: .semibold, design: Theme.rounded))
                Text("If the internet drops while Melatonin keeps your Mac awake, it joins the first network on your list that’s in range. If none works, it restarts Wi-Fi so macOS can pick one.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Theme.ember)
                .labelsHidden()
        }
    }
}

/// Asks for Location access, which is what lets Melatonin see network names.
private struct LocationCard: View {
    let wifi: WiFiAccess

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "location.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 6) {
                Text("Choose networks by name")
                    .font(.system(size: 12, weight: .semibold))
                Text(wifi.access == .denied
                     ? "Location access is off. Turn on Melatonin in System Settings › Privacy & Security › Location Services."
                     : "macOS only shows Wi-Fi network names to apps with Location access. Allow it and Melatonin can join your networks in the order you set. Your location is never used or stored.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    wifi.access == .denied ? wifi.openPrivacySettings() : wifi.requestAccess()
                } label: {
                    Text(wifi.access == .denied ? "Open Privacy Settings" : "Allow Location Access")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.blue.opacity(0.08))
                .strokeBorder(Color.blue.opacity(0.25), lineWidth: 0.5)
        )
    }
}

private struct AddNetworkMenu: View {
    let connection: ConnectionGuard

    var body: some View {
        Menu {
            if connection.availableToAdd.isEmpty {
                Text("No other saved networks")
            }
            ForEach(connection.availableToAdd, id: \.self) { ssid in
                Button {
                    connection.add(ssid)
                } label: {
                    Label(ssid, systemImage: FallbackNetwork.looksLikeHotspot(ssid) ? "personalhotspot" : "wifi")
                }
            }
        } label: {
            Label("Add network", systemImage: "plus")
                .font(.system(size: 12, weight: .medium))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

private struct NetworkList: View {
    let connection: ConnectionGuard
    private let rowHeight: CGFloat = 40

    var body: some View {
        Group {
            if connection.networks.isEmpty {
                Text("Add the networks you want as backups: home, office, your phone’s hotspot.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                    .padding(.horizontal, 30)
            } else {
                List {
                    ForEach(Array(connection.networks.enumerated()), id: \.element.id) { index, network in
                        NetworkRow(rank: index + 1, network: network, connection: connection)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6))
                    }
                    .onMove(perform: connection.move)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(connection.networks.count <= 7)
                .frame(height: min(CGFloat(connection.networks.count), 7) * rowHeight + 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.primary.opacity(0.04))
                .strokeBorder(.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

private struct NetworkRow: View {
    let rank: Int
    let network: FallbackNetwork
    let connection: ConnectionGuard

    private var wifi: WiFiAccess { connection.wifi }
    private var isCurrent: Bool { wifi.current == network.ssid }
    private var signal: Int? { wifi.nearby[network.ssid] }
    private var isJoining: Bool { connection.status == .switching(network.ssid) }

    var body: some View {
        HStack(spacing: 8) {
            Text(verbatim: "\(rank)")
                .font(.system(size: 11, weight: .bold, design: Theme.rounded))
                .foregroundStyle(rank == 1 ? AnyShapeStyle(Theme.ink) : AnyShapeStyle(.secondary))
                .frame(width: 20, height: 20)
                .background(Circle().fill(rank == 1 ? AnyShapeStyle(Theme.amber) : AnyShapeStyle(.primary.opacity(0.08))))
            Image(systemName: network.isHotspot ? "personalhotspot" : "wifi")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(network.isHotspot ? .green : .blue)
                .frame(width: 18)
            Text(network.ssid)
                .font(.system(size: 13))
                .lineLimit(1)
            if isCurrent {
                chip("Connected", color: .green)
            } else if wifi.access == .granted, signal != nil {
                chip("In range", color: .blue)
            }
            Spacer(minLength: 4)
            Button { connection.connectNow(network) } label: {
                Image(systemName: isJoining ? "ellipsis.circle" : "arrow.right.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.ember)
                    .symbolEffect(.pulse, isActive: isJoining)
            }
            .buttonStyle(.borderless)
            .disabled(connection.isRecovering || wifi.access != .granted || isCurrent)
            .help("Connect now")
            Button { connection.toggleHotspot(network) } label: {
                Image(systemName: network.isHotspot ? "personalhotspot.circle.fill" : "personalhotspot.circle")
                    .font(.system(size: 15))
                    .foregroundStyle(network.isHotspot ? AnyShapeStyle(.green) : AnyShapeStyle(.tertiary))
            }
            .buttonStyle(.borderless)
            .help("Mark as hotspot")
            Button { connection.remove(network) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.borderless)
            .help("Remove")
        }
        .frame(height: 40)
        .contentShape(Rectangle())
    }

    private func chip(_ title: LocalizedStringKey, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.14)))
            .fixedSize()
    }
}

/// One quiet line when some networks can't be joined yet, with a way to fix it.
private struct PasswordNotice: View {
    let connection: ConnectionGuard

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "key")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                let names = connection.notReady.map(\.ssid).formatted(.list(type: .and))
                Text("Not ready yet: \(names)")
                    .font(.system(size: 11, weight: .semibold))
                Text("Melatonin needs your OK to use the Wi-Fi passwords macOS already saved for these networks. Until then, they’re skipped when the internet drops.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Allow saved passwords") { connection.allowSavedPasswords() }
                    .buttonStyle(.link)
                    .font(.system(size: 11, weight: .semibold))
            }
        }
    }
}

/// The macOS and phone settings that decide whether the hotspot gets picked
/// when Melatonin falls back to restarting Wi-Fi.
private struct HotspotTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Make sure your Mac picks your phone’s hotspot", systemImage: "personalhotspot")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            tip(1, "Join the hotspot once from the Wi-Fi menu so your Mac saves it.")
            tip(2, "In System Settings › Wi-Fi, open the hotspot’s Details and turn on “Automatically join this network”.")
            tip(3, "Android: turn off the setting that switches the hotspot off when no devices are connected.")
            tip(4, "Using an iPhone? macOS can join its Personal Hotspot automatically: Wi-Fi settings › Ask to join hotspots › Automatic.")
            Button("Open Wi-Fi Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension")!)
            }
            .buttonStyle(.link)
            .font(.system(size: 11, weight: .medium))
            .padding(.leading, 26)
        }
    }

    private func tip(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: "\(number)")
                .font(.system(size: 10, weight: .bold, design: Theme.rounded))
                .foregroundStyle(.green)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.green.opacity(0.14)))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StatusLine: View {
    let connection: ConnectionGuard

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.8), radius: 3)
            Text(connection.summary)
                .font(.system(size: 12, weight: .medium, design: Theme.rounded))
                .lineLimit(1)
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private var color: Color {
        switch connection.status {
        case .online: .green
        case .offline, .exhausted: .red
        case .switching, .restartingWiFi: Theme.amber
        case .off, .standby: .secondary
        }
    }
}
