import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_stream_app/models/director_model.dart';
import 'package:live_stream_app/models/user.dart';
import 'package:live_stream_app/utils/appId.dart';
import 'package:live_stream_app/utils/message.dart';

final directorController =
    StateNotifierProvider.autoDispose<DirectorController, DirectorModel>((ref) {
  return DirectorController(ref.read);
});

class DirectorController extends StateNotifier<DirectorModel> {
  final Reader read;

  DirectorController(this.read) : super(DirectorModel());

  Future<void> _initialize() async {
    RtcEngine _engine =
        await RtcEngine.createWithContext(RtcEngineContext(appId));
    AgoraRtmClient _client = await AgoraRtmClient.createInstance(appId);
    state = DirectorModel(engine: _engine, client: _client);
  }

  Future<void> joinCall({required String channelName, required int uid}) async {
    await _initialize();

    await state.engine?.enableVideo();
    await state.engine?.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await state.engine?.setClientRole(ClientRole.Broadcaster);

    // Callbacks for the RTC engine
    state.engine?.setEventHandler(
      RtcEngineEventHandler(
        joinChannelSuccess: (channel, uid, elapsed) {
          print('Diretor: $uid');
        },
        leaveChannel: (stats) {
          print('Saiu do canal');
        },
        userJoined: (uid, elapsed) {
          print('Usuário conectado: ' + uid.toString());
          addUserToLobby(uid: uid);
        },
        userOffline: (uid, reason) {
          removeUser(uid: uid);
        },
        remoteAudioStateChanged: (uid, state, reason, elapsed) {
          if (state == AudioRemoteState.Decoding) {
            updateUserAudio(uid: uid, muted: false);
          } else if (state == AudioRemoteState.Stopped) {
            updateUserAudio(uid: uid, muted: true);
          }
        },
        remoteVideoStateChanged: (uid, state, reason, elapsed) {
          if (state == VideoRemoteState.Decoding) {
            updateUserVideo(uid: uid, videoDisabled: false);
          } else if (state == VideoRemoteState.Stopped) {
            updateUserVideo(uid: uid, videoDisabled: true);
          }
        },
      ),
    );

    // Callbacks for RTM Client
    state.client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Mensagem privada de " + peerId + "; " + (message.text));
    };

    state.client?.onConnectionStateChanged = (int st, int reason) {
      print('Estado dá conexão alterado: ' +
          st.toString() +
          ', Motivo: ' +
          reason.toString());
      if (st == 5) {
        state.channel?.leave();
        state.client?.logout();
        state.client?.destroy();
        print('Desconectado');
      }
    };

    // Join the RTM  and RTC channels
    await state.client?.login(null, uid.toString());
    state =
        state.copyWith(channel: await state.client?.createChannel(channelName));
    await state.channel?.join();
    await state.engine?.joinChannel(null, channelName, null, uid);

    // Callbacks for RTM Channel
    state.channel?.onMemberJoined = (AgoraRtmMember member) {
      print('Membro conectado: ' +
          member.userId +
          ', Canal: ' +
          member.channelId);
    };

    state.channel?.onMemberLeft = (AgoraRtmMember member) {
      print('Membro desconectou: ' +
          member.userId +
          ', Canal: ' +
          member.channelId);
    };

