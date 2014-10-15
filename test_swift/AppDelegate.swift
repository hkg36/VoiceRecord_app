//
//  AppDelegate.swift
//  test_swift
//
//  Created by xinchen on 14-9-19.
//  Copyright (c) 2014年 co.po. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        if(UIApplication.instancesRespondToSelector(Selector("registerUserNotificationSettings:")))
        {
            application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))
        }
        SQLiteDB.instanse.execute("CREATE TABLE voice_log (id integer PRIMARY KEY AUTOINCREMENT,title Varchar(128),file Varchar(1024),time Timestamp DEFAULT CURRENT_TIMESTAMP,duration float)", parameters: nil)
        if let localNotification:UILocalNotification  = launchOptions?[UIApplicationLaunchOptionsLocalNotificationKey] as?UILocalNotification {
            dispatch_after(1, dispatch_get_main_queue(), {
                if let appdel=UIApplication.sharedApplication().delegate as? AppDelegate{
                    appdel.application(UIApplication.sharedApplication(),didReceiveLocalNotification:localNotification)
                }
            })
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification)
    {
        if let id: AnyObject=notification.userInfo?["id"]{
            let locnotifyid=id as? Int
            AlertPlayView.Show(locnotifyid!)
        }
    }
}

