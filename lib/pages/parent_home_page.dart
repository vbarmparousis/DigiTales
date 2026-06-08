//Import Packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

//My Imports
import '../models/story.dart';
import 'story_creation_page.dart';
import 'stories_list_page.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});


  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  late Box storyBox;

  @override
  void initState() {
    super.initState();
    //Grants access to Hive Story Box.r
    storyBox = Hive.box('storyBox');
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Parent Mode'),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_note_rounded, size: 150, color: Colors.teal),

            const SizedBox(height: 30),

            const Text(
              'Parent Mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Create, edit and manage your stories',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(170, 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),

                  onPressed: () async {
                    //Opens the Story Creation Page and waits for a new story
                    //Navigator.push returns the story title when Story Creation Page closes.
                    final Story? newStory = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoryCreationPage(),
                      ),
                    );

                    //Checks if there is any new stories.
                    // If there is a new story it is stored inside Hive.
                    if (newStory != null) {
                      //Stores the new story inside Hive.
                      await storyBox.add(newStory.toMap());

                      //Rebuilds UI after adding the new story inside Hive
                      setState(() {});
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_add),
                      SizedBox(width: 10),
                      Text('Create Story'),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(170, 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                  onPressed: () {
                    //Opens the Stories List Page.
                    //Sends the stories list to Stories List Page.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StoriesListPage(),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_rounded),
                      SizedBox(width: 10),
                      Text('Manage Library'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
