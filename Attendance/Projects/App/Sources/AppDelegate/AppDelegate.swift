import Firebase

import UIKit

//@main
//class AppDelegate: UIResponder, UIApplicationDelegate {
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        FirebaseApp.configure()
//        registerDependencies()
//        return true
//    }
//    
//    func application(
//        _ application: UIApplication,
//        configurationForConnecting connectingSceneSession: UISceneSession,
//        options: UIScene.ConnectionOptions
//    ) -> UISceneConfiguration {
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//    
//    func application(
//        _ application: UIApplication,
//        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
//    ) {
//    }
//    
//    private func registerDependencies() {
//        Task {
//            await AppDIContainer.shared.registerDependencies()
//        }
//    }
//}
