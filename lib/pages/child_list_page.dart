//Import Libraries
import 'dart:io';

//Import Packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

//My Imports
import '../models/story.dart';
import 'child_story_page.dart';

class ChildListPage extends StatelessWidget {
  const ChildListPage({super.key});

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
            const Text(
              'Choose a story to listen',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24),
            ),

            const SizedBox(height: 32),

            //Checks if there are no stored stories in hive story box.
            //If hive box is empty, shows the appropriate message on screen.
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

                    //Creates a scrollable grid of story cards.
                    child: GridView.builder(
                      itemCount: storyBox.length,

                      //Grid layout:
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            //Shows 2 story cards per row.
                            crossAxisCount: 2,
                            //Horizontal space between story cards.
                            crossAxisSpacing: 12,
                            //Vertical space between story cards.
                            mainAxisSpacing: 12,
                            //Width/Height Ratio.
                            childAspectRatio: 1,
                          ),

                      //Story card builder.
                      itemBuilder: (context, index) {
                        //Loads a stored story from
                        //Hive Story Box using its index position.
                        final loadedStory = storyBox.getAt(index);

                        //Converts Hive Map data into real Story object.
                        final story = Story.fromMap(loadedStory);

                        //Inkwell makes the whole story card tappable.
                        return InkWell(

                          //Tap effect follows rounder card corners.
                          borderRadius: BorderRadius.circular(25),

                          //Opens selected story and sends the Story
                          //object to the ChildStoryPage.
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

                              //White Border around each story card.
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 4,
                              ),

                              //Shadow under each story card.
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  //Shifts shadow 8 pixels down.
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),

                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Stack(
                                //Stack children fill the story card.
                                fit: StackFit.expand,
                                children: [
                                  //Story Cover Image.
                                  story.coverImage.isNotEmpty
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
                                            size: 70,
                                            color: Colors.teal,
                                          ),
                                        ),

                                  //Dark Gradient Overlay.
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withValues(alpha: 0.5),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  //Story Title.
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.80,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Text(
                                        story.title,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,

                                        //Adds '...' if title is too long.
                                        overflow: TextOverflow.ellipsis,

                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
