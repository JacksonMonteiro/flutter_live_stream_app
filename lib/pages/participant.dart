// ignore_for_file: prefer_const_constructors, unused_field, avoid_print, library_prefixes, unused_import

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:live_stream_app/models/user.dart';
import 'package:live_stream_app/utils/token.dart';

import '../utils/appId.dart';

class Participant extends StatefulWidget {
  final String channelName;
  final String userName;
  final int uid;

  const Participant(
      {Key? key,
      required this.channelName,
      required this.userName,
      required this.uid})
      : super(key: key);

  @override
  State<Participant> createState() => _ParticipantState();
}

class _ParticipantState extends State<Participant> {
  final List<AgoraUser> _users = [];
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;
  bool muted = false;
  bool videoDisabled = false;

  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    _channel?.leave();
    _client?.logout();
    _client?.destroy();
    super.dispose();
  }

  Future<void> initializeAgora() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _client = await AgoraRtmClient.createInstance(appId);

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);

    // Callbacks for the RTC engine
    _engine.setEventHandler(
      RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          _users.add(AgoraUser(uid: uid));
        });
      }, leaveChannel: (stats) {
        setState(() {
          _users.clear();
        });
      }),
    );

    // Callbacks for RTM Client
    _client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Mensagem privada de " + peerId + "; " + (message.text));
    };

    _client?.onConnectionStateChanged = (int state, int reason) {
      print('Estado dá conexão alterado: ' +
          state.toString() +
          ', Motivo: ' +
          reason.toString());
      if (state == 5) {
        _channel?.leave();
        _client?.logout();
        _client?.destroy();
        print('Desconectado');
      }
    };

    // Join the RTM  and RTC channels
    await _client?.login(null, widget.uid.toString());
    _channel = await _client?.createChannel(widget.channelName);
    await _channel?.join();
    await _engine.joinChannel(null, widget.channelName, null, widget.uid);

    // Callbacks for RTM Channel
    _channel?.onMemberJoined = (AgoraRtmMember member) {
      print('Membro conectado: ' +
          member.userId +
          ', Canal: ' +
          member.channelId);
    };

    _channel?.onMemberLeft = (AgoraRtmMember member) {
      print('Membro desconectou: ' +
          member.userId +
          ', Canal: ' +
          member.channelId);
    };

    _channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      List<String> parsedMessage = message.text.split(" ");
      switch (parsedMessage[0]) {
        case "mute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = true;
            });
          }
      }

      print('Mensagem pública de ' + member.userId + ': ' + (message.text));
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Center(
            child: Stack(
          children: [
            _broadcastView(),
            _toolbar(),
          ],
        )),
      ),
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: _onToggleMute,
            child: Icon(muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent, size: 20),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: muted ? Colors.blueAccent : Colors.white,
            padding: EdgeInsets.all(12),
          ),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(Icons.call_end, color: Colors.white, size: 20),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: Colors.redAccent,
            padding: EdgeInsets.all(15),
          ),
          RawMaterialButton(
            onPressed: _onToggleVideoDisabled,
            child: Icon(videoDisabled ? Icons.videocam_off : Icons.videocam,
                color: videoDisabled ? Colors.white : Colors.blueAccent,
                size: 20),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
            padding: EdgeInsets.all(12),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child:
                Icon(Icons.switch_camera, color: Colors.blueAccent, size: 20),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: Colors.white,
            padding: EdgeInsets.all(12),
          )
        ],
      ),
    );
  }

  Widget _broadcastView() {
    return Row(children: [
      Expanded(child: RtcLocalView.SurfaceView()),
    ]);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideoDisabled() {
    setState(() {
      videoDisabled = !videoDisabled;
    });
    _engine.muteLocalVideoStream(videoDisabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }
}
