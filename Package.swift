// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AgentKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "AgentKitCore", targets: ["AgentKitCore"]),
        .library(name: "AgentKitProviders", targets: ["AgentKitProviders"]),
        .library(name: "AgentKitChat", targets: ["AgentKitChat"]),
        .library(name: "AgentKitMCP", targets: ["AgentKitMCP"]),
        .library(name: "AgentKitDevTools", targets: ["AgentKitDevTools"]),
        .library(name: "AgentKitTestSupport", targets: ["AgentKitTestSupport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic.git", from: "2.1.0"),
        .package(url: "https://github.com/MacPaw/OpenAI.git", from: "0.4.0"),
    ],
    targets: [
        // MARK: - Core (zero external dependencies)
        .target(
            name: "AgentKitCore",
            dependencies: [],
            path: "Sources/AgentKitCore"
        ),

        // MARK: - Providers (Core + third-party SDKs)
        .target(
            name: "AgentKitProviders",
            dependencies: [
                "AgentKitCore",
                .product(name: "SwiftAnthropic", package: "SwiftAnthropic"),
                .product(name: "OpenAI", package: "OpenAI"),
            ],
            path: "Sources/AgentKitProviders"
        ),

        // MARK: - Chat UI (Core only, imports SwiftUI)
        .target(
            name: "AgentKitChat",
            dependencies: ["AgentKitCore"],
            path: "Sources/AgentKitChat"
        ),

        // MARK: - MCP (Core only)
        .target(
            name: "AgentKitMCP",
            dependencies: ["AgentKitCore"],
            path: "Sources/AgentKitMCP"
        ),

        // MARK: - DevTools (Core only, debug builds)
        .target(
            name: "AgentKitDevTools",
            dependencies: ["AgentKitCore"],
            path: "Sources/AgentKitDevTools"
        ),

        // MARK: - Test Support (public mocks)
        .target(
            name: "AgentKitTestSupport",
            dependencies: ["AgentKitCore"],
            path: "Sources/AgentKitTestSupport"
        ),

        // MARK: - Tests
        .testTarget(
            name: "AgentKitCoreTests",
            dependencies: ["AgentKitCore", "AgentKitTestSupport"]
        ),
        .testTarget(
            name: "AgentKitProviderTests",
            dependencies: ["AgentKitProviders", "AgentKitTestSupport"]
        ),
        .testTarget(
            name: "AgentKitChatTests",
            dependencies: ["AgentKitChat", "AgentKitTestSupport"]
        ),
    ]
)
