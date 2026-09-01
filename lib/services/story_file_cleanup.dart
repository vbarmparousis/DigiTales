//Library Imports
import 'dart:io';

//Package Imports
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

//Story file cleanup service class.
class StoryFileCleanup {
  //Deletes story media files that are no longer used by any story in Hive.
  static Future<void> cleanupUnusedStoryFiles(Box storyBox) async {
    //Stores all media file paths used by saved stories.
    final List<String> usedFilePaths = [];

    //Check every story stored in Hive.
    for (final storedStory in storyBox.values) {
      //Converts the stored Hive data into a Map
      //so its story data can be accessed.
      final storyData = Map<dynamic, dynamic>.from(storedStory);

      usedFilePaths.add(storyData['coverImage'] ?? '');

      //Gets the stored story pages.
      final List storyPages = storyData['pages'] ?? [];

      //Stores every page image and narration path.
      for (final storyPage in storyPages) {
        usedFilePaths.add(storyPage['pageImage'] ?? '');
        usedFilePaths.add(storyPage['pageAudio'] ?? '');
      }
    }

    //Gets the app's private document directory.
    final appDirectory = await getApplicationDocumentsDirectory();

    //Checks every file stored inside the app directory.
    await for (final file in appDirectory.list()) {
      //Checks only actual files.
      if (file is File) {
        //Gets only the file name from the full file path.
        final fileName = file.path.split(Platform.pathSeparator).last;

        //Checks if the file is a media file created by DigiTales.
        //It prevents other files from being deleted.
        final bool isStoryMediaFile =
            fileName.startsWith('story_image_') ||
            fileName.startsWith('audio_recording_') ||
            fileName.startsWith('imported_story_file_');

        //Deletes the file only if it belongs to DigiTales and
        //is not used by any saved story.
        if (isStoryMediaFile && !usedFilePaths.contains(file.path)) {
          try {
            await file.delete();
          } catch (_) {
            //A cleanup failure doesn't interrupt the main operation.
          }
        }
      }
    }
  }
}
