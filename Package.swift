// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pizza3DEngine",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Pizza3DEngine",
            targets: ["Pizza3DEngine"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Pizza3DEngine",
            dependencies: [],
            resources: [
                .copy("Gizmos/Rotate/ring1.obj"),
                .copy("Gizmos/Rotate/ring2.obj"),
                .copy("Gizmos/Rotate/ring3.obj"),
                
                .copy("Gizmos/Scale/cube.obj"),
                .copy("Gizmos/Scale/scale1.obj"),
                .copy("Gizmos/Scale/scale2.obj"),
                .copy("Gizmos/Scale/scale3.obj"),
                
                .copy("Gizmos/Translate/sphere.obj"),
                .copy("Gizmos/Translate/arrow1.obj"),
                .copy("Gizmos/Translate/arrow2.obj"),
                .copy("Gizmos/Translate/arrow3.obj"),

                .copy("Data/demo_hex.mesh"),
                .copy("Data/demo_tet.mesh"),
                .copy("Data/demo_tri.obj"),
                .copy("Data/demo_quad.obj"),
                
                .copy("Shader/Shaders.metal")
            ]
        )
    ]
)
