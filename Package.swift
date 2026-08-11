// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "iOSTestKit",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "NetworkStub", targets: ["NetworkStub"]),
        .library(name: "UITestHelpers", targets: ["UITestHelpers"]),
        .library(name: "TimeControl", targets: ["TimeControl"]),
        .library(name: "KeychainStore", targets: ["KeychainStore"]),
        .library(name: "CoreDataTestSupport", targets: ["CoreDataTestSupport"]),
        .library(name: "LocalNotifications", targets: ["LocalNotifications"]),
        .library(name: "SnapshotTesting", targets: ["SnapshotTesting"]),
        .library(name: "DeepLinkTesting", targets: ["DeepLinkTesting"]),
        .library(name: "LocationAuthorization", targets: ["LocationAuthorization"]),
        .library(name: "PurchaseSupport", targets: ["PurchaseSupport"]),
        .library(name: "DebugOverlay", targets: ["DebugOverlay"]),
        .library(name: "UserDefaultsStore", targets: ["UserDefaultsStore"]),
        .library(name: "PhotoLibraryAuthorization", targets: ["PhotoLibraryAuthorization"]),
        .library(name: "BiometricAuthentication", targets: ["BiometricAuthentication"]),
        .library(name: "PushRegistering", targets: ["PushRegistering"]),
        .library(name: "AppleSignIn", targets: ["AppleSignIn"]),
        .library(name: "BackgroundTaskScheduling", targets: ["BackgroundTaskScheduling"]),
        .library(name: "ContactsAuthorization", targets: ["ContactsAuthorization"])
    ],
    targets: [
        .target(name: "NetworkStub"),
        .target(name: "UITestHelpers"),
        .target(name: "TimeControl"),
        .target(name: "KeychainStore"),
        .target(name: "CoreDataTestSupport"),
        .target(name: "LocalNotifications"),
        .target(name: "SnapshotTesting"),
        .target(name: "DeepLinkTesting"),
        .target(name: "LocationAuthorization"),
        .target(name: "PurchaseSupport"),
        .target(name: "DebugOverlay"),
        .target(name: "UserDefaultsStore"),
        .target(name: "PhotoLibraryAuthorization"),
        .target(name: "BiometricAuthentication"),
        .target(name: "PushRegistering"),
        .target(name: "AppleSignIn"),
        .target(name: "BackgroundTaskScheduling"),
        .target(name: "ContactsAuthorization")
    ]
)
