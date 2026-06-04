//Import Packages
import 'package:flutter/material.dart';

//My Imports
import 'parent_home_page.dart';
import 'child_home_page.dart';
import '../widgets/app_background.dart';

//First Page of the application
//The user selects between Parent and Child role.
class UserSelectionPage extends StatefulWidget{

  const UserSelectionPage({super.key});

  @override
  State<UserSelectionPage> createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        //Uses the same app bar background color as the rest of the app.
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: const Text ('Digi-Tales'),
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
                )]
              ,),



            const SizedBox(height: 35),

            const Text(
              'Digital Storytelling',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
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
              style: TextStyle(fontSize: 25,
                //color: Colors.white,
                ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                //Child Role Button
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 150),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),

                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) =>
                            ChildHomePage(
                              //title: 'Child Page',
                            ),
                      ),
                      );
                    },

                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.child_care_rounded, size: 80,),
                        SizedBox(height: 20),
                        Text('Child',style: TextStyle(fontSize: 26),
                        ),

                      ],
                    )

                ),

                const SizedBox(width: 20),

                //Parent Role Button
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 150),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                    ),

                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) =>
                            ParentHomePage(
                              title: 'Parent Page',
                            ),
                      ),
                      );
                    },

                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, size: 80,),
                        SizedBox(height: 20),
                        Text('Parent',style: TextStyle(fontSize: 26),
                        ),

                      ],
                    )

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