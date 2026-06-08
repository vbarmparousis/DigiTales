//Import Packages
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

//My Imports
import 'stories_list_page.dart';
import 'child_home_page.dart';
import '../widgets/app_background.dart';
import '../widgets/role_selection_card.dart';

//First Page of the application
//The user selects between Parent and Child role.
class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  final LocalAuthentication parentModeAuthentication = LocalAuthentication();

  //Uses the device lock system before opening Parent Mode.
  Future<bool> authenticateParentMode() async {
    try {
      final bool canAuthenticate =
          await parentModeAuthentication.canCheckBiometrics ||
          await parentModeAuthentication.isDeviceSupported();

      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device authentication is not available.'),
          ),
        );
        return false;
      }
      final bool isAuthenticated = await parentModeAuthentication.authenticate(
        localizedReason: 'Please authenticate to enter Parent Mode.',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return isAuthenticated;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Parent Mode requires a device screen lock. Please set up a screen lock on your device to use Parent Mode',
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Uses the same app bar background color as the rest of the app.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Digi-Tales'),
      ),

      body:
          // AppBackground(
          //child:
          Padding(
            //Adds spacing so the UI doesn't touch the screen borders.
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              //Column stretches widgets vertically.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 170,
                      color: Colors.teal,
                    ),

                    const Icon(
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    //color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Create and listen to personalized audio stories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    //color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  'Select your Role:',
                  style: TextStyle(
                    fontSize: 25,
                    //color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                Row(
                  children: [

                    //Child Role Button
                    RoleSelectionCard(
                        title: 'Child',
                        subtitle: 'Listen to stories',
                        icon: Icons.child_care_rounded,
                        color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChildHomePage(),

                            ),
                          );
                      },
          ),
                    const SizedBox(width: 16),

                    //Parent Role Button
                    RoleSelectionCard(
                      title: 'Parent',
                      subtitle: 'Create and Manage',
                      icon: Icons.lock_person_rounded,
                      color: Colors.teal,
                      onTap: () async {
                        final bool isAuthenticated =
                            await authenticateParentMode();

                        if (!isAuthenticated) {
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StoriesListPage(),

                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
      // ),
    );
  }
}
