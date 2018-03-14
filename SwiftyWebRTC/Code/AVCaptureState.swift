//
//  AVCaptureState.swift
//  SwiftyWebRTC
//
//  Copyright © 2017 Ankit Aggarwal. All rights reserved.
//

import Foundation
import AVFoundation

class AVCaptureState {
    static var isVideoDisabled: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        return status == .restricted || status == .denied
    }

    static var isAudioDisabled: Bool {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        return status == .restricted || status == .denied
    }
}
