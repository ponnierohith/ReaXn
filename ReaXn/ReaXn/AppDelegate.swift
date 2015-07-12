//
//  AppDelegate.swift
//  ReaXn
//
//  Created by Kevin Chen on 7/11/15.
//  Copyright (c) 2015 ReaXn. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TSTapDetectorDelegate {

    var window: UIWindow?
    var tapDetector: TSTapDetector!
    
    var phone : TCDevice?
    var connection : TCConnection?
    
    let useNotifications : Bool = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // initialize tap detector
        self.tapDetector = TSTapDetector.init()
        self.tapDetector.listener.collectMotionInformationWithInterval(10)
        self.tapDetector.delegate = self
        
        UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(expirationCallback)
        
        if useNotifications {
            println("==== USING notifications ====")
            registerForActionableNotifications()
        } else {
            println("==== NOT using notification ====")
        }

        return true
    }
    
    func registerForActionableNotifications() {
        // 1. Create the actions **************************************************
        // Open Action
        let helpAction = UIMutableUserNotificationAction()
        helpAction.identifier = "HELP_ACTION"
        helpAction.title = "Help"
        helpAction.activationMode = UIUserNotificationActivationMode.Background
        helpAction.authenticationRequired = false
        helpAction.destructive = false
        
        // 2. Create the category ***********************************************
        
        // Category
        let actionCategory = UIMutableUserNotificationCategory()
        actionCategory.identifier = "HELP_CATEGORY"
        
        // A. Set actions for the default context
        actionCategory.setActions([helpAction],
            forContext: UIUserNotificationActionContext.Default)
        
        // B. Set actions for the minimal context
        actionCategory.setActions([helpAction],
            forContext: UIUserNotificationActionContext.Minimal)
        
        // 3. Notification Registration *****************************************
        
        let types = UIUserNotificationType.Alert | UIUserNotificationType.Sound
        let settings = UIUserNotificationSettings(forTypes: types, categories: NSSet(object: actionCategory) as Set<NSObject>)
        UIApplication.sharedApplication().registerUserNotificationSettings(settings)
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
    
    // We should probably figure out what to do once the expiration times out.
    // Also, Swift closures confuse me so I defined a function handle.
    func expirationCallback() {
        
    }
    
    // Tap detection callback
    func detectorDidDetectTap(detector: TSTapDetector!) {
        
        if useNotifications {
            createNotification()
            
        } else {
            sendSMS()

        }
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate)) //TODO: does this even work?

    }
    
    
    func createNotification() {
        if useNotifications {
            // create a corresponding local notification
            var notification = UILocalNotification()
            notification.alertBody = "Notification text goes here" // text that will be displayed in the notification
            notification.alertAction = "Action" // text that is displayed after "slide to..." on the lock screen - defaults to "slide to view"
            notification.soundName = UILocalNotificationDefaultSoundName // play default sound
            notification.userInfo = ["UUID": NSUUID().UUIDString, ] // assign a unique identifier to the notification so that we can retrieve it later
            notification.category = "HELP_CATEGORY"
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }

    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
        if useNotifications {
            
            // Handle notification action *****************************************
            if notification.category == "HELP_CATEGORY" {
                
                if let action = identifier {
                    switch action{
                        case "HELP_ACTION":
//                            NSNotificationCenter.defaultCenter().postNotificationName("helpNotification", object: self, userInfo: notification.userInfo)
//                            NSNotificationCenter.defaultCenter().postNotificationName("receivedHelpNotification", object: self, userInfo: notification.userInfo)
                        
                            println("Help action triggered")
//                            dialNumber("6083957313")
                        
                            sendSMS()
                        
//                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

                        default:
                            return
                    }
                }
            }
            completionHandler()
            
        }
    }
    
    
    //MARK: - Twilio
    
    func sendSMS() {
        println("Sending request.")
        
//        let phoneNumberKevin = "+6083957313"
        let phoneNumberBen = "+6178179292"
//        let phoneNumberSonny = "+6284449233"
        
        var kTwilioSID: String = Constants.TwilioSID()
        var kTwilioSecret: String = Constants.TwilioSecret()
        
        let phoneNumberTwilio = Constants.TwilioFromNumber()
        var kFromNumber: String = phoneNumberTwilio
        
        var kToNumber : String
        if let storedToNumber = NSUserDefaults.standardUserDefaults().objectForKey(Constants.DefaultsKey_TwilioToPhoneNumber()) as? String {
            kToNumber = storedToNumber
        } else {
            kToNumber = phoneNumberBen
        }
        
        var kMessage : String
        if let storedMessage = NSUserDefaults.standardUserDefaults().objectForKey(Constants.DefaultsKey_TwilioMessage()) as? String {
            kMessage = storedMessage
        } else {
            kMessage = "[**ReaXnTest** Help, I'm not sure if I feel safe right now.]"
        }
        
        let urlString = "https://\(kTwilioSID):\(kTwilioSecret)@api.twilio.com/2010-04-01/Accounts/\(kTwilioSID)/SMS/Messages.json"
        
        if let url = NSURL(string: urlString) {
            var request: NSMutableURLRequest = NSMutableURLRequest()
            request.URL = url
            request.HTTPMethod = "POST"
            var bodyString: String = "From=\(kFromNumber)&To=\(kToNumber)&Body=\(kMessage)"
            if let data: NSData = bodyString.dataUsingEncoding(NSUTF8StringEncoding) {
                request.HTTPBody = data
                
                var response: NSURLResponse?
                var error: NSError?
                let urlData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error)
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    println(httpResponse.statusCode)
                }
            }
            
        }
    }
    
//    func dialNumber(number : String) {
//        let phoneNumber = "telprompt://\(number)"
//        println("calling \(phoneNumber)")
//        UIApplication.sharedApplication().openURL(NSURL(string: phoneNumber)!)
//    }

}

