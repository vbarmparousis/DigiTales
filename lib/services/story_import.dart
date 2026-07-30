//Import  Libraries
import 'dart:convert';
import 'dart:io';

//Import Packages
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

//My Imports
import '../models/story.dart';

//Story import service class.
class StoryImport {
  //Imports a story from a zip file.
  static Future<Story?> importStoryFromZip() async {
    //Opens the device file picker and allows only zip files.
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    //If the file selection is canceled, the function stops.
    if (result == null) {
      return null;
    }

    //Gets the selected zip file path.
    final selectedZipPath = result.files.single.path;

    //If the selected zip path is empty, the function stops.
    if (selectedZipPath == null) {
      return null;
    }

    //Reads selected zip file as bytes.
    final zipBytes = await File(selectedZipPath).readAsBytes();

    //Decodes the zip bytes into an archive object that
    //contains the files inside the zip.
    final importedZipArchive = ZipDecoder().decodeBytes(zipBytes);

    //Finds story.json file inside the imported zip archive.
    final storyJsonFile = findArchiveFile(
      openedZipArchive: importedZipArchive,
      fileName: 'story.json',
    );

    //If story.json does not exist, the import fails.
    if (storyJsonFile == null) {
      throw Exception('story.json was not found inside the zip file');
    }

    //Reads story.json bytes from the opened zip archive.
    final List<int> storyJsonBytes = storyJsonFile.content as List<int>;

    //Converts story.json bytes into text.
    final storyJsonText = utf8.decode(storyJsonBytes);

    //Converts story.json text into a Map.
    final Map<String, dynamic> storyData = Map<String, dynamic>.from(
      jsonDecode(storyJsonText),
    );

    //Gets app's local document directory.
    final appDirectory = await getApplicationDocumentsDirectory();

    //Copies the imported cover image into the app storage.
    final importedCoverImagePath = await copyFileFromZipToAppDirectory(
      openedZipArchive: importedZipArchive,
      archiveFileName: storyData['coverImage'] ?? '',
      appDirectoryPath: appDirectory.path,
    );

    //Creates the imported story page list.
    final List<StoryPage> importedPages = [];

    //Gets pages data from story.json.
    final List pagesData = storyData['pages'] ?? [];

    //Copies every imported page image and audio into the app storage.
    for (int index = 0; index < pagesData.length; index++) {
      //Gets a page data Map from story.json.
      final Map<String, dynamic> pageData = Map<String, dynamic>.from(
        pagesData[index],
      );

      //Copies the imported page image into app storage.
      final importedPageImagePath = await copyFileFromZipToAppDirectory(
        openedZipArchive: importedZipArchive,
        archiveFileName: pageData['pageImage'] ?? '',
        appDirectoryPath: appDirectory.path,
      );

      //Copies the imported page audio into app storage.
      final importedPageAudioPath = await copyFileFromZipToAppDirectory(
        openedZipArchive: importedZipArchive,
        archiveFileName: pageData['pageAudio'] ?? '',
        appDirectoryPath: appDirectory.path,
      );

      //Adds the imported page into the page list.
      importedPages.add(
        StoryPage(
          pageImage: importedPageImagePath,
          pageAudio: importedPageAudioPath,
          pageAudioDuration: pageData['pageAudioDuration'] ?? 0,
        ),
      );
    }

    //Creates and returns the imported Story object.
    return Story(
      title: storyData['title'] ?? 'Imported Story',
      coverImage: importedCoverImagePath,
      backgroundMusic: storyData['backgroundMusic'] ?? '',
      pages: importedPages,
    );
  }

  //Finds a file inside the opened zip archive by its file name.
  static ArchiveFile? findArchiveFile({
    required Archive openedZipArchive,
    required String fileName,
  }) {
    //Searches every file inside the archive.
    for (final file in openedZipArchive.files) {
      //Returns the file if the name matches.
      if (file.name == fileName) {
        return file;
      }
    }

    //Returns null if the file was not found.
    return null;
  }

  //Copies a file from the opened zip archive into the app's private storage.
  static Future<String> copyFileFromZipToAppDirectory({
    required Archive openedZipArchive,
    required String archiveFileName,
    required String appDirectoryPath,
  }) async {
    //If there is no archive file name, the function stops.
    if (archiveFileName.isEmpty) {
      return '';
    }

    //Finds the requested file inside the opened zip archive.
    final archiveFile = findArchiveFile(
      openedZipArchive: openedZipArchive,
      fileName: archiveFileName,
    );

    //If the file was not found, the function stops.
    if (archiveFile == null) {
      return '';
    }

    //Reads the selected file as bytes from the opened zip archive.
    final List<int> fileBytes = archiveFile.content as List<int>;

    //Creates a unique imported file name.
    final now = DateTime.now()
        .toString()
        .replaceAll(':', '_')
        .replaceAll(' ', '_');

    //Keeps the original file extension.
    final extension = p.extension(archiveFileName);

    //Creates the new local file path into the app storage.
    final newFilePath = '$appDirectoryPath/imported_story_file_$now$extension';

    //Writes the imported file into app storage.
    final newFile = File(newFilePath);
    await newFile.writeAsBytes(fileBytes);

    //Returns the new local path.
    return newFile.path;
  }
}
