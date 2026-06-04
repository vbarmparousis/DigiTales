//Create a new Class for Stories
class Story {
  final String title;
  final String description;
  final String storyAudio;
  final String coverImage;
  final int audioDuration;
  //Stores Hive Key for correct edit/delete operations
  final dynamic hiveKey;



  Story({
    required this.title,
    required this.description,
    required this.storyAudio,
    required this.coverImage,
    required this.audioDuration,
    this.hiveKey,

  });
}