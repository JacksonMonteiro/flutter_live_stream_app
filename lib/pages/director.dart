// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_stream_app/controllers/director_controller.dart';
import 'package:live_stream_app/models/director_model.dart';

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
        body: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                SafeArea(
                  child: Text('Diretor'),
                )
              ]),
            ),
            if (directorData.activeUsers.isEmpty)
              SliverList(
                delegate: SliverChildListDelegate([
                  Center(
                    child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('Estado vazio')),
                  ),
                ]),
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
              }, childCount: directorData.activeUsers.length),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: size.width / 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20),
            ),
          ],
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
        children: [],
      ),
    );
  }
}
