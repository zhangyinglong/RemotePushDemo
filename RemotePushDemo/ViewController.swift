//
//  ViewController.swift
//  RemotePushDemo
//
//  Created by zhang yinglong on 2017/5/26.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    fileprivate let speecher = Speaker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func sendNotification(_ sender: Any) {
        if #available(iOS 10.0, *) {
            let content = UNMutableNotificationContent()
            content.title = "本地通知";
            content.body = "本地通知测试";
            content.sound = UNNotificationSound.default()
            content.userInfo = ["speech": "收到一条本地通知"]
            if let path = Bundle.main.path(forResource: "background-cover", ofType: "jpg") {
                do {
                    let attachment = try UNNotificationAttachment(identifier: "attachment",
                                                                  url: URL(fileURLWithPath: path),
                                                                  options: nil)
                    content.attachments = [attachment]
                } catch  {

                }
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
            let request = UNNotificationRequest(identifier: "media", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if error == nil {
                    print("send successfully")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }

    @IBAction func speakAction(_ sender: Any) {
        speecher.speak(content: "文本转语音测试")
    }
}

