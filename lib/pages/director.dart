// ignore_for_file: prefer_const_constructors, library_prefixes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_stream_app/controllers/director_controller.dart';
import 'package:live_stream_app/models/director_model.dart';

import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class Director extends StatefulWidget {
  final String channelName;
  final int uid;

  const Director({Key? key, required this.channelName, required this.uid})
      : super(key: key);

  @override
  State<Director> createState() => _DirectorState();
}

class _DirectorState extends State<Director> {
  @override
  void initState() {
    super.initState();
    context
        .read(directorController.notifier)
        .joinCall(channelName: widget.channelName, uid: widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (BuildContext context,
        T Function<T>(ProviderBase<Object?, T>) watch, Widget? child) {
      DirectorController directorNotifier = watch(directorController.notifier);
      DirectorModel directorData = watch(directorController);
      Size size = MediaQuery.of(context).size;

      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    SafeArea(
                      child: Container(),
                    )
                  ],
                ),
              ),
              if (directorData.activeUsers.isEmpty)
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Center(
                        child: Container(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('Nenhum usuário ativo')),
                      ),
                    ],
                  ),
                ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate((BuildContext ctx, index) {
                  return Row(
                    children: [
                      Expanded(
                        child: StageUser(
                            directorData: directorData,
                            directorNotifier: directorNotifier,
                            index: index),
                      ),
                    ],
                  );
                }, childCount: directorData.activeUsers.length,),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: size.width / 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20),
              ),  
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Divider(
                        thickness: 3,
                        indent: 80,
                        endIndent: 80,
                      ),
                    ),
                  ],
                ),
              ),
              if (directorData.lobbyUsers.isEmpty)
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Lobby vazio'),
                      ),
                    ),
                  ],
                ),
              ),
              SliverGrid(
                  delegate:
                      SliverChildBuilderDelegate((BuildContext ctx, index) {
                    return Row(
                      children: [
                        Expanded(
                          child: LobbyUser(
                              directorData: directorData,
                              directorNotifier: directorNotifier,
                              index: index),
                        ),
                      ],
                    );
                  }, childCount: directorData.lobbyUsers.length),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: size.width / 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20))
            ],
          ),
        ),
      );
    });
  }
}

class StageUser extends StatelessWidget {
  const StageUser(
      {Key? key,
      required this.directorData,
      required this.directorNotifier,
      required this.index})
      : super(key: key);

  final DirectorModel directorData;
  final DirectorController directorNotifier;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: directorData.activeUsers.elementAt(index).videoDisabled ? Stack(children: [Container(
              color: Colors.black
            )],) : Stack(),
          )
        ],
      ),
    );
  }
}

class LobbyUser extends StatelessWidget {
  const LobbyUser(
      {Key? key,
      required this.directorData,
      required this.directorNotifier,
      required this.index})
      : super(key: key);

  final DirectorModel directorData;
  final DirectorController directorNotifier;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: directorData.lobbyUsers.elementAt(index).videoDisabled ? 
          Stack(children: [
            Container(
              color:
                  (directorData.lobbyUsers.elementAt(index).backgroundColor !=
                          null)
                      ? directorData.lobbyUsers
                          .elementAt(index)
                          .backgroundColor!
                          .withOpacity(1)
                      : Colors.black,
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                directorData.lobbyUsers.elementAt(index).name ?? "Erro ao mostrar nome",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ]) : RtcRemoteView.SurfaceView(
            channelId: 'gfx',
            uid: directorData.lobbyUsers.elementAt(index).uid,
            ),
        ),
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), color: Colors.black54),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  directorNotifier.promoteToActiveUser(
                      uid: directorData.lobbyUsers.elementAt(index).uid);
                },
                icon: Icon(Icons.arrow_upward),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
