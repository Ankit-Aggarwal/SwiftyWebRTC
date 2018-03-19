//
//  RTCCapturer.swift
//
//  Created by Ankit Aggarwal on 19/02/18.
//  Copyright © 2018 Ankit Aggarwal. All rights reserved.
//

import Foundation
import WebRTC

public class RTCCapturer: NSObject {

    private var capturer: RTCCameraVideoCapturer
    private var settingsModel: RTCCapturerSettingsModel
    private var usingFrontCamera = true

    public init(withCapturer capturer: RTCCameraVideoCapturer, settingsModel : RTCCapturerSettingsModel) {
        self.capturer = capturer
        self.settingsModel = settingsModel
        super.init()
    }

    public func startCapture() {
        let position = self.usingFrontCamera ? AVCaptureDevice.Position.front : AVCaptureDevice.Position.back
        guard let device = self.findDeviceForPosition(position: position) else { return }

        let format = self.selectFormatForDevice(device: device)
        let fps = self.selectFpsForFormat(format: format)
        self.capturer.startCapture(with: device, format: format, fps: fps)
    }

    public func stopCapture() {
        self.capturer.stopCapture()
    }

    public func switchCamera() {
        self.usingFrontCamera = !self.usingFrontCamera
        self.startCapture()
    }
}

private extension RTCCapturer {
    func findDeviceForPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let captureDevices = RTCCameraVideoCapturer.captureDevices()
        for device in captureDevices {
            if device.position == position {
                return device
            }
        }
        return captureDevices.first
    }

    func selectFpsForFormat(format: AVCaptureDevice.Format) -> Int {
        var maxFramerate: Float64 = 0

        for fpsRange in format.videoSupportedFrameRateRanges {
            maxFramerate = fmax(maxFramerate, fpsRange.maxFrameRate)
        }

        return Int(maxFramerate)
    }

    func selectFormatForDevice(device: AVCaptureDevice) -> AVCaptureDevice.Format {
        let supportedFormats = RTCCameraVideoCapturer.supportedFormats(for: device)
        let targetWidth = self.settingsModel.currentVideoResolutionWidthFromStore
        let targetHeight = self.settingsModel.currentVideoResolutionHeightFromStore

        var selectedFormat: AVCaptureDevice.Format? = nil
        var currentDiff = INT_MAX

        for format in supportedFormats {
            let dimension: CMVideoDimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let diff = abs(targetWidth - Int(dimension.width)) + abs(targetHeight - Int(dimension.height));
            if diff < currentDiff {
                selectedFormat = format
                currentDiff = Int32(diff)
            }
        }
        return selectedFormat!
    }
}
