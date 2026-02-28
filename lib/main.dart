import 'package:flutter/material.dart';
import 'package:music_player_manager/homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MediaKit.ensureInitialized();
  await Future.delayed(const Duration(seconds: 1));
  // JustAudioMediaKit.ensureInitialized(android: true, windows: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Player Manager',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      // home: const AudioPlayerExample(),
      home: const MyHomePage(title: 'Music Player Manager'),
    );
  }
}
