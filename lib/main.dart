import 'package:flutter/material.dart';
import 'package:music_player_manager/homepage.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting('id_ID', null).then((data) => runApp(const MyApp()));
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
