// swift-tools-version:5.7

/**
*  Batlin
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import PackageDescription

let package = Package(
    name: "Batlin",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "Batlin", targets: ["Batlin"]),
        .executable(name: "Batlin-cli", targets: ["BatlinCLI"]),
        .library(
            name: "HighlightJSBatlinPlugin",
            targets: ["HighlightJSBatlinPlugin"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/johnsundell/Ink.git",
            from: "0.2.0"
        ),
        .package(
            url: "https://github.com/johnsundell/Plot.git",
            from: "0.9.0"
        ),
        .package(
            url: "https://github.com/johnsundell/Files.git",
            from: "4.3.0"
        ),
        .package(
            url: "https://github.com/johnsundell/Codextended.git",
            from: "0.1.0"
        ),
        .package(
            url: "https://github.com/johnsundell/ShellOut.git",
            from: "2.3.0"
        ),
        .package(
            url: "https://github.com/johnsundell/Sweep.git",
            from: "0.4.0"
        ),
        .package(
            url: "https://github.com/johnsundell/CollectionConcurrencyKit.git",
            from: "0.1.0"
        ),
        .package(
            url: "https://github.com/apple/swift-docc-plugin", 
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/MichaelJBerk/Parsley", 
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "Batlin",
            dependencies: [
                "Ink", "Plot", "Files", "Codextended",
                "ShellOut", "Sweep", "CollectionConcurrencyKit",
                "Parsley"
            ]
        ),
        .executableTarget(
            name: "BatlinCLI",
            dependencies: ["BatlinCLICore"]
        ),
        .target(
            name: "BatlinCLICore",
            dependencies: ["Batlin"]
        ),
        .target(
            name: "HighlightJSBatlinPlugin",
            dependencies: ["HighlightJS", "Batlin"]
        ),
        .target(name: "HighlightJS"),
        .testTarget(
            name: "BatlinTests",
            dependencies: ["Batlin", "BatlinCLICore"]
        ),
        .testTarget(
            name: "HighlightJSTests",
            dependencies: ["HighlightJS"]
        )
      
    ]
)
