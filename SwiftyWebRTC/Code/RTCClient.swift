//
//  RTCClient.swift
//  SwiftyWebRTC
//
//  Copyright © 2017 Ankit Aggarwal. All rights reserved.
//

import Foundation
import WebRTC

public enum RTCClientState {
    case disconnected
    case connecting
    case connected
}

public protocol RTCClientDelegate: class {
    func rtcClient(client : RTCClient, startCallWithSdp sdp: String)
    func rtcClient(client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack)
    func rtcClient(client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack)
    func rtcClient(client : RTCClient, didReceiveError error: Error)
    func rtcClient(client : RTCClient, didChangeConnectionState connectionState: RTCIceConnectionState)
    func rtcClient(client : RTCClient, didChangeState state: RTCClientState)
    func rtcClient(client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate)
    func rtcClient(client : RTCClient, didCreateLocalCapturer capturer: RTCCameraVideoCapturer)
}

public extension RTCClientDelegate {
    // add default implementation to extension for optional methods
    func rtcClient(client : RTCClient, didReceiveError error: Error) {

    }

    func rtcClient(client : RTCClient, didChangeConnectionState connectionState: RTCIceConnectionState) {

    }

    func rtcClient(client : RTCClient, didChangeState state: RTCClientState) {

    }
}

public class RTCClient: NSObject {
    fileprivate var iceServers: [RTCIceServer] = []
    fileprivate var peerConnection: RTCPeerConnection?
    fileprivate var connectionFactory: RTCPeerConnectionFactory = RTCPeerConnectionFactory()
    fileprivate var remoteIceCandidates: [RTCIceCandidate] = []
    fileprivate var isVideoCall = true

    public weak var delegate: RTCClientDelegate?

    fileprivate let audioCallConstraint = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio" : "true"],
                                                         optionalConstraints: nil)
    fileprivate let videoCallConstraint = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio" : "true", "OfferToReceiveVideo": "true"],
                                                                     optionalConstraints: nil)
    var callConstraint : RTCMediaConstraints {
        return self.isVideoCall ? self.videoCallConstraint : self.audioCallConstraint
    }

    fileprivate let defaultConnectionConstraint = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])

    fileprivate var mediaConstraint: RTCMediaConstraints {
        let constraints = ["minWidth": "0", "minHeight": "0", "maxWidth" : "480", "maxHeight": "640"]
        return RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: nil)
    }

    private var state: RTCClientState = .connecting {
        didSet {
            self.delegate?.rtcClient(client: self, didChangeState: state)
        }
    }
    
    public override init() {
        super.init()
    }

    public convenience init(iceServers: [RTCIceServer], videoCall: Bool = true) {
        self.init()
        self.iceServers = iceServers
        self.isVideoCall = videoCall
        self.configure()
    }

    deinit {
        guard let peerConnection = self.peerConnection else {
            return
        }
        if let stream = peerConnection.localStreams.first {
            peerConnection.remove(stream)
        }
    }

    public func configure() {
        initialisePeerConnectionFactory()
        initialisePeerConnection()
    }

    public func startConnection() {
        guard let peerConnection = self.peerConnection else {
            return
        }
        self.state = .connecting
        let localStream = self.localStream()
        peerConnection.add(localStream)
        if let localVideoTrack = localStream.videoTracks.first {
            self.delegate?.rtcClient(client: self, didReceiveLocalVideoTrack: localVideoTrack)
        }
    }

    public func disconnect() {
        guard let peerConnection = self.peerConnection else {
            return
        }
        peerConnection.close()
        if let stream = peerConnection.localStreams.first {
            peerConnection.remove(stream)
        }
        self.delegate?.rtcClient(client: self, didChangeState: .disconnected)

        initialisePeerConnection()
    }

    public func makeOffer() {
        guard let peerConnection = self.peerConnection else {
            return
        }

        peerConnection.offer(for: self.callConstraint, completionHandler: { [weak self]  (sdp, error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(client: this, didReceiveError: error)
            } else {
                this.handleSdpGenerated(sdpDescription: sdp)
            }
        })
    }

    public func handleAnswerReceived(withRemoteSDP remoteSdp: String?) {
        guard let remoteSdp = remoteSdp else {
            return
        }

        // Add remote description
        let sessionDescription = RTCSessionDescription.init(type: .answer, sdp: remoteSdp)
        self.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(client: this, didReceiveError: error)
            } else {
                this.handleRemoteDescriptionSet()
                this.state = .connected
            }
        })
    }

    public func createAnswerForOfferReceived(withRemoteSDP remoteSdp: String?) {
        guard let remoteSdp = remoteSdp,
            let peerConnection = self.peerConnection else {
                return
        }

        // Add remote description
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: remoteSdp)
        self.peerConnection?.setRemoteDescription(sessionDescription, completionHandler: { [weak self] (error) in
            guard let this = self else { return }
            if let error = error {
                this.delegate?.rtcClient(client: this, didReceiveError: error)
            } else {
                this.handleRemoteDescriptionSet()
                // create answer
                peerConnection.answer(for: this.callConstraint, completionHandler:
                    { (sdp, error) in
                        if let error = error {
                            this.delegate?.rtcClient(client: this, didReceiveError: error)
                        } else {
                            this.handleSdpGenerated(sdpDescription: sdp)
                            this.state = .connected
                        }
                })
            }
        })
    }

    public func addIceCandidate(iceCandidate: RTCIceCandidate) {
        // Set ice candidate after setting remote description
        if self.peerConnection?.remoteDescription != nil {
            self.peerConnection?.add(iceCandidate)
        } else {
            self.remoteIceCandidates.append(iceCandidate)
        }
    }
}

