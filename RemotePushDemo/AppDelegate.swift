//
//  AppDelegate.swift
//  RemotePushDemo
//
//  Created by zhang yinglong on 2017/5/26.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let notificationHandler = NotificationHandler()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        registerNotificationCategory()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        /// Required - 注册 DeviceToken
        let tokenString = deviceToken.hexString
        print("Get Push token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("did Fail To Register For Remote Notifications With Error: %@", error.localizedDescription)
    }
    
    // 本地推送
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        
    }
    
    // 静默远程推送
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Required, iOS 7 Support
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // 普通远程推送
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        // Required,For systems with less than or equal to iOS6
    }
    
    // Called when your app has been activated by the user selecting an action from a local notification.
    // A nil action identifier indicates the default action.
    // You should call the completion handler as soon as you've finished handling the action.
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Swift.Void) {
        
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Swift.Void) {
        
    }
    
    // Called when your app has been activated by the user selecting an action from a remote notification.
    // A nil action identifier indicates the default action.
    // You should call the completion handler as soon as you've finished handling the action.
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Swift.Void) {
        
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Swift.Void) {
        
    }
    
}

extension AppDelegate {
    
    @available(iOS 10.0, *)
    fileprivate func createiOS10Category() -> Set<UNNotificationCategory> {
        let saySomethingCategory: UNNotificationCategory = {
            let inputAction = UNTextInputNotificationAction(
                identifier: SaySomethingCategoryAction.input.rawValue,
                title: "Input",
                options: [.foreground],
                textInputButtonTitle: "Send",
                textInputPlaceholder: "What do you want to say...")
            
            let goodbyeAction = UNNotificationAction(
                identifier: SaySomethingCategoryAction.goodbye.rawValue,
                title: "Goodbye",
                options: [.foreground])
            
            let cancelAction = UNNotificationAction(
                identifier: SaySomethingCategoryAction.none.rawValue,
                title: "Cancel",
                options: [.destructive])
            
            return UNNotificationCategory(identifier: UserNotificationCategoryType.saySomething.rawValue, actions: [inputAction, goodbyeAction, cancelAction], intentIdentifiers: [], options: [.customDismissAction])
        }()
        
        let customUICategory: UNNotificationCategory = {
            let nextAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.switch.rawValue,
                title: "Switch",
                options: [])
            let openAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.open.rawValue,
                title: "Open",
                options: [.foreground])
            let dismissAction = UNNotificationAction(
                identifier: CustomizeUICategoryAction.dismiss.rawValue,
                title: "Dismiss",
                options: [.destructive])
            return UNNotificationCategory(identifier: UserNotificationCategoryType.customUI.rawValue, actions: [nextAction, openAction, dismissAction], intentIdentifiers: [], options: [])
        }()
        return [saySomethingCategory, customUICategory]
    }
    
    fileprivate func createiOS89Category() -> Set<UIUserNotificationCategory> {
        let category: UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
        let saySomethingAction = createCategorys(identifier: CustomizeUICategoryAction.open.rawValue,
                                                 title: "Input",
                                                 activationMode: .foreground,
                                                 authenticationRequired: false,
                                                 destructive: false,
                                                 isTextInput: true,
                                                 titleForSubBtn: "Send")
        let customUIAction = createCategorys(identifier: CustomizeUICategoryAction.dismiss.rawValue,
                                             title: "Dismiss",
                                             activationMode: .foreground,
                                             authenticationRequired: false,
                                             destructive: false,
                                             isTextInput: false,
                                             titleForSubBtn: "")
        category.setActions([saySomethingAction, customUIAction], for: .default)
        return [category]
    }
    
    fileprivate func registerNotificationCategory() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().setNotificationCategories(createiOS10Category())
            UNUserNotificationCenter.current().delegate = notificationHandler
        } else {
            let types: UIUserNotificationType = [.alert, .sound, .badge]
            let settings = UIUserNotificationSettings(types: types, categories: createiOS89Category())
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    fileprivate func createCategorys(identifier: String,
                                     title: String,
                                     activationMode: UIUserNotificationActivationMode,
                                     authenticationRequired: Bool,
                                     destructive: Bool,
                                     isTextInput: Bool,
                                     titleForSubBtn: String) -> UIMutableUserNotificationAction
    {
        let action = UIMutableUserNotificationAction()
        action.identifier = identifier
        action.title = title
        action.activationMode = activationMode
        action.isAuthenticationRequired = authenticationRequired
        action.isDestructive = destructive
        if isTextInput {
            if #available(iOS 9.0, *) {
                action.behavior = .textInput
                action.parameters = [UIUserNotificationTextInputActionButtonTitleKey: titleForSubBtn]
            } else {
                // Fallback on earlier versions
            }
        }
        return action
    }
    
}

extension Data {
    var hexString: String {
        return withUnsafeBytes {(bytes: UnsafePointer<UInt8>) -> String in
            let buffer = UnsafeBufferPointer(start: bytes, count: count)
            return buffer.map {String(format: "%02hhx", $0)}.reduce("", { $0 + $1 })
        }
    }
}
