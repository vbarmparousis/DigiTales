//Import Packages
import 'package:flutter/material.dart';
import 'child_story_page.dart';
import 'package:hive/hive.dart';
import 'dart:io';

//My Imports
import '../models/story.dart';

class ChildHomePage extends StatelessWidget {
  const   ChildHomePage ({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {

    //Grands access to Hive Story Box
    final storyBox=Hive.box('storyBox');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Time'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
          body: Padding(
            //Adds spacing so the UI doesn't touch the screen borders.
            padding: const EdgeInsets.all(24),
            child: Column(
              //Column stretches widgets vertically.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  const SizedBox(height: 32),

                  const Icon(
                    Icons.headphones_rounded,
                    size: 150,
                    color: Colors.teal,
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Story Time',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Choose a story to listen',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24),
                  ),

                  const SizedBox(height: 32),

                  //Checks if there are no stored stories in Hive Story Box.
                  storyBox.isEmpty ?
                    const Column(
                      children: [
                         Icon(
                          Icons.book_rounded,
                          size: 100,
                          color: Colors.teal,
                        ),

                        SizedBox(height: 32),
                      Text(
                      'There are no stories yet.',
                        textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20),
                    ),
            ]
          )
                  :
                    Expanded(
                      //Dynamic List Creation
                      child: ListView.builder(

                        itemCount: storyBox.length,
                        itemBuilder: (context, index) {

                          //Loads one stored story from
                          // Hive Story Box using it's index position
                          final loadedStory = storyBox.getAt(index);

                          //Convert Hive Map data into real Story object.
                          final story = Story(
                            title: loadedStory['title'],
                            description: loadedStory['description'],
                            storyAudio: loadedStory['storyAudio'],
                            coverImage: loadedStory['coverImage'] ??'',
                            audioDuration: loadedStory['audioDuration'] ?? 0,
                          );

                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35)
                            ),


                            child: ListTile(

                              //Story Image Cover
                              leading: story.coverImage.isNotEmpty
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                    File(story.coverImage),
                                    height: 60,
                                    width: 60,
                                    fit: BoxFit.cover
                                ),
                              )
                                  :const Icon(Icons.book_rounded),

                              title: Text(
                                story.title,
                                maxLines:1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(story.description,
                                maxLines:1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              //Opens selected story and sends the story object
                              //to ChildStoryPage.
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChildStoryPage(
                                          story: story,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      ),
                    ),

                ],
              ),
            )
          );
     }
}