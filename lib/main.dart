import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter/material.dart';
import 'package:live_stream_app/appId.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Live Stream App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
} 

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AgoraClient client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(appId: appId, channelName: "live stream app"),
      enabledPermission: [Permission.camera, Permission.microphone]);

  @override
  void initState() {
    super.initState();
    client.initialize();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AgoraVideoViewer(client: client),
          AgoraVideoButtons(client: client),

        ],
      ),
    );
  }
}
