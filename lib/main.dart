//Import Packages
import 'package:digital_storytelling_app/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';


Future<void> main() async {

  //Ensures Flutter bindings are initialized before
  //using asynchronous plugins like Hive.
  WidgetsFlutterBinding.ensureInitialized();

  //Initializes Hive local storage.
  await Hive.initFlutter();

  //Opens the local Hive Story Box.
  await Hive.openBox('storyBox');

  //Locks application orientation to portrait mode only.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]);

  //Starts Application.
  runApp(const DigitalStorytellingApp());
}

class DigitalStorytellingApp extends StatelessWidget {
  const DigitalStorytellingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Storytelling',
      theme: ThemeData(

        //Added Font: Nunito
        fontFamily:'Nunito',

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,

            //Added Font: Nunito
            fontFamily:'Nunito',

          ),
        )
      ),
      home: const SplashScreen(),
    );
  }
}

