// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:live_stream_app/controllers/director_controller.dart';
import 'package:live_stream_app/models/director_model.dart';

class Director extends StatefulWidget {
  final String channelName;

  const Director({Key? key, required this.channelName}) : super(key: key);

  @override
  State<Director> createState() => _DirectorState();
}

class _DirectorState extends State<Director> {
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      DirectorController directorNotifier =
          ref.watch(directorController.notifier);
      DirectorModel directorData = ref.watch(directorController);

      return Scaffold(
        body: Center(
          child: Text('Director'),
        ),
      );
    });
  }
}
