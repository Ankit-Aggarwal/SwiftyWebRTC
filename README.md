# SwiftyWebRTC

As the name suggests, this is an framework for iOS implementation of the Google WebRTC framework, it contains build in WebRTC.Framework and RTCClient (written in swift) to let you easily add video/audio call capability to your app.

## About

This Framework provides you with a resuable wrapper written in swift (swift3) for comfortable and easy using of Google WebRTC framework and making your ios app video call enabled.
WebRTC is an open-source project (libjingle_peerConnection) maintained by google with high-level API implementations for both iOS and Android. 
WebRTC api can be read from [here](https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API).
WebRTC Framework used in project has been build from [here](https://webrtc.org/native-code/ios/)

If you want to know about the wrapper implementation that can be checked from my blog in [here](https://medium.com/@aren.ankit/swiftywebrtc-789936b0e39b#.mgcrsvjkw) 
## Source
### Carthage

Framework can be added using following to your cartfile
```
github "Ankit-Aggarwal/SwiftyWebRTC" 
```

## Usage:
Integration RTCClient to your controller is easy.

1. Configure Client:
```
    func configureVideoClient() {
    // You can pass on iceServers your app wanna use 
    // RTCClient can be used for only audio call also where videoCall is by default
        let client = RTCClient(iceServers: iceServers, videoCall: true)
        client.delegate = self
        self.videoClient = client
        client.startConnection()
    }
```
2. Your controller needs to conform to RTCClientDelegate, which will help your client to interact with server for passing info
```
extension VideoChatViewController: RTCClientDelegate {
    func rtcClient(client : RTCClient, didReceiveError error: Error) {
        // Error Received
        }
    }

    func rtcClient(client : RTCClient, didGenerateIceCandidate iceCandidate: RTCIceCandidate) {
     // iceCandidate generated, pass this to other user using any signal method your app uses
    }

    func rtcClient(client : RTCClient, startCallWithSdp sdp: String) {
       // SDP generated, pass this to other user using any signal method your app uses
    }

    func rtcClient(client : RTCClient, didReceiveLocalVideoTrack localVideoTrack: RTCVideoTrack) {
    // Use localVideoTrack generated for rendering stream to remoteVideoView
        localVideoTrack.add(self.localVideoView)
        self.localVideoTrack = localVideoTrack
    }
    func rtcClient(client : RTCClient, didReceiveRemoteVideoTrack remoteVideoTrack: RTCVideoTrack) {
    // Use remoteVideoTrack generated for rendering stream to remoteVideoView
        remoteVideoTrack.add(self.remoteVideoView)
        self.remoteVideoTrack = remoteVideoTrack
    }
}
```

This is all you need to let the data flowing :)

# Contributing

If you'd like to contribute, please fork the repository and issue pull requests. If you have any special requests and want to collaborate, please contact me directly. Thanks!

May add a example project in the repo, depending on the requests i get...
