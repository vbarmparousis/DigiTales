//Custom Class: Story.
//This class represents a complete digital story.
class Story {
  final String title;
  final String coverImage;

  //Each story object contains multiple pages.
  final List<StoryPage> pages;

  final String backgroundMusic;

  //Stores Hive key of the story for correct edit/delete operations.
  final dynamic hiveKey;

  //Story constructor.
  Story({
    required this.title,
    required this.coverImage,
    required this.pages,

    //Background music is optional.
    this.backgroundMusic = '',

    //hiveKey is not required because a new story doesn't
    //have a Hive key before it's saved inside the Hive box.
    this.hiveKey,
  });

  //Converts a Story object into a Map object.
  //
  //Hive stores simple data type, the custom class Story can't
  //be stored properly, so it needs to be converted into a
  //Map first.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'coverImage': coverImage,
      'backgroundMusic': backgroundMusic,

      //Converts every StoryPage object into a Map.
      //The result is a List of Maps.
      'pages': pages.map((page) => page.toMap()).toList(),
    };
  }

  //Converts a Map object back into a Story object.

  //Hive returns stored data as Map-like data.
  //This Map is converted back into a Story object.
  factory Story.fromMap(Map<dynamic, dynamic> map, {dynamic hiveKey}) {
    return Story(
      title: map['title'] ?? '',
      coverImage: map['coverImage'] ?? '',
      backgroundMusic: map['backgroundMusic'] ?? '',
      pages: (map['pages'] as List? ?? [])
          .map((pageMap) => StoryPage.fromMap(pageMap))
          .toList(),
      hiveKey: hiveKey,
    );
  }
}

//Custom Class: StoryPage.
//This class represents one page of a digital story.
//Each page contains its own image, audio and audio duration.
class StoryPage {
  final String pageImage;
  final String pageAudio;
  final int pageAudioDuration;

  //StoryPage Constructor.
  StoryPage({
    required this.pageImage,
    required this.pageAudio,
    required this.pageAudioDuration,
  });

  //Converts a StoryPage object into a Map object
  //in order to store it inside Hive.
  Map<String, dynamic> toMap() {
    return {
      'pageImage': pageImage,
      'pageAudio': pageAudio,
      'pageAudioDuration': pageAudioDuration,
    };
  }

  //Converts a Map object back into a StoryPage object.

  //Hive returns stored data as Map-like data.
  //This Map is converted back into a StoryPage object.
  factory StoryPage.fromMap(Map<dynamic, dynamic> map) {
    return StoryPage(
      pageImage: map['pageImage'] ?? '',
      pageAudio: map['pageAudio'] ?? '',
      pageAudioDuration: map['pageAudioDuration'] ?? 0,
    );
  }
}
