//Import Packages
import 'package:flutter/material.dart';
import 'child_story_page.dart';
import 'package:hive/hive.dart';
import 'dart:io';

//My Imports
import '../models/story.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({super.key});

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    //Grants access to Hive Story Box
    final storyBox = Hive.box('storyBox');

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

            const Text(
              'Choose a story to listen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 32),

            //Checks if there are no stored stories in Hive Story Box.
            storyBox.isEmpty
                ? const Column(
                    children: [
                      Icon(Icons.book_rounded, size: 100, color: Colors.teal),

                      SizedBox(height: 32),
                      Text(
                        'There are no stories yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  )
                : Expanded(
                    //Dynamic List Creation
                    child: GridView.builder(
                      itemCount: storyBox.length,

                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),

                      itemBuilder: (context, index) {
                        //Loads one stored story from
                        // Hive Story Box using it's index position
                        final loadedStory = storyBox.getAt(index);

                        //Convert Hive Map data into real Story object.
                        final story = Story.fromMap(loadedStory);

                        return InkWell(
                          borderRadius: BorderRadius.circular(25),

                          //Opens selected story and sends the story object
                          //to ChildStoryPage.
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChildStoryPage(story: story),
                              ),
                            );
                          },

                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                //Story Cover Image.
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(25),
                                    ),
                                    child: story.coverImage.isNotEmpty
                                        ? Image.file(
                                            File(story.coverImage),
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            color: Colors.teal.withValues(
                                              alpha: 0.10,
                                            ),
                                            child: const Icon(
                                              Icons.auto_stories_rounded,
                                              size: 60,
                                              color: Colors.teal,
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      Text(
                                        story.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      //Show how many pages the story has.
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.menu_book_rounded,
                                              size: 16,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