    state.channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print('Mensagem pública de ' + member.userId + ': ' + (message.text));
    };
  }

  Future<void> leaveCall() async {
    state.engine?.leaveChannel();
    state.engine?.destroy();
    state.channel?.leave();
    state.client?.logout();
    state.client?.destroy();
  }

  Future<void> addUserToLobby({required int uid}) async {
    state = state.copyWith(lobbyUsers: {
      ...state.lobbyUsers,

      AgoraUser(
          uid: uid,
          muted: true,
          videoDisabled: true,
          name: 'todo',
          backgroundColor: Colors.blue)
    });

    state.channel!.sendMessage(AgoraRtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers)));
  }

  Future<void> removeUser({required int uid}) async {
    Set<AgoraUser> _tempActive = state.activeUsers;
    Set<AgoraUser> _tempLobby = state.lobbyUsers;

    for (int i = 0; i < _tempActive.length; i++) {
      if (_tempActive.elementAt(i).uid == uid) {
        _tempActive.remove(_tempActive.elementAt(i));
      }
    }

    for (int i = 0; i < _tempLobby.length; i++) {
      if (_tempLobby.elementAt(i).uid == uid) {
        _tempLobby.remove(_tempLobby.elementAt(i));
      }
    }

    state = state.copyWith(activeUsers: _tempActive, lobbyUsers: _tempLobby);
    state.channel!.sendMessage(AgoraRtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers)));
  }

  Future<void> promoteToActiveUser({required int uid}) async {
    Set<AgoraUser> _tempLobby = state.lobbyUsers;
    Color? tempColor;
    String? tempName;

    for (int i = 0; i < _tempLobby.length; i++) {
      if (_tempLobby.elementAt(i).uid == uid) {
        tempColor = _tempLobby.elementAt(i).backgroundColor;
        tempName = _tempLobby.elementAt(i).name;
        _tempLobby.remove(_tempLobby.elementAt(i));
      }
    }

    state = state.copyWith(activeUsers: {
      ...state.activeUsers,
      AgoraUser(uid: uid, backgroundColor: tempColor, name: tempName)
    }, lobbyUsers: _tempLobby);

    state.channel!.sendMessage(AgoraRtmMessage.fromText("unmute $uid"));
    state.channel!.sendMessage(AgoraRtmMessage.fromText("enable $uid"));
    state.channel!.sendMessage(AgoraRtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers)));
  }

  Future<void> demoteToLobbyUser({required int uid}) async {
    Set<AgoraUser> _tempActive = state.activeUsers;
    Color? tempColor;
    String? tempName;
 
    for (int i = 0; i < _tempActive.length; i++) {
      if (_tempActive.elementAt(i).uid == uid) {
        tempColor = _tempActive.elementAt(i).backgroundColor;
        tempName = _tempActive.elementAt(i).name;
        _tempActive.remove(_tempActive.elementAt(i));
      }
    }

    state = state.copyWith(lobbyUsers: {
      ...state.lobbyUsers,
      AgoraUser(
          uid: uid,
          backgroundColor: tempColor,
          name: tempName,
          videoDisabled: true,
          muted: true,)
    }, activeUsers: _tempActive);

    state.channel!.sendMessage(AgoraRtmMessage.fromText("mute $uid"));
    state.channel!.sendMessage(AgoraRtmMessage.fromText("disable $uid"));
    state.channel!.sendMessage(AgoraRtmMessage.fromText(
        Message().sendActiveUsers(activeUsers: state.activeUsers)));
  }

  Future<void> updateUserAudio({required int uid, required bool muted}) async {
    AgoraUser _tempUser =
        state.activeUsers.singleWhere((element) => element.uid == uid);
    Set<AgoraUser> _tempSet = state.activeUsers;
    _tempSet.remove(_tempUser);
    _tempSet.add(_tempUser.copyWith(muted: muted));
  }

  Future<void> updateUserVideo(
      {required int uid, required bool videoDisabled}) async {
    AgoraUser _tempUser =
        state.activeUsers.singleWhere((element) => element.uid == uid);
    Set<AgoraUser> _tempSet = state.activeUsers;
    _tempSet.remove(_tempUser);
    _tempSet.add(_tempUser.copyWith(videoDisabled: videoDisabled));
  }

  Future<void> toggleUserAudio(
      {required int index, required bool muted}) async {
    if (muted) {
      state.channel!.sendMessage(AgoraRtmMessage.fromText(
          "unmute ${state.activeUsers.elementAt(index).uid}"));
    } else {
      state.channel!.sendMessage(AgoraRtmMessage.fromText(
          "mute ${state.activeUsers.elementAt(index).uid}"));
    }
  }

  Future<void> toggleUserVideo(
      {required int index, required bool enable}) async {
    if (enable) {
      state.channel!.sendMessage(AgoraRtmMessage.fromText(
          "enable ${state.activeUsers.elementAt(index).uid}"));
    } else {
      state.channel!.sendMessage(AgoraRtmMessage.fromText(
          "disable ${state.activeUsers.elementAt(index).uid}"));
    }
  }
}
