//Library Imports
import 'dart:io';
import 'dart:convert';

//Package Imports
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

//My Imports
import '../models/story.dart';

//Story export service class.
class StoryExport {
  //Exports a story as a zip file.
  static Future<File> exportStoryToZip(Story story) async {
    //Creates an empty archive object.
    //Later it will become the zip file.
    final exportZipArchive = Archive();

    //Creates the story data that will be saved into story.json file.
    final Map<String, dynamic> exportedStoryData = {
      'title': story.title,
      'coverImage': 'cover_image${p.extension(story.coverImage)}',
      'backgroundMusic': story.backgroundMusic,
      'pages': List.generate(story.pages.length, (index) {
        final page = story.pages[index];

        return {
          'pageImage': 'page_${index + 1}_image${p.extension(page.pageImage)}',
          'pageAudio': 'page_${index + 1}_audio${p.extension(page.pageAudio)}',
          'pageAudioDuration': page.pageAudioDuration,
        };
      }),
    };

    //Converts story data to JSON text.
    final storyJson = jsonEncode(exportedStoryData);

    //Adds story.json as a text file inside the archive object.
    exportZipArchive.addFile(ArchiveFile.string('story.json', storyJson));

    //Adds cover image inside the archive object.
    await addFileToZipArchive(
      exportZipArchive: exportZipArchive,
      originalFilePath: story.coverImage,
      exportedFileName: 'cover_image${p.extension(story.coverImage)}',
    );

    //Adds every page image and audio inside the archive object.
    for (int index = 0; index < story.pages.length; index++) {
      final page = story.pages[index];

      await addFileToZipArchive(
        exportZipArchive: exportZipArchive,
        originalFilePath: page.pageImage,
        exportedFileName:
            'page_${index + 1}_image${p.extension(page.pageImage)}',
      );

      await addFileToZipArchive(
        exportZipArchive: exportZipArchive,
        originalFilePath: page.pageAudio,
        exportedFileName:
            'page_${index + 1}_audio${p.extension(page.pageAudio)}',
      );
    }

    //Gets app's temporary directory.
    final temporaryDirectory = await getTemporaryDirectory();

    //Creates a safe file name for the exported zip.
    final zipStoryTitle = story.title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');

    //Creates the exported zip file path.
    final zipFilePath = '${temporaryDirectory.path}/$zipStoryTitle.zip';

    //Encode the archive into real zip file bytes.
    final zipBytes = ZipEncoder().encode(exportZipArchive);

    //Creates a file object that points to the final zip path.
    final zipFile = File(zipFilePath);

    //Writes the zip bytes to the zip file.
    await zipFile.writeAsBytes(zipBytes);

    //Returns the created zip file.
    return zipFile;
  }

  //Adds a local file into the archive object.
  static Future<void> addFileToZipArchive({
    required Archive exportZipArchive,
    required String originalFilePath,
    required String exportedFileName,
  }) async {
    //If the file path is empty, the function stops.
    if (originalFilePath.isEmpty) {
      return;
    }

    final file = File(originalFilePath);

    //If the file doesn't exist, the function stops.
    if (!await file.exists()) {
      return;
    }

    //Reads the file bytes.
    final fileBytes = await file.readAsBytes();

    //Adds the file bytes into the archive object.
    exportZipArchive.addFile(
      ArchiveFile(exportedFileName, fileBytes.length, fileBytes),
    );
  }
}
