//Package Imports
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';

//My Imports
import 'splash_screen.dart';
import 'theme/app_colors.dart';

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

  //Allows the application to draw behind the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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

        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.parentPrimary),
        useMaterial3: true,

        scaffoldBackgroundColor: AppColors.appBackground,

        //Default style for SnackBars.
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.appText,
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        ),
      ),

      //Splash Screen. The first screen of the application.
      home: const SplashScreen(),
    );
  }
}
