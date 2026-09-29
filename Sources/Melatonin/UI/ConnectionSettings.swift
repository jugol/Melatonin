import SwiftUI

/// Picks and orders the saved networks Melatonin falls back to when the
/// internet drops.
struct ConnectionSettings: View {
    static let windowID = "connection"

    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var connection = model.connection
        VStack(alignment: .leading, spacing: 0) {
            header(isOn: $connection.isEnabled)
                .padding(.horizontal, 22)
                .padding(.top, 38)
                .padding(.bottom, 16)

            StatusLine(connection: connection)
                .padding(.horizontal, 22)
                .padding(.bottom, 18)

            HStack {
                Text("Priority")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                AddNetworkMenu(connection: connection)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 8)

            NetworkList(connection: connection)
                .padding(.horizontal, 16)

            Text("Drag to reorder. Only networks this Mac has joined before can be added; their saved passwords are used.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 22)
                .padding(.top, 8)

            if model.helperStatus != .ready {
                Label("Needs the helper. Set it up from the menu bar.", systemImage: "lock.shield")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.ember)
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
            }

            Divider().padding(.horizontal, 22).padding(.vertical, 18)

            iPhoneTip
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
        .onAppear { connection.reloadSavedNetworks() }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.networks)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.isEnabled)
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
                Text("If the internet drops while Melatonin keeps your Mac awake, it joins the next network on this list.")
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

    private var iPhoneTip: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "personalhotspot")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 6) {
                Text("Using an iPhone? macOS can join its Personal Hotspot automatically: Wi-Fi settings › Ask to join hotspots › Automatic.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Open Wi-Fi Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension")!)
                }
                .buttonStyle(.link)
                .font(.system(size: 11, weight: .medium))
            }
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
        case .switching: Theme.amber
        case .off, .standby: .secondary
        }
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
                VStack(spacing: 8) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text("Add the networks you want as backups: home, office, your phone’s hotspot.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
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
                .scrollDisabled(connection.networks.count <= 6)
                .frame(height: min(CGFloat(connection.networks.count), 6) * rowHeight + 8)
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

    var body: some View {
        HStack(spacing: 10) {
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
            if network.isHotspot {
                Text("Hotspot")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.green.opacity(0.14)))
            }
            if connection.lastJoined == network.ssid {
                Text("Joined")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.ember)
            }
            Spacer(minLength: 6)
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
}
