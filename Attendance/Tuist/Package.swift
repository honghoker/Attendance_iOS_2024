// swift-tools-version: 5.9
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "FirebaseCore": .staticLibrary,
            "FirebaseAuth": .staticLibrary,
            "FirebaseFirestore": .staticLibrary,
            "FirebaseAnalytics": .staticLibrary,
            "FirebaseCrashlytics": .staticLibrary,
            "FirebaseRemoteConfig": .staticLibrary
        ]
    )
#endif

let package = Package(
    name: "DDDAttendance",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit", from: "5.7.0"),
        .package(url: "https://github.com/layoutBox/FlexLayout", from: "2.0.10"),
        .package(url: "https://github.com/layoutBox/PinLayout", from: "1.10.5"),
        .package(url: "https://github.com/ReactorKit/ReactorKit", from: "3.2.0"),
        .package(url: "https://github.com/devxoul/Then", from: "3.0.0"),
        
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.27.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.1.0"),
        
        .package(url: "https://github.com/EFPrefix/EFQRCode.git", exact: "6.2.1"),
        
        
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.0.0"),
        .package(url: "https://github.com/kaishin/Gifu.git", from: "3.4.0"),
        
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/exyte/PopupView.git", from: "2.10.4"),
        
          .package(url: "http://github.com/pointfreeco/swift-composable-architecture", exact: "1.15.0"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-collections.git", branch: "main"),
        .package(url: "https://github.com/johnpatrickmorgan/TCACoordinators.git", from: "0.10.0"),
        .package(url: "https://github.com/Roy-wonji/AsyncMoya",  from: "1.0.9"),
        .package(url: "https://github.com/minsOne/DIContainer.git", from: "1.3.4")
    ]
)
