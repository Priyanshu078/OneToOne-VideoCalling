import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:permission_handler/permission_handler.dart';
import 'package:video_calling/homePage.dart';
import 'package:video_calling/utils/appId.dart';

class MyVideoCall extends StatefulWidget {
  final String channelName;
  MyVideoCall({Key key, @required this.channelName}) : super(key: key);

  @override
  _MyVideoCallState createState() => _MyVideoCallState();
}

class _MyVideoCallState extends State<MyVideoCall> {
  int _remoteUid;
  RtcEngine _engine;
  bool muted = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    // to destroy the engine
    _engine.destroy();
    // to leave the channel
    _engine.leaveChannel();
    super.dispose();
  }

  Future<void> handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }

  Future<void> initialize() async {
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.joinChannel(tokenforVideoCall, widget.channelName, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appID);
    await _engine.enableVideo();
  }

  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        final info = 'onError: $code';
        showSnackBar(info);
        print(info);
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        final info =
            'onJoinChannel: $channel, uid: $uid, timeElapsed: $elapsed';
        showSnackBar(info);
        print(info);
      },
      leaveChannel: (stats) {
        final info = 'stats: $stats';
        showSnackBar(info);
        print(info);
      },
      userJoined: (uid, elapsed) {
        setState(() {
          _remoteUid = uid;
        });
        final info = 'Uid: $uid, timeElapsed: $elapsed';
        showSnackBar(info);
        print(info);
      },
      userOffline: (uid, reason) {
        setState(() {
          _remoteUid = null;
        });
        final info = 'Uid: $uid, reason: $reason';
        showSnackBar(info);
        print(info);
      },
    ));
  }

  void showSnackBar(String text){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Agora Video Call"),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              child: getRemoteView(),
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: getLocalView(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: toolbar(),
          ),
        ],
      ),
    );
  }

  Widget getRemoteView() {
    if (_remoteUid != null) {
      return Container(
        child: RtcRemoteView.SurfaceView(
          uid: _remoteUid,
        ),
      );
    } else {
      return Center(child: Text("Loading the remote preview...."));
    }
  }

  Widget getLocalView() {
    return Container(
      height: MediaQuery.of(context).size.height / 4,
      width: MediaQuery.of(context).size.width / 3,
      child: Center(
        child: RtcLocalView.SurfaceView(),
      ),
    );
  }

  Widget toolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            padding: EdgeInsets.all(12),
            child: Icon(
              muted ? Icons.mic_off : Icons.mic,
              color: muted ? Colors.white : Colors.blueAccent,
              size: 20,
            ),
            shape: CircleBorder(),
            onPressed: onToggleMute,
            elevation: 2.0,
            fillColor: muted ? Colors.blueAccent : Colors.white,
          ),
          RawMaterialButton(
            padding: EdgeInsets.all(15),
            shape: CircleBorder(),
            elevation: 2.0,
            onPressed: () => onCallEnd(context),
            fillColor: Colors.redAccent,
            child: Icon(
              Icons.call_end,
              size: 35,
              color: Colors.white,
            ),
          ),
          RawMaterialButton(
            padding: EdgeInsets.all(12),
            shape: CircleBorder(),
            elevation: 2.0,
            onPressed: onSwitchCamera,
            fillColor: Colors.white,
            child: Icon(
              Icons.switch_camera,
              size: 20,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  void onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void onCallEnd(context) {
    Navigator.pop(context);
  }

  void onSwitchCamera() {
    _engine.switchCamera();
  }
}
