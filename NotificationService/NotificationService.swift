//
//  NotificationService.swift
//  NotificationService
//
//  Created by zhang yinglong on 2017/7/3.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

import UIKit
import UserNotifications
import MobileCoreServices

// https://developer.apple.com/documentation/usernotifications/unnotificationattachment

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // 进行 Push 到达的埋点统计
            var msgid = 1
            if let tmp = bestAttemptContent.userInfo["msgid"] as? NSNumber {
                msgid = tmp.intValue
            }
            tracePush(msgId: msgid)
            
            /**
             添加多媒体附件
             内置资源支持10MB以内图片，50M以内音视频
             外链支持30秒内能下载完成的多媒体文件
             */
            if let imageURLString = bestAttemptContent.userInfo["image"] as? String, let URL = URL(string: imageURLString) {
                downloadAndSave(url: URL) { localURL, contentType in
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
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

extension NotificationService {
    
    fileprivate func tracePush(msgId: Int) {
        // 埋点上传
    }
    
    fileprivate func downloadAndSave(url: URL, handler: @escaping (_ localURL: URL?, _ contentType: String?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: {
            data, res, error in
            
            var localURL: URL? = nil
            if let data = data {
                let cache = NotificationService.cacheURL(url: url)
                if let _ = try? data.write(to: cache) {
                    localURL = cache
                }
            }
            handler(localURL, NotificationService.readTypeOfHeader(header: res as! HTTPURLResponse))
        })
        
        task.resume()
    }
    
    class func cacheURL(url: URL) -> URL {
        let ext = (url.absoluteString as NSString).pathExtension
        let cacheURL = URL(fileURLWithPath: FileManager.default.cachesDirectory)
        return cacheURL.appendingPathComponent(url.absoluteString.md5).appendingPathExtension(ext)
    }
    
    class func attachmentOption(url: URL) -> [String:Any]? {
        var contentType: CFString? = nil
        let type = url.pathExtension
        switch type.lowercased() {
        // audio
        case "aiff":
            contentType = kUTTypeAudioInterchangeFileFormat
        case "waveformaudio":
            contentType = kUTTypeWaveformAudio
        case "mp3":
            contentType = kUTTypeMP3
        case "mpeg4audio":
            contentType = kUTTypeMPEG4Audio
            
        // image
        case "jpeg", "jpg":
            contentType = kUTTypeJPEG
        case "gif":
            contentType = kUTTypeGIF
        case "png":
            contentType = kUTTypePNG
            
        // video
        case "mpeg":
            contentType = kUTTypeMPEG
        case "mpeg2":
            contentType = kUTTypeMPEG2Video
        case "mpeg4", "mp4":
            contentType = kUTTypeMPEG4
        case "avi":
            contentType = kUTTypeAVIMovie
        default:
            break
        }
        
        var options: [String:Any]? = nil
        if let contentType = contentType {
            options = [UNNotificationAttachmentOptionsTypeHintKey:contentType]
        }
        return options
    }
    
    class func readTypeOfHeader(header: HTTPURLResponse) -> String? {
        var key: CFString? = nil
        if let contentType = header.allHeaderFields["Content-Type"] as! String? {
            if let type = contentType.components(separatedBy: ";").first {
                switch type {
                case "video/mpeg":
                    key = kUTTypeMPEG
                case "video/mpeg2":
                    key = kUTTypeMPEG2Video
                case "video/mpeg4", "video/mp4":
                    key = kUTTypeMPEG4
                case "video/avi":
                    key = kUTTypeAVIMovie
                    
                case "audio/aiff":
                    key = kUTTypeAudioInterchangeFileFormat
                case "audio/waveform":
                    key = kUTTypeWaveformAudio
                case "audio/mp3", "audio/mpeg":
                    key = kUTTypeMP3
                case "audio/mpeg4":
                    key = kUTTypeMPEG4Audio
                    
                case "image/gif":
                    key = kUTTypeGIF
                case "image/png":
                    key = kUTTypePNG
                case "image/jpeg":
                    key = kUTTypeJPEG
                default:
                    break
                }
            }
        }
        
        var result: String? = nil
        if let key = key {
            result = key as String
        }
        return result
    }
    
}

extension FileManager {
    
    var cachesDirectory: String {
        var paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
    
}

extension String {
    
    var md5: String {
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CC_LONG(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        
        CC_MD5(str, strLen, result)
        
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        
        result.deallocate(capacity: digestLen)
        
        return hash as String
    }
    
}

