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
        .library(name: "CoreDataTestSupport", targets: ["CoreDataTestSupport"])
    ],
    targets: [
        .target(name: "NetworkStub"),
        .target(name: "UITestHelpers"),
        .target(name: "TimeControl"),
        .target(name: "KeychainStore"),
        .target(name: "CoreDataTestSupport")
    ]
)
