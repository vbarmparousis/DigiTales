//Library Imports
import 'dart:io';

//Package Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

//My Imports
import '../models/story.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_card.dart';
import 'story_time_page.dart';
import '../widgets/story_book_cover.dart';

class ChildListPage extends StatefulWidget {
  const ChildListPage({super.key});

  @override
  State<ChildListPage> createState() => _ChildListPageState();
}

class _ChildListPageState extends State<ChildListPage> {
  //Prevents opening multiple StoryTime pages at the same time.
  bool isOpeningStory = false;

  //Calculates a suitable decoding width for the story pages.
  int calculateStoryImageCacheWidth(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    //Converts the screen width from logical pixels to physical pixels
    final int physicalScreenWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).round();

    return physicalScreenWidth.clamp(1200, 2048).toInt();
  }

  //Creates the same resized provider for displaying and precaching images.
  ImageProvider<Object> getStoryImageProvider(
    BuildContext context,
    String imagePath,
  ) {
    return ResizeImage.resizeIfNeeded(
      calculateStoryImageCacheWidth(context),
      null,
      FileImage(File(imagePath)),
    );
  }

  //Precaches a small group of images.
  //This helps prevent white flashing when a page image is shown
  //for the first time during the page flip animation.
  Future<void> precacheStoryImagesBeforeOpening(
    BuildContext context,
    Story story,
  ) async {
    final List<String> imagePaths = [
      if (story.coverImage.isNotEmpty) story.coverImage,
      if (story.pages.isNotEmpty) story.pages[0].pageImage,
      if (story.pages.length > 1) story.pages[1].pageImage,
    ];

    //Removes duplicate and empty paths.
    final Set<String> validPaths = imagePaths
        .where((imagePath) => imagePath.isNotEmpty)
        .toSet();

    for (final imagePath in validPaths) {
      if (!context.mounted) {
        return;
      }

      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        continue;
      }
      try {
        await precacheImage(getStoryImageProvider(context, imagePath), context);
      } catch (_) {
        //The story can still open if an image can't be decoded.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //Grants access to Hive Story Box
    final storyBox = Hive.box('storyBox');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Library',
          foregroundColor: Colors.white,
          textColor: Colors.white,
          backgroundColor: AppColors.childMode,
        ),
        body: SafeArea(
          //the AppBar already protects the top system area so top:false.
          top: false,
          child: Padding(
            //Adds spacing so the UI doesn't touch the screen borders.
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              //Stretches the children horizontally across the available width.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose a story to listen to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appText,
                  ),
                ),

                const SizedBox(height: 24),

                //Story Grid Section Card.
                Expanded(
                  child: SectionCard(
                    children: [
                      Expanded(
                        //Checks if there are no stored stories in hive story box.
                        //If hive box is empty, shows the appropriate message on screen.
                        child: storyBox.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.book_rounded,
                                      size: 100,
                                      color: AppColors.appText,
                                    ),

                                    const SizedBox(height: 32),
                                    Text(
                                      'There are no stories yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: AppColors.appText,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            :
                              //Dynamic List Creation
                              //Creates a scrollable grid of story cards.
                              GridView.builder(
                                itemCount: storyBox.length,

                                //Grid layout:
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      //Shows 2 story cards per row.
                                      crossAxisCount: 2,
                                      //Horizontal space between story cards.
                                      crossAxisSpacing: 10,
                                      //Vertical space between story cards.
                                      mainAxisSpacing: 10,
                                      //Width/Height Ratio.
                                      childAspectRatio: 0.60,
                                    ),

                                //Story card builder.
                                itemBuilder: (context, index) {
                                  //Calculates the story index in reverse order
                                  //so the newest stories are displayed first.
                                  final reverseIndex =
                                      storyBox.length - 1 - index;

                                  //Loads a stored story from
                                  //Hive Story Box using its reverse index position.
                                  final loadedStory = storyBox.getAt(
                                    reverseIndex,
                                  );

                                  //Converts Hive Map data into real Story object.
                                  final story = Story.fromMap(loadedStory);

                                  //Inkwell makes the whole story card tappable.
                                  return InkWell(
                                    //Tap effect follows rounder card corners.
                                    borderRadius: BorderRadius.circular(20),

                                    //Opens selected story and sends the Story
                                    //object to the StoryTimePage.
                                    onTap: () async {
                                      //Stops another story from opening while one is already opening.
                                      if (isOpeningStory) {
                                        return;
                                      }

                                      isOpeningStory = true;

                                      //Prepares the cover and first pages before opening StoryTimePage.
                                      await precacheStoryImagesBeforeOpening(
                                        context,
                                        story,
                                      );

                                      if (!context.mounted) {
                                        return;
                                      }

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => StoryTimePage(
                                            story: story,
                                            mode: StoryTimeMode.child,
                                          ),
                                        ),
                                      );

                                      isOpeningStory = false;
                                    },

                                    //Miniature Book Cover.
                                    child: StoryBookCover(
                                      title: story.title,
                                      imagePath: story.coverImage,
                                      imageCacheWidth: 700,
                                      isMiniatureMode: true,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
