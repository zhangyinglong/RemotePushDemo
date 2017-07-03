## 简介
在 iOS 10 中新加入 [UserNotifications](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/index.html) 框架，对以往杂乱无章的通知系统 API 进行了统一，更方便开发者们快速引用。关于新框架的一些基本概念在[喵大](https://onevcat.com/#blog)的[《iOS 10 UserNotifications 框架解析》](https://onevcat.com/2016/08/notification/)已有详细的描述，本文只对实践中的具体运用做介绍。

## 基本流程
iOS 10中通知相关操作遵循下面的流程：
![流程.png](http://upload-images.jianshu.io/upload_images/1200910-186dbbcc9eb480fd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 权限申请
iOS 各个版本 Notifications 权限申请代码如下：

```
// iOS 10 support
if #available(iOS 10.0, *) {
    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
    UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
        if granted {
           // 用户允许进行通知
        }
    }
}
// iOS 9 support
else if #available(iOS 9, *) {
    let types: UIUserNotificationType = [.alert, .sound, .badge]
    let settings = UIUserNotificationSettings(types: types, categories: nil)
    UIApplication.shared.registerUserNotificationSettings(settings)
    // ...其他操作
    if UIApplication.shared.currentUserNotificationSettings?.types != [] {
        // 用户允许进行通知
    }
} 
// iOS 8 support
else if #available(iOS 8, *) {
    let types: UIUserNotificationType = [.alert, .sound, .badge]
    let settings = UIUserNotificationSettings(types: types, categories: nil)
    UIApplication.shared.registerUserNotificationSettings(settings)
    // ...其他操作
    if UIApplication.shared.currentUserNotificationSettings?.types != [] {
        // 用户允许进行通知
    }
} 
// iOS 7 support
else {
    let types: UIRemoteNotificationType = [.badge, .sound, .alert]
    UIApplication.shared.registerForRemoteNotifications(matching: types)
}

```
#### 注册Token
当用户同意授权以后，还需要向系统注册一个 Device Token，并将这个 token 发送到 APNs（Apple Push Notification Service），然后 APNs 通过 token 识别设备和应用，讲通知推送给用户。

```
// 向 APNs 请求 token
UIApplication.shared.registerForRemoteNotifications()

// Called when APNs has assigned the device a unique token
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let tokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
    print("APNs device token: \(tokenString)")
    // 上传至后台服务器
}

// Called when APNs failed to register the device for push notifications
func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {  
    // Print the error to console (you should alert the user that registration failed)
    print("APNs registration failed: \(error)")
}
```
#### 发送推送通知
关于 [APNs 的推送原理](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/APNSOverview.html) 就不做详细说明，这里以 Node.js 为例子搭建推送测试工具，步骤如下：
1、创建 APNs 服务的访问 [Auth Key ID](https://developer.apple.com/account/ios/certificate/key)
![创建key.png](http://upload-images.jianshu.io/upload_images/1200910-3f9262cda6d68e2d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
2、获取 Key ID，点击 Download 同时下载 .p8 证书文件
![获取key.png](http://upload-images.jianshu.io/upload_images/1200910-9452cf58894a77ba.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
2、获取开发者账号的 [Team ID](https://developer.apple.com/account/#/membership)
![Membership.png](http://upload-images.jianshu.io/upload_images/1200910-600e6dfabd94b577.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
3、编写测试脚本 push.js，内容如下：

```
var apn = require('apn');

if (process.argv.length == 3) {
	// Enter the device token
	var deviceToken = process.argv[2];

	// Set up apn with the APNs Auth Key
	var apnProvider = new apn.Provider({  
	     token: {
	        key: 'xxxx.p8', // Path to the key p8 file
	        keyId: 'xxxx',
	        teamId: 'xxxx',
	    },
	    production: false // Set to true if sending a notification to a production iOS app
	});

	// Prepare a new notification
	var notification = new apn.Notification();

	// Specify your iOS app's Bundle ID (accessible within the project editor)
	notification.topic = 'com.domain.xxxx';

	// Set expiration to 1 hour from now (in case device is offline)
	notification.expiry = Math.floor(Date.now() / 1000) + 3600;

	// Set app badge indicator
	notification.badge = 1;

	// Play ping.aiff sound when the notification is received
	notification.sound = 'default';

	// Display the following message (the actual notification text, supports emoji)
	notification.alert = 'Hello World \u270C';

	// Send any extra payload data with the notification which will be accessible to your app in didReceiveRemoteNotification
	notification.payload = {id: 123};

	// Actually send the notification
	apnProvider.send(notification, deviceToken).then(function(result) {  
	    // Check the result for any failed devices
	    console.log(result);
	});
} else {
	console.log("Usage: node push.js <deviceToken>");
}
```
至此就可以测试远程推送通知了。当然还可以其他类似的工具 [NWPusher](https://github.com/noodlewerk/NWPusher.git)
```
node push.js 8c6f8b7056613a5223c690fb171697c524173b9c39e7dff688c66f0b23fbefdb
```
#### 展示处理
iOS 10以前通知完全是系统行为，开发者无法自主控制，引入 UserNotifications 框架以后通知数据处理流程如下：
![Notification Extension.png](http://upload-images.jianshu.io/upload_images/1200910-1dba439f45a89cba.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
其中 Service Extension 和 Content Extension 前者可以让我们有机会在收到远程推送的通知后，展示之前对通知内容进行修改；后者可以用来自定义通知视图UI的样式。尤其是**Service Extension收到通知以后必执行**。
1、创建 Service Extension，Xcode 会自动生成模板代码。在这里可以进行埋点统计，并在通知中展示多媒体文件（图片/音频/视频）。

```
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    /**
     该方法可以在限定时间内（30秒）修改请求中的 content 内容，然后返回给系统显示
     */
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // 进行 Push 到达的埋点统计
            var msgid = 1
            if let tmp = bestAttemptContent.userInfo["msgid"] as? NSNumber {
                msgid = tmp.intValue
            }
            tracePush(msgId: msgId)

            /** 
                添加多媒体附件
                内置资源支持10MB以内图片，50M以内音视频
                外链支持30秒内能下载完成的多媒体文件
             */ 
            if let imageURLString = bestAttemptContent.userInfo["image"] as? String, let URL = URL(string: imageURLString) {
                downloadAndSave(url: URL) { localURL in
                    if let localURL = localURL {
                       do {
                          let attachment = try UNNotificationAttachment(identifier: "image_downloaded", url: localURL, options: nil)
                          bestAttemptContent.attachments = [attachment]
                       } catch {
                          print(error)
                       }
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }

    /**
     一定时间内（30秒）没将内容返回给系统，则会自动调用该方法，未完成的修改将被忽略
     */
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```
2、创建 Content Extension，Xcode 会自动生成模板代码（若不需要自定义UI，可跳过本部分）。iOS 10中通知分类注册方式更加简洁，通知响应处理方式也集中到了独立的 delegate中，包括本地和远程通知的处理。

```
func registerNotificationCategory() {
    if #available(iOS 10.0, *) {
       UNUserNotificationCenter.current().setNotificationCategories(createiOS10Category())
       UNUserNotificationCenter.current().delegate = notificationHandler
    } else {
       let types: UIUserNotificationType = [.alert, .sound, .badge]
       let settings = UIUserNotificationSettings(types: types, categories: createiOS89Category())
       UIApplication.shared.registerUserNotificationSettings(settings)
    }
}

// 当 application 处于前台活跃状态时会被调用，控制是否需要弹出提示
func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
}

// 当用户点击通知启动 application，前台活跃状态点击通知时都会被调用到
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
}
```
Content Extension 也可以在 application 未启动前，处理已注册过的通知分类

```
// 用户每收到一条通知都会执行一次调用
func didReceive(_ notification: UNNotification)  {

}

// 用户点击通知时会调用
func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Swift.Void) {

}
```
3、编辑推送信息，简单的示例 payload 如下：

```
{
  "msgid": 100,
  "aps":{
    "alert":{
      "title":"Image Notification",
      "body":"Show me an image from web!"
    },
    "mutable-content":1
  },
  "image": "https://onevcat.com/assets/images/background-cover.jpg"
}
```
详细定义参见 [苹果官方文档](https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)。
4、Service Extension 和 Content Extension 都有独立的 Bundle ID，打包时需要进行签名，同时也需要配置 ATS
![ATS.png](http://upload-images.jianshu.io/upload_images/1200910-d2fe026b65a08c73.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

注意事项：
> 1、**mutable-content** 表示接收到通知时会对内容进行修改，必须配置为1，否则不会执行 Service Extension
> 
> 2、附件可以设置多个 attachment 实例，但系统默认只会显示第一个，当然可以通告代码修改它们的顺序，以显示最符合情景的图片或者视频。
> 
> 3、extension 的 bundle 和 app main bundle 并不相同，属于不同的沙盒目录，也就是说当要使用内置资源时需添加进 extension 的 bundle 中，
> 
> 4、如果使用的图片和视频文件不在 bundle 内部，它们将被移动到系统的负责通知的文件夹下，然后在当通知被移除后删除。如果媒体文件在 bundle 内部，它们将被复制到通知文件夹下。每个应用能使用的媒体文件的文件大小总和是有限制，超过限制后创建 attachment 时将抛出异常，即不能同时创建太多的 attachment
> 
> 5、当访问一个已经创建好的 attachment 时，需使用```startAccessingSecurityScopedResource ```来获取访问权限：
> 
```
let content = notification.request.content
if let attachment = content.attachments.first {  
    if attachment.url.startAccessingSecurityScopedResource() {  
       eventImage.image = UIImage(contentsOfFile: attachment.url.path!)
      attachment.url.stopAccessingSecurityScopedResource()  
    }  
}  
```

关于 Service Extension、Content Extension 和多媒体通知的使用，可以参考 [Demo](https://github.com/zhangyinglong/RemotePushDemo.git)。