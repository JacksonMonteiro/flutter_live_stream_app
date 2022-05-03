// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:live_stream_app/pages/director.dart';
import 'package:live_stream_app/pages/participant.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _channelName = TextEditingController();
  final _userName = TextEditingController();
  late int uid;

  @override
  void initState() {
    super.initState();
    getUserUid();
  }

  Future<void> getUserUid() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt('localUid');
    print('UID salvo: $uid');
    if (storedUid != null) {
      uid = storedUid;
    } else {
      int time = DateTime.now().microsecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 3));
      preferences.setInt('localUid', uid);
      print('Configurações de UID: $uid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset('assets/images/logo.png'),
        SizedBox(
          height: 5,
        ),
        Text("Faça multi Streamings com seus amigos"),
        SizedBox(
          height: 40,
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: TextField(
              controller: _userName,
              decoration: InputDecoration(
                hintText: "Nome de Usuário",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            )),
        SizedBox(
          height: 8,
        ),
        SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: TextField(
              controller: _channelName,
              decoration: InputDecoration(
                hintText: "Nome do canal",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
            )),
        SizedBox(height: 32),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: TextButton(
            style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Participant(
                        channelName: _channelName.text,
                        userName: _userName.text,
                        uid: uid,
                      )));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Participante',
                  style: TextStyle(fontSize: 28, color: Colors.black),
                ),
                SizedBox(width: 8),
                Icon(Icons.live_tv, color: Colors.black),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: TextButton(
            style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20))),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Director(
                        channelName: _channelName.text,
                      )));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Diretor',
                  style: TextStyle(fontSize: 28, color: Colors.white),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.cut,
                  color: Colors.white,
                )
              ],
            ),
          ),
        ),
      ])),
    );
  }
}
