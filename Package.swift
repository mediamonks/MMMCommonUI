// swift-tools-version:5.4
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
		.package(url: "https://github.com/mediamonks/MMMLoadable", .upToNextMajor(from: "1.5.3")),
		.package(url: "https://github.com/mediamonks/MMMTestCase", .upToNextMajor(from: "1.4.0"))
    ],
    targets: [
        .target(
            name: "MMMCommonUIObjC",
            dependencies: [
				"MMMCommonCore",
				"MMMLoadable",
				"MMMObservables",
				"MMMLog"
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
		),
		.testTarget(
			name: "MMMCommonUITests",
			dependencies: [
				"MMMTestCase",
				"MMMCommonUI"
			],
			path: "Tests",
			resources: [
				.copy("TestResources")
			]
		)
    ]
)
