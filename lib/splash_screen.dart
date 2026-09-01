//Package Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//My Imports
import 'pages/role_selection_page.dart';
import 'theme/app_colors.dart';

//Splash Screen appears when the application starts.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

//Controls Splash Screen behavior.
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    //Waits 5 seconds before opening the Role Selection Page.
    Future.delayed(const Duration(seconds: 5), () {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Replaces Splash Screen so the user
      //can't return to it using the back button.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          //Container takes full screen width
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.childMode, AppColors.parentPrimary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Column(
            //Centers widgets vertically.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  height: 230,
                  width: 230,

                  child: Image.asset(
                    'images/logo.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),

              const SizedBox(height: 32),

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
                'Stories that sound like home.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
