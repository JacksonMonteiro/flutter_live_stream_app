// ignore_for_file: prefer_const_constructors, unused_field, avoid_print, library_prefixes, unused_import

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:live_stream_app/models/user.dart';
import 'package:live_stream_app/utils/message.dart';
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
  List<AgoraUser> _users = [];
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;
  bool muted = false;
  bool videoDisabled = false;
  bool localUserActive = false;

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
            _engine.muteLocalAudioStream(true);
          }
          break;
        case "unmute":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              muted = false;
            });
            _engine.muteLocalAudioStream(false);
          }
          break;
        case "disable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              videoDisabled = true;
            });
            _engine.muteLocalVideoStream(true);
          }
          break;
        case "enable":
          if (parsedMessage[1] == widget.uid.toString()) {
            setState(() {
              videoDisabled = false;
            });
            _engine.muteLocalVideoStream(false);
          }
          break;
        case "activeUsers":
          setState(() {
            _users = Message().parseActiveUsers(uids: parsedMessage[1]);
          });
          break;
        default:
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
        children: <Widget>[
          localUserActive
              ? RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(muted ? Icons.mic_off : Icons.mic,
                      color: muted ? Colors.white : Colors.blueAccent,
                      size: 20),
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: muted ? Colors.blueAccent : Colors.white,
                  padding: EdgeInsets.all(12),
                )
              : SizedBox(),
          RawMaterialButton(
            onPressed: () => _onCallEnd(context),
            child: Icon(Icons.call_end, color: Colors.white, size: 20),
            shape: CircleBorder(),
            elevation: 2,
            fillColor: Colors.redAccent,
            padding: EdgeInsets.all(15),
          ),
          localUserActive
              ? RawMaterialButton(
                  onPressed: _onToggleVideoDisabled,
                  child: Icon(
                      videoDisabled ? Icons.videocam_off : Icons.videocam,
                      color: videoDisabled ? Colors.white : Colors.blueAccent,
                      size: 20),
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: videoDisabled ? Colors.blueAccent : Colors.white,
                  padding: EdgeInsets.all(12),
                )
              : SizedBox(),
          localUserActive
              ? RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  child: Icon(Icons.switch_camera,
                      color: Colors.blueAccent, size: 20),
                  shape: CircleBorder(),
                  elevation: 2,
                  fillColor: Colors.white,
                  padding: EdgeInsets.all(12),
                )
              : SizedBox(),
        ],
      ),
    );
  }

  List<Widget> _getRenderViews() {
    final List<Widget> list = [];
    bool checkIfLocalActive = false;
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].uid == widget.uid) {
        list.add(Stack(
          children: [
            RtcLocalView.SurfaceView(),
            Align(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Text(widget.userName),
              ),
              alignment: Alignment.bottomRight,
            ),
          ],
        ));
        checkIfLocalActive = true;
      } else {
        list.add(Stack(
          children: [
            RtcRemoteView.SurfaceView(
              channelId: 'gfx',
              uid: _users[i].uid,
            ),
            Align(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
                  color: Colors.white,
                ),
                child: Text(_users[i].name ?? "Erro ao mostrar nome"),
              ),
              alignment: Alignment.bottomRight,
            )
          ],
        ));
      }
    }

    if (checkIfLocalActive) {
      localUserActive = true;
    } else {
      localUserActive = false;
    }

    return list;
  }

  Widget _expandedVideoView(List<Widget> views) {
    final wrappedViews = views
        .map<Widget>((view) => Expanded(child: Container(child: view)))
        .toList();

    return Expanded(
        child: Row(
      children: wrappedViews,
    ));
  }

  Widget _broadcastView() {
    final views = _getRenderViews();

    switch (views.length) {
      case 1:
        return Column(
          children: <Widget>[
            _expandedVideoView([views[0]]),
          ],
        );
      case 2:
        return Column(children: <Widget>[
          _expandedVideoView([views[0]]),
          _expandedVideoView([views[1]]),
        ]);
      case 3:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: <Widget>[
            _expandedVideoView(views.sublist(0, 2)),
            _expandedVideoView(views.sublist(2, 4))
          ],
        );
      default:
    }

    return Container();
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
