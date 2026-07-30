//Import Libraries
import 'dart:io';

//Import Packages
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

//My Imports
import '../models/story.dart';
import 'child_story_page.dart';
import 'story_creation_page.dart';
import '../services/story_export.dart';
import '../services/story_import.dart';
import 'edit_story_page.dart';

//Popup menu actions of each story.
enum StoryMenuAction { edit, export, delete }

//Stateful Widget rebuilds the screen
//changes with setstate((){});
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

  //Deletes a local file inside the app's document directory.
  Future<void> deleteLocalAppStoryFiles(String filePath) async {
    //If there is no file path, the function stops.
    if (filePath.isEmpty) {
      return;
    }

    //Gets the app's private documents directory.
    final appDirectory = await getApplicationDocumentsDirectory();

    //Checks if the file is inside the app's document directory.
    //If not, the function stops.
    if (!filePath.startsWith(appDirectory.path)) {
      return;
    }

    final file = File(filePath);

    //Deletes the file only if it exists.
    if (await file.exists()) {
      await file.delete();
    }
  }

  //Deletes all local files of a deleted story.
  Future<void> deleteStoryFile(Story story) async {
    //Deletes the story cover image.
    await deleteLocalAppStoryFiles(story.coverImage);

    //Deletes every page image and audio.
    for (final page in story.pages) {
      await deleteLocalAppStoryFiles(page.pageImage);
      await deleteLocalAppStoryFiles(page.pageAudio);
    }
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

    //If the story update is canceled, the function stops.
    if (updatedStory == null) {
      return;
    }

    //Updates the story inside Hive.
    await storyBox.put(story.hiveKey, updatedStory.toMap());

    //Rebuilds the stories list.
    setState(() {});
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
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    //If the story deletion is canceled, the function stops.
    if (confirmDelete != true) {
      return;
    }

    //Deletes story's images and audio files from local storage.
    await deleteStoryFile(story);

    //Deletes story from Hive.
    await storyBox.delete(story.hiveKey);

    //Rebuilds the stories list.
    setState(() {});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Story deleted.')));
  }

  //Opens Story Creation Page and save the new story into Hive.
  Future<void> createStory({required Box storyBox}) async {
    //Opens the Story Creation Page and waits for a new story
    //Navigator.push returns the story title when Story Creation Page closes.
    final Story? newStory = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StoryCreationPage()),
    );

    //If story creation is canceled, the function stops.
    if (newStory == null) {
      return;
    }

    //Stores the new story inside Hive.
    await storyBox.add(newStory.toMap());

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

      //Rebuilds UI after importing the story.
      setState(() {});

      //Shows confirmation message.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Story imported.')));
    } catch (error) {
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
      filteredStories.sort((a, b) => a.title.compareTo(b.title));
    }
    //Sorts Stories Reversed Alphabetically.
    else if (sortingOption == 'Z-A') {
      filteredStories.sort((a, b) => b.title.compareTo(a.title));
    }
    //Sorts Stories by shortest Duration.
    else if (sortingOption == 'Shortest') {
      filteredStories.sort(
        (a, b) => getTotalStoryDuration(a).compareTo(getTotalStoryDuration(b)),
      );
    }
    //Sorts Stories by longest Duration.
    else if (sortingOption == 'Longest') {
      filteredStories.sort(
        (a, b) => getTotalStoryDuration(b).compareTo(getTotalStoryDuration(a)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        //Same Background as the Home Page
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Library'),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              //Create Story Button.
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            //Search TextField
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Stories',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  //Converts search text to lowercase
                  //for case-insensitive searching.
                  searchText = value.toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            //Sorting Dropdown
            DropdownButtonFormField<String>(
              initialValue: sortingOption,

              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
              ),

              //Sorting Dropdown
              items: const [
                DropdownMenuItem(value: 'A-Z', child: Text('Sort A-Z')),

                DropdownMenuItem(value: 'Z-A', child: Text('Sort Z-A')),

                DropdownMenuItem(
                  value: 'Shortest',
                  child: Text('Shortest First'),
                ),

                DropdownMenuItem(
                  value: 'Longest',
                  child: Text('Longest First'),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  sortingOption = value!;
                });
              },
            ),

            const SizedBox(height: 32),

            Expanded(
              child: storyBox.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_rounded,
                            size: 100,
                            color: Colors.teal,
                          ),
                          const Text(
                            'There are no stories yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 24),
                          ),
                        ],
                      ),
                    )
                  : filteredStories.isEmpty
                  ? const Center(
                      child: Text(
                        'No stories found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    )
                  : ListView.builder(
                      //Uses widget to get access to stories in this State
                      itemCount: filteredStories.length,
                      itemBuilder: (context, index) {
                        //Gets one filtered story from search results.
                        final story = filteredStories[index];

                        return Card(
                          child: ListTile(
                            leading: story.coverImage.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(story.coverImage),
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,

                                      //The library card needs a thumbnail-sized image.
                                      cacheWidth: 300,

                                      //Keeps the image stable during rebuilds.
                                      gaplessPlayback: true,

                                      filterQuality: FilterQuality.medium,

                                      //Shows a placeholder instead of
                                      //a white flash while the image is decoded.
                                      frameBuilder:
                                          (
                                            context,
                                            child,
                                            frame,
                                            wasSynchronouslyLoaded,
                                          ) {
                                            if (wasSynchronouslyLoaded ||
                                                frame != null) {
                                              return child;
                                            }

                                            return Container(
                                              height: 60,
                                              width: 60,
                                              color: Colors.teal.withValues(
                                                alpha: 0.10,
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.auto_stories_rounded,
                                                  size: 32,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                : const Icon(Icons.book_rounded),

                            title: Text(
                              story.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pages: ${story.pages.length}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),

                                    //Show Duration in ListTile.
                                    Text(
                                      formatTime(getTotalStoryDuration(story)),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            //Three dot menu with the available story actions.
                            trailing: PopupMenuButton<StoryMenuAction>(
                              icon: const Icon(Icons.more_vert_rounded),

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
                                        color: Colors.teal,
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
                                        color: Colors.teal,
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
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 12),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            onTap: () async {
                              //Prepares the cover and first pages before opening ChildStoryPage.
                              await precacheStoryImagesBeforeOpening(
                                context,
                                story,
                              );

                              if (!context.mounted) {
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChildStoryPage(story: story),
                                ),
                              );
                            },
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
