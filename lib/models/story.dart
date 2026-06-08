//Complete Story Class.
class Story {
  final String title;
  final String coverImage;

  //Each story contains multiple pages.
  final List<StoryPage> pages;

  //Stores Hive Key for correct edit/delete operations
  final dynamic hiveKey;

  Story({
    required this.title,
    required this.coverImage,
    required this.pages,
    this.hiveKey,

  });

  //Converts a Story object into a Map object
  //in order to store a story into Hive.
  Map<String, dynamic> toMap() {
    return{
      'title' : title,
      'coverImage' : coverImage,
      'pages' : pages.map((page) => page.toMap()).toList(),
    };
  }

  //Creates a Story object from a Map
  //in order to load a story from Hive.
  factory Story.fromMap(
      Map<dynamic, dynamic> map, {
        dynamic hiveKey,
      }
    ){
      return Story(
        title: map['title'] ?? '',
        coverImage: map['coverImage'] ?? '',
        pages: (map['pages'] as List? ?? [])
          .map((pageMap) => StoryPage.fromMap(pageMap))
          .toList(),
        hiveKey: hiveKey,
      );
      }
}

//Story Page Class.
//Each page contains its own image, audio and audio duration.
class StoryPage {
  final String pageImage;
  final String pageAudio;
  final int pageAudioDuration;

  StoryPage({
    required this.pageImage,
    required this.pageAudio,
    required this.pageAudioDuration,
  });

  //Converts a StoryPage object into a Map object
  //in order to store a story page into Hive.
  Map<String, dynamic> toMap() {
    return {
      'pageImage' : pageImage,
      'pageAudio' : pageAudio,
      'pageAudioDuration' : pageAudioDuration,
  };
  }

  //Creates a StoryPage object from a Map
  //in order to load a story page from Hive.
  factory StoryPage.fromMap( Map<dynamic, dynamic> map) {
    return StoryPage(
      pageImage: map['pageImage'] ?? '',
      pageAudio: map['pageAudio'] ?? '',
      pageAudioDuration: map['pageAudioDuration'] ?? 0,
    );
  }
}