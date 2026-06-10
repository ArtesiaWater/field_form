// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3"),
        .package(name: "shared_preferences_foundation", path: "../.packages/shared_preferences_foundation-2.5.6"),
        .package(name: "share_plus", path: "../.packages/share_plus-13.1.0"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.4.9"),
        .package(name: "package_info_plus", path: "../.packages/package_info_plus-10.1.0"),
        .package(name: "native_exif", path: "../.packages/native_exif-0.8.0"),
        .package(name: "map_launcher", path: "../.packages/map_launcher-4.5.0"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.13"),
        .package(name: "flutter_secure_storage_darwin", path: "../.packages/flutter_secure_storage_darwin-0.3.2"),
        .package(name: "flutter_localization", path: "../.packages/flutter_localization-0.4.0"),
        .package(name: "file_picker", path: "../.packages/file_picker-12.0.0-beta.5"),
        .package(name: "camera_avfoundation", path: "../.packages/camera_avfoundation-0.10.1"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "shared-preferences-foundation", package: "shared_preferences_foundation"),
                .product(name: "share-plus", package: "share_plus"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "package-info-plus", package: "package_info_plus"),
                .product(name: "native-exif", package: "native_exif"),
                .product(name: "map-launcher", package: "map_launcher"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "flutter-secure-storage-darwin", package: "flutter_secure_storage_darwin"),
                .product(name: "flutter-localization", package: "flutter_localization"),
                .product(name: "file-picker", package: "file_picker"),
                .product(name: "camera-avfoundation", package: "camera_avfoundation"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
