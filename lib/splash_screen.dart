import 'package:digital_storytelling_app/pages/role_selection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//Splash Screen appears when the application starts.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//Controls Splash Screen behavior.
class _SplashScreenState
    extends
        State<SplashScreen> //Supports animation and ticker-based functionality.
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();

    //Allows fullscreen Splash Screen.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    //Waits 4 seconds before opening the User Selection Page.
    Future.delayed(Duration(seconds: 4), () {
      //Replaces Splash Screen so the user
      //can't return to it using the back botton.
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => UserSelectionPage()));
    });
  }

  @override
  void dispose() {
    //Restores System UI Overlay when Splash Screen is removed.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        //Container takes full screen width
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.teal],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          //Centers widgets vertically.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, size: 170, color: Colors.teal),

                Icon(
                  Icons.auto_stories_rounded,
                  size: 150,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 25),
            const Text(
              'Digital Storytelling',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 35,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Personalized audio stories.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
