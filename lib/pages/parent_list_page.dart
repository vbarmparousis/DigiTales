//Library Imports
import 'dart:io';

//Package Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:share_plus/share_plus.dart';

//My Imports
import '../models/story.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/story_book_cover.dart';
import '../theme/button_styles.dart';
import 'story_time_page.dart';
import 'story_creation_page.dart';
import '../services/story_export.dart';
import '../services/story_import.dart';
import 'edit_story_page.dart';
import '../widgets/section_card.dart';
import '../services/story_file_cleanup.dart';

//Popup menu actions of each story.
enum StoryMenuAction { edit, export, delete }

//Stateful widget rebuilds the screen when its state changes.
class ParentListPage extends StatefulWidget {
  const ParentListPage({super.key});

  @override
  State<ParentListPage> createState() => _ParentListPageState();
}

class _ParentListPageState extends State<ParentListPage> {
  //Controls search TextField.
  final TextEditingController _searchController = TextEditingController();

  //Stores current search text.
  String searchText = '';

  //Stores current sorting option.
  String sortingOption = 'A-Z';

  //Prevents opening multiple StoryTime pages at the same time.
  bool isOpeningStory = false;

  //Formats audio duration into HH:MM:SS format.
  String formatTime(int seconds) {
    return Duration(
      seconds: seconds,
    ).toString().split('.').first.padLeft(8, '0');
  }

  //Calculates the total audio duration of all pages.
  int getTotalStoryDuration(Story story) {
    int totalDuration = 0;

    for (final page in story.pages) {
      totalDuration += page.pageAudioDuration;
    }
    return totalDuration;
  }

