//Import Packages
import 'package:digital_storytelling_app/splash_screen.dart';
import 'package:digital_storytelling_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  //Ensures Flutter is fully initialized before
  //using asynchronous plugins like Hive.
  WidgetsFlutterBinding.ensureInitialized();

  //Initializes Hive local storage.
  await Hive.initFlutter();

  //Opens the Hive box 'storyBox' that stores all created stories.
  await Hive.openBox('storyBox');

  //Locks application orientation to portrait mode only.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  //Starts Application.
  runApp(const DigitalStorytellingApp());
}

//Main widget of the application.
class DigitalStorytellingApp extends StatelessWidget {
  const DigitalStorytellingApp({super.key});

  @override
  Widget build(BuildContext context) {
    //Basic structure of the app.
    return MaterialApp(
      title: 'DigiTales',
      theme: ThemeData(
        //Sets Nunito as the default font of the app.
        fontFamily: 'Nunito',

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,

        scaffoldBackgroundColor: AppColors.appBackground,

        //Default style for AppBar.
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,

            //Sets Nunito as the default font of the AppBar.
            fontFamily: 'Nunito',
          ),
        ),
      ),

      //Splash Screen. The first screen of the application.
      home: const SplashScreen(),
    );
  }
}
