//Import Packages
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

//My Imports
import 'parent_list_page.dart';
import 'child_list_page.dart';
import '../widgets/section_card.dart';
import '../widgets/role_selection_card.dart';
import '../theme/app_colors.dart';

//First Page of the application
//The user selects between Parent Mode and Child role.
class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  //Device Authentication for Parent Mode.
  final LocalAuthentication parentModeAuthentication = LocalAuthentication();

  //Uses the device lock system before opening Parent Mode.
  Future<bool> authenticateParentMode() async {
    try {
      //Checks if the device supports biometrics
      //or another authentication method.
      final bool canAuthenticate =
          await parentModeAuthentication.canCheckBiometrics ||
          await parentModeAuthentication.isDeviceSupported();

      //If authentication is not available, shows appropriate message.
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device authentication is not available.'),
          ),
        );
        return false;
      }

      //Device Authentication Screen.
      final bool isAuthenticated = await parentModeAuthentication.authenticate(
        localizedReason: 'Please authenticate to enter Parent Mode.',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      //Returns true only if the authentication was successful.
      return isAuthenticated;
    }
    //Handles errors during authentication.
    catch (error) {
      //If authentication can't be used, shows appropriate message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent Mode requires device authentication.'),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                //Application Logo.
                Center(
                  child: Container(
                    height: 230,
                    width: 230,

                    child: Image.asset(
                      'images/logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Your Digital Storytelling Buddy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appText,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Create and listen to personalized audio stories.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: AppColors.appText),
                ),

                const SizedBox(height: 32),

                //Role Selection Section Card.
                SectionCard(
                  sectionCardMargin: EdgeInsets.zero,
                  children: [
                    const Text(
                      'Select your role:',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appText,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    Row(
                      children: [
                        //Child Mode Card.
                        RoleSelectionCard(
                          title: 'Child',
                          subtitle: 'Listen to stories',
                          icon: Icons.child_care_rounded,
                          color: AppColors.childMode,
                          onTap: () {
                            //Opens Child List Page.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChildListPage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),

                        //Parent Mode Card.
                        RoleSelectionCard(
                          title: 'Parent',
                          subtitle: 'Create and Manage',
                          icon: Icons.lock_person_rounded,
                          color: AppColors.parentMode,
                          onTap: () async {
                            final bool isAuthenticated =
                                await authenticateParentMode();

                            //If authentication fails, Parent Mode doesn't open.
                            if (!isAuthenticated) {
                              return;
                            }
                            //Opens Parent List Page.
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ParentListPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}
