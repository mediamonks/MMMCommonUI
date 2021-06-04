// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "MMMCommonUI",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "MMMCommonUI",
            targets: ["MMMCommonUI"]
		)
    ],
    dependencies: [
		.package(url: "https://github.com/mediamonks/MMMCommonCore", .upToNextMajor(from: "1.3.2")),
		.package(url: "https://github.com/mediamonks/MMMObservables", .upToNextMajor(from: "1.2.2")),
		.package(url: "https://github.com/mediamonks/MMMLog", .upToNextMajor(from: "1.2.2")),
		.package(url: "https://github.com/mediamonks/MMMLoadable", .upToNextMajor(from: "1.5.3"))
    ],
    targets: [
        .target(
            name: "MMMCommonUIObjC",
            dependencies: [
				"MMMCommonCore",
				"MMMLoadable",
				"MMMLog",
				"MMMObservables"
            ],
            path: "Sources/MMMCommonUIObjC"
		),
        .target(
            name: "MMMCommonUI",
            dependencies: [
				"MMMCommonUIObjC",
				"MMMCommonCore",
				"MMMObservables",
				"MMMLoadable",
				"MMMLog"
			],
            path: "Sources/MMMCommonUI"
		)
    ]
)
