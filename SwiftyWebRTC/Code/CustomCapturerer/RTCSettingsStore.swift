//
//  RTCSettingsStore.swift
//
//  Created by Ankit Aggarwal on 16/02/18.
//  Copyright © 2018 Ankit Aggarwal. All rights reserved.
//

import Foundation

class RTCSettingsStore: NSObject {

    struct StorageConstantKeys {
        static let videoResolutionKey = "rtc_video_resolution_key"
        static let videoCodecKey = "rtc_video_codec_key"
        static let bitrateKey = "rtc_max_bitrate_key"
    }

    /**
     * Light-weight persistent store for user settings.
     * It will persist between application launches and application updates.
     */
    
    private lazy var storage = UserDefaults.standard

    var videoResolution: String? {
        get {
            return self.storage.object(forKey: StorageConstantKeys.videoResolutionKey) as? String
        }
        set {
            self.storage.set(newValue, forKey: StorageConstantKeys.videoResolutionKey)
            self.storage.synchronize()
        }
    }

    var videoCodec: String? {
        get {
            return self.storage.object(forKey: StorageConstantKeys.videoCodecKey) as? String
        }
        set {
            self.storage.set(newValue, forKey: StorageConstantKeys.videoCodecKey)
            self.storage.synchronize()
        }
    }

    var maxBitrate: NSNumber? {
        get {
            return self.storage.object(forKey: StorageConstantKeys.bitrateKey) as? NSNumber
        }
        set {
            self.storage.set(newValue, forKey: StorageConstantKeys.bitrateKey)
            self.storage.synchronize()
        }
    }
}

