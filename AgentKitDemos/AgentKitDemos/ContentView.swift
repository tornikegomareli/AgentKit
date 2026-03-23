import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Demos") {
                    NavigationLink {
                        VaultBankingDemo()
                    } label: {
                        demoCatalogRow(
                            icon: "building.columns.fill",
                            color: Color(red: 0.1, green: 0.23, blue: 0.36),
                            title: "Vault — Banking & Finance",
                            subtitle: "10 tools: transfers, spending analysis, payees, savings goals"
                        )
                    }

                    NavigationLink {
                        MeridianDocsDemo()
                    } label: {
                        demoCatalogRow(
                            icon: "text.magnifyingglass",
                            color: Color(red: 0.78, green: 0.58, blue: 0.23),
                            title: "Meridian — Docs & Knowledge",
                            subtitle: "9 tools: search, summarize, freshness audit, contradictions"
                        )
                    }

                    NavigationLink {
                        VoltaTasksDemo()
                    } label: {
                        demoCatalogRow(
                            icon: "bolt.fill",
                            color: Color(red: 0.16, green: 0.16, blue: 0.18),
                            title: "Volta — Task Management",
                            subtitle: "9 tools: board, sprint health, dependencies, assignments"
                        )
                    }

                    NavigationLink {
                        LumenEmailDemo()
                    } label: {
                        demoCatalogRow(
                            icon: "tray.fill",
                            color: Color(red: 0.12, green: 0.44, blue: 0.66),
                            title: "Lumen — Email & Calendar",
                            subtitle: "12 tools: triage, draft replies, schedule meetings, labels"
                        )
                    }

                    NavigationLink {
                        ShoppingAssistantDemo()
                    } label: {
                        demoCatalogRow(
                            icon: "bag.fill",
                            color: .indigo,
                            title: "Shopping Assistant",
                            subtitle: "5 tools: search, cart, orders, product details"
                        )
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set your API key in APIKeys.swift")
                            .font(.subheadline.weight(.medium))
                        Text("Or set OPENAI_API_KEY env var in scheme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.yellow.opacity(0.1))
                }
            }
            .navigationTitle("AgentKit Demos")
        }
    }

    private func demoCatalogRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color, in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