public struct ErrorDomain {
    public static let videoPermissionDenied = "Video permission denied"
    public static let audioPermissionDenied = "Audio permission denied"
}

private extension RTCClient {
    func handleRemoteDescriptionSet() {
        for iceCandidate in self.remoteIceCandidates {
            self.peerConnection?.add(iceCandidate)
        }
        self.remoteIceCandidates = []
    }

    // Generate local stream and keep it live and add to new peer connection
    func localStream() -> RTCMediaStream {
        let factory = self.connectionFactory
        let localStream = factory.mediaStream(withStreamId: "RTCmS")

        if self.isVideoCall {
            if !AVCaptureState.isVideoDisabled {
                let videoSource: RTCVideoSource = factory.videoSource()
                let capturer = RTCCameraVideoCapturer(delegate: videoSource)
                self.delegate?.rtcClient(client: self, didCreateLocalCapturer: capturer)
                let videoTrack = factory.videoTrack(with: videoSource, trackId: "RTCvS0")
                videoTrack.isEnabled = true
                localStream.addVideoTrack(videoTrack)
            } else {
                // show alert for video permission disabled
                let error = NSError.init(domain: ErrorDomain.videoPermissionDenied, code: 0, userInfo: nil)
                self.delegate?.rtcClient(client: self, didReceiveError: error)
            }
        }

        if !AVCaptureState.isAudioDisabled {
            let audioTrack = factory.audioTrack(withTrackId: "RTCaS0")
            localStream.addAudioTrack(audioTrack)
        } else {
            // show alert for audio permission disabled
            let error = NSError.init(domain: ErrorDomain.audioPermissionDenied, code: 0, userInfo: nil)
            self.delegate?.rtcClient(client: self, didReceiveError: error)
        }
        return localStream
    }

    func initialisePeerConnectionFactory () {
        RTCPeerConnectionFactory.initialize()
        self.connectionFactory = RTCPeerConnectionFactory()
    }

    func initialisePeerConnection () {
        let configuration = RTCConfiguration()
        configuration.iceServers = self.iceServers
        self.peerConnection = self.connectionFactory.peerConnection(with: configuration,
                                                                    constraints: self.defaultConnectionConstraint,
                                                                    delegate: self)
    }

    func handleSdpGenerated(sdpDescription: RTCSessionDescription?) {
        guard let sdpDescription = sdpDescription  else {
            return
        }
        // set local description
        self.peerConnection?.setLocalDescription(sdpDescription, completionHandler: {[weak self] (error) in
            // issue in setting local description
            guard let this = self, let error = error else { return }
            this.delegate?.rtcClient(client: this, didReceiveError: error)
        })
        //  Signal to server to pass this sdp with for the session call
        self.delegate?.rtcClient(client: self, startCallWithSdp: sdpDescription.sdp)
    }
}

extension RTCClient: RTCPeerConnectionDelegate {

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if stream.videoTracks.count > 0 {
            self.delegate?.rtcClient(client: self, didReceiveRemoteVideoTrack: stream.videoTracks[0])
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {

    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        self.delegate?.rtcClient(client: self, didChangeConnectionState: newState)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.rtcClient(client: self, didGenerateIceCandidate: candidate)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        
    }
}
