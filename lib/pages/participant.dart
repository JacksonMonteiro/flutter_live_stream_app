// ignore_for_file: prefer_const_constructors, unused_field

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';

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
  List<int> _users = [];
  late RtcEngine _engine;
  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;

  @override
  void initState() {
    super.initState();
    initializeAgora();
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
        _users.add(uid);
      });
    }));

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
      print('Mensagem pública de ' + member.userId + ': ' + (message.text));
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Participante'),
      ),
    );
  }
}
