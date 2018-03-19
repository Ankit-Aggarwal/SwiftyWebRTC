//
//  RTCCapturerSettingsModel.swift
//
//  Created by Ankit Aggarwal on 19/02/18.
//  Copyright © 2018 Ankit Aggarwal. All rights reserved.
//

import Foundation

/**
 * Model class for user defined settings.
 *
 * Handles storing the settings and provides default values if setting is not
 * set. Also provides list of available options for different settings. Stores
 * for example video codec, video resolution and maximum bitrate.
 */

public class RTCCapturerSettingsModel: NSObject {

    struct SettingsConstants {
        static let videoResolutionsStaticValues = [ "640x480", "960x540", "1280x720" ]
        static let videoCodecsStaticValues = [ "H264", "VP8", "VP9" ]
    }

    private lazy var settingsStore: RTCSettingsStore = {
        return RTCSettingsStore.init()
    }()

    private var defaultVideoResolutionSetting: String {
        return SettingsConstants.videoResolutionsStaticValues[0]
    }

    private var defaultVideoCodecSetting: String {
        return SettingsConstants.videoCodecsStaticValues[0]
    }

    /**
     * Returns array of available capture resoultions.
     *
     * The capture resolutions are represented as strings in the following format
     * [width]x[height]
     */
    private var availableVideoResolutions: [String] {
        return SettingsConstants.videoResolutionsStaticValues
    }

    /**
     * Returns array of available video codecs.
     */
    private var availableVideoCodecs: [String] {
        return SettingsConstants.videoCodecsStaticValues
    }

    var currentVideoResolutionWidthFromStore: Int {
        let resolution = self.currentVideoResolutionSettingFromStore
        return self.videoResolutionComponentAtIndex(0, inString: resolution)
    }

    var currentVideoResolutionHeightFromStore: Int {
        let resolution = self.currentVideoResolutionSettingFromStore
        return self.videoResolutionComponentAtIndex(1, inString: resolution)
    }

    var maxBitrate: NSNumber? {
        get {
            return self.settingsStore.maxBitrate
        }

        set {
            self.settingsStore.maxBitrate = newValue
        }
    }

    /**
     * Stores the provided video resolution string into the store.
     *
     * If the provided resolution is no part of the available video resolutions
     * the store operation will not be executed and NO will be returned.
     * @param resolution the string to be stored.
     * @return YES/NO depending on success.
     */

    func storeVideoResolutionSetting(resolution: String) -> Bool {
        if !self.availableVideoResolutions.contains(resolution) {
            return false
        }
        self.settingsStore.videoResolution = resolution
        return true
    }

    /**
     * Returns current video resolution string.
     * If no resolution is in store, default value of 640x480 is returned.
     * When defaulting to value, the default is saved in store for consistency reasons.
     */

    var currentVideoResolutionSettingFromStore: String {
        if let resolution = self.settingsStore.videoResolution {
            return resolution
        } else {
            let resolution = self.defaultVideoResolutionSetting
            // To ensure consistency add the default to the store.
            self.settingsStore.videoResolution = resolution
            return resolution
        }
    }


    /**
     * Stores the provided video codec setting into the store.
     *
     * If the provided video codec is not part of the available video codecs
     * the store operation will not be executed and NO will be returned.
     * @param video codec settings the string to be stored.
     * @return YES/NO depending on success.
     */
    func storeVideoCodecSetting(videoCodec : String) -> Bool {
        if !self.availableVideoCodecs.contains(videoCodec) {
            return false
        }
        self.settingsStore.videoCodec = videoCodec
        return true
    }

    /**
     * Returns current video codec setting from store if present.
     */
    func currentVideoCodecSettingFromStore() -> String {
        if let videoCodec = self.settingsStore.videoCodec {
            return videoCodec
        } else {
            let videoCodec = self.defaultVideoCodecSetting
            // To ensure consistency add the default to the store.
            self.settingsStore.videoCodec = videoCodec
            return videoCodec
        }
    }
}


private extension RTCCapturerSettingsModel {
    func videoResolutionComponentAtIndex(_ index: Int,
                                                 inString resolution: String) -> Int {
        guard index == 0 || index == 1 else {
            return 0
        }
        // Resolution saved in format WidthxHeight
        let components = resolution.components(separatedBy: "x")
        if components.count != 2 {
            return 0
        }
        return Int(components[index]) ?? 0
    }
}
