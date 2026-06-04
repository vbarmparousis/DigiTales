//Import Packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

//My Imports
import '../models/story.dart';
import 'story_creation_page.dart';
import 'stories_list_page.dart';


class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key, required this.title});

  final String title;

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {

  late Box storyBox;

  @override
  void initState() {
    super.initState();
    //Grands access to Hive Story Box
   storyBox=Hive.box('storyBox');
    //print('stoooooooooooooryBox.keys');
    //print(storyBox.keys);

    //Clears the temporary list to prevent duplicate stories
    //when te page is opened again.
    /*widget.stories.clear();

    var savedStory;

    //Loads all the stories from Hive Box and stores it into Story objects.
    for(savedStory in storyBox.values){
      final story=Story(
        title: savedStory['title'],
        description: savedStory['description'],
        storyAudio: savedStory['storyAudio'],
      );

      //Stores the loaded story into the temporary story list.
      widget.stories.add(story);

    }*/
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),

      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.

        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_note_rounded,
              size: 150,
              color: Colors.teal,
            ),

            const SizedBox(height: 30),

            const Text(
              'Parent Mode',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(35)
                    ),
                  ),

                  onPressed: () async {
                    //Opens the Story Creation Page and waits for a new story title
                    //Navigator.push returns the story title when Story Creation Page closes.
                    var newStory = await Navigator.push(
                        context, MaterialPageRoute(
                      builder: (context) => const StoryCreationPage(),
                    )
                    );

                    //Checks if there is any new stories.
                    // If there is a new story it is stored inside Hive.
                    if (newStory !=null){

                      //Rebuilds after adding the new story inside Hive
                      setState(() {});

                      //Stores the new story inside Hive.
                      await storyBox.add({
                        'title': newStory.title,
                        'description': newStory.description,
                        'storyAudio': newStory.storyAudio,
                        'coverImage': newStory.coverImage,
                        'audioDuration': newStory.audioDuration,
                      });
                      //print(storyBox.keys);
                    }

                  },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_add),
                        SizedBox(width:10),
                        Text('Create Story'),
                      ],
                    )
                ),

                const SizedBox(width: 20,),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(170, 70),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(35)
                    ),
                  ),
                  onPressed: () {
                    //Opens the Stories List Page.
                    //Sends the stories list to Stories List Page.
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => StoriesListPage(),
                    )
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.library_books_rounded),
                      SizedBox(width:10),
                      Text('Manage Library'),
                    ],
                  )
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}



