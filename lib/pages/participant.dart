// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

class Participant extends StatefulWidget {
  final String channelName;
  final String userName;

  const Participant(
      {Key? key, required this.channelName, required this.userName})
      : super(key: key);

  @override
  State<Participant> createState() => _ParticipantState();
}

class _ParticipantState extends State<Participant> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Participante'),
      ),
    );
  }
}
