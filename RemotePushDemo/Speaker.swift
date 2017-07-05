//
//  Speaker.swift
//  RemotePushDemo
//
//  Created by zhang yinglong on 2017/7/5.
//  Copyright © 2017年 zhang yinglong. All rights reserved.
//

import AVFoundation

class Speaker: NSObject {
    
    fileprivate lazy var speecher: AVSpeechSynthesizer = {
        let speecher = AVSpeechSynthesizer()
        speecher.delegate = self
        return speecher
    }()
    
    public func speak(content: String) {
        shutup()
        
        let speechUtterance = AVSpeechUtterance(string: content)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        if let language = NSLocale.preferredLanguages.first {
            speechUtterance.voice = AVSpeechSynthesisVoice(language: language)
        }
        speecher.speak(speechUtterance)
    }
    
    public func shutup() {
        if speecher.isSpeaking {
            speecher.stopSpeaking(at: .immediate)
        }
    }

}

extension Speaker: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        // 开始播放
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // 播放结束
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // 暂停播放
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // 继续播放
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // 取消播放
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance){
        // 将要读的字符串长度
    }

}