  //Exports a story as a zip file and opens device share menu.
  Future<void> exportStory(Story story) async {
    try {
      //Creates the exported zip file.
      final zipFile = await StoryExport.exportStoryToZip(story);

      //Opens the device share menu.
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          text: 'DigiTales story backup: ${story.title}',
        ),
      );
    } catch (error) {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Show error message if export fails.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story export failed.')));
    }
  }

  //Opens EditStoryPage.
  Future<void> editStory({required Story story, required Box storyBox}) async {
    //Opens EditStoryPage and waits for the updated story.
    final Story? updatedStory = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditStoryPage(story: story)),
    );

    //If the story update is canceled, deletes unused edit files
    //and stops the function.
    if (updatedStory == null) {
      await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);
      return;
    }

    //Updates the story inside Hive.
    await storyBox.put(story.hiveKey, updatedStory.toMap());

    //Deletes story media files that are no longer used.
    await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Rebuilds the stories list.
    setState(() {});

    //Shows confirmation message.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story updated.')));
  }

  //Shows a confirmation dialog before deleting a story.
  Future<void> deleteStory({
    required Story story,
    required Box storyBox,
  }) async {
    //Displays delete confirmation dialog.
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Story'),
        content: Text(
          'Are you sure you want to delete the story: "${story.title}"?',
        ),
        actions: [
          //Cancel deletion button.
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text('Cancel'),
          ),

          //Confirm deletion button.
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    //If the story deletion is canceled, the function stops.
    if (confirmDelete != true) {
      return;
    }

    //Deletes story from Hive.
    await storyBox.delete(story.hiveKey);

    //Deletes story media files that are no longer used.
    await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Rebuilds the stories list.
    setState(() {});

    //Shows confirmation message.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story deleted.')));
  }

  //Opens Story Creation Page and save the new story into Hive.
  Future<void> createStory({required Box storyBox}) async {
    //Opens the Story Creation Page and waits for a new story
    //Navigator.push returns the new Story when Story Creation Page closes.
    final Story? newStory = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryCreationPage()),
    );

    //If story creation is canceled, deletes unused draft files
    //and stops the function.
    if (newStory == null) {
      await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);
      return;
    }

    //Stores the new story inside Hive.
    await storyBox.add(newStory.toMap());

    //Deletes story media files that are no longer used.
    await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Rebuilds UI after adding the new story.
    setState(() {});

    //Shows confirmation message.
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story created.')));
  }

  Future<void> importStory({required Box storyBox}) async {
    try {
      //Opens file picker and imports the selected zip file as a Story object.
      final Story? importedStory = await StoryImport.importStoryFromZip();

      //If file selection is canceled, the function stops.
      if (importedStory == null) {
        return;
      }

      //Saves the imported story inside Hive.
      await storyBox.add(importedStory.toMap());

      //Deletes story media files that are no longer used.
      await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Rebuilds UI after importing the story.
      setState(() {});

      //Shows confirmation message.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story imported.')));
    } catch (error) {
      //Deletes any unused media files from a failed import.
      await StoryFileCleanup.cleanupUnusedStoryFiles(storyBox);

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Shows error message if import fails.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story import failed.')));
    }
  }

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
  void dispose() {
    //Free memory from search controller.
    _searchController.dispose();
    //Calls parent class dispose method to complete cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Grants access to Hive Story Box
    final storyBox = Hive.box('storyBox');

    //Creates a temporary list with all stories loaded from Hive.
    final List<Story> allStoriesList = [];

    //Loads all stories from Hive and turns them into Story objects.
    //The key is needed so edit/delete works correctly after filtering.
    for (final key in storyBox.keys) {
      final loadedStory = storyBox.get(key);
      allStoriesList.add(Story.fromMap(loadedStory, hiveKey: key));
    }

    //Filters stories based on the search text.
    final filteredStories = allStoriesList.where((story) {
      return story.title.toLowerCase().contains(searchText);
    }).toList();

    //Sorts Stories Alphabetically.
    if (sortingOption == 'A-Z') {
      filteredStories.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    //Sorts Stories Reversed Alphabetically.
    else if (sortingOption == 'Z-A') {
      filteredStories.sort(
        (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
      );
    }
    //Sorts Stories by shortest Duration.
    else if (sortingOption == 'Shortest Duration') {
      filteredStories.sort(
        (a, b) => getTotalStoryDuration(a).compareTo(getTotalStoryDuration(b)),
      );
    }
    //Sorts Stories by longest Duration.
    else if (sortingOption == 'Longest Duration') {
      filteredStories.sort(
        (a, b) => getTotalStoryDuration(b).compareTo(getTotalStoryDuration(a)),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: 'Library',
          foregroundColor: Colors.white,
          backgroundColor: AppColors.parentMode,
          textColor: Colors.white,
        ),

        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                //Create Story Button.
                Expanded(
                  child: ElevatedButton.icon(
                    style: ButtonStyles.primaryParentButton,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Story'),
                    onPressed: () async {
                      await createStory(storyBox: storyBox);
                    },
                  ),
                ),
                const SizedBox(width: 12),

                //Import Story Button.
                Expanded(
                  child: ElevatedButton.icon(
                    style: ButtonStyles.secondaryParentButton,
                    icon: const Icon(Icons.file_upload_rounded),
                    label: const Text('Import Story'),
                    onPressed: () async {
                      await importStory(storyBox: storyBox);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              //Search and Sort Section Card.
              SectionCard(
                children: [
                  Row(
                    children: [
                      //Search TextField
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search stories',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.appText,
                            ),

                            //Adds a clear button only when the user types something.
                            suffixIcon: searchText.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.appText,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        searchText = '';
                                      });
                                    },
                                  ),

                            filled: true,
                            fillColor: Colors.white,

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),

                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.appText,
                                width: 1.5,
                              ),
                            ),

                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.appText,
                                width: 2,
                              ),
                            ),
                          ),

                          onChanged: (value) {
                            setState(() {
                              //Trims search text and converts it to lowercase
                              //for case-insensitive searching.
                              searchText = value.trim().toLowerCase();
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      //Sorting Popup Button.
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.appText,
                            width: 1.5,
                          ),
                        ),

                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.sort_rounded,
                            color: AppColors.appText,
                          ),

                          //Current sorting option.
                          initialValue: sortingOption,

                          //Runs when a sorting option is selected.
                          onSelected: (value) {
                            setState(() {
                              sortingOption = value;
                            });
                          },

                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'A-Z',
                              child: Text(
                                'Sort A-Z',
                                style: TextStyle(color: AppColors.appText),
                              ),
                            ),

                            PopupMenuItem(
                              value: 'Z-A',
                              child: Text(
                                'Sort Z-A',
                                style: TextStyle(color: AppColors.appText),
                              ),
                            ),

                            PopupMenuItem(
                              value: 'Shortest Duration',
                              child: Text(
                                'Shortest Duration',
                                style: TextStyle(color: AppColors.appText),
                              ),
                            ),

                            PopupMenuItem(
                              value: 'Longest Duration',
                              child: Text(
                                'Longest Duration',
                                style: TextStyle(color: AppColors.appText),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  //Shows the current sorting option under the search row.
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Sorting: $sortingOption',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.appText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              //Story List Section Card.
              Expanded(
                child: SectionCard(
                  children: [
                    Expanded(
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
                          : filteredStories.isEmpty
                          ? const Center(
                              child: Text(
                                'No stories found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: AppColors.appText,
                                ),
                              ),
                            )
                          : ListView.builder(
                              //Uses widget to get access to stories in this State
                              itemCount: filteredStories.length,
                              itemBuilder: (context, index) {
                                //Gets one filtered story from search results.
                                final story = filteredStories[index];

                                return Card(
                                  color: AppColors.listCard,
                                  clipBehavior: Clip.antiAlias,

                                  child: InkWell(
                                    onTap: () async {
                                      //Stops another story from opening while one is already opening.
                                      if (isOpeningStory) {
                                        return;
                                      }

                                      isOpeningStory = true;

                                      //Prepares the cover and first pages before opening StoryPage.
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
                                            mode: StoryTimeMode.parent,
                                          ),
                                        ),
                                      );
                                      isOpeningStory = false;
                                    },

                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),

                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          //Miniature Book Cover.
                                          SizedBox(
                                            width: 66,
                                            height: 102,

                                            child: StoryBookCover(
                                              title: story.title,
                                              imagePath: story.coverImage,
                                              imageCacheWidth: 300,
                                              isMiniatureMode: true,
                                              showTitle: false,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                //Story Title.
                                                Text(
                                                  story.title,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: AppColors.appText,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                //Story Page Number.
                                                Text(
                                                  'Pages: ${story.pages.length}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: AppColors.appText,
                                                  ),
                                                ),

                                                const SizedBox(height: 4),

                                                //Total Story Duration.
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.access_time_rounded,
                                                      size: 16,
                                                      color: AppColors.appText,
                                                    ),
                                                    const SizedBox(width: 4),

                                                    //Show Duration in ListTile.
                                                    Text(
                                                      formatTime(
                                                        getTotalStoryDuration(
                                                          story,
                                                        ),
                                                      ),
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.appText,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          //Three dot menu with the available story actions.
                                          PopupMenuButton<StoryMenuAction>(
                                            icon: const Icon(
                                              Icons.more_vert_rounded,
                                              color: AppColors.appText,
                                            ),

                                            //Runs when an action is selected from the menu.
                                            onSelected: (action) async {
                                              switch (action) {
                                                case StoryMenuAction.edit:
                                                  await editStory(
                                                    story: story,
                                                    storyBox: storyBox,
                                                  );
                                                  break;
                                                case StoryMenuAction.export:
                                                  await exportStory(story);
                                                  break;

                                                case StoryMenuAction.delete:
                                                  await deleteStory(
                                                    story: story,
                                                    storyBox: storyBox,
                                                  );
                                                  break;
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: StoryMenuAction.edit,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit_rounded,
                                                      color: AppColors.appText,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('Edit'),
                                                  ],
                                                ),
                                              ),

                                              PopupMenuItem(
                                                value: StoryMenuAction.export,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.ios_share_rounded,
                                                      color: AppColors.appText,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('Export'),
                                                  ],
                                                ),
                                              ),

                                              PopupMenuItem(
                                                value: StoryMenuAction.delete,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_rounded,
                                                      color: AppColors.danger,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('Delete'),
                                                  ],
                                                ),
                                              ),
                                            ],
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
            ],
          ),
        ),
      ),
    );
  }
}
