//Import Libraries
import 'dart:io';

//Import Packages
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:page_flip/page_flip.dart';

//My Imports
import '../models/story.dart';

class ChildStoryPage extends StatefulWidget {
  final Story story;

  const ChildStoryPage({super.key, required this.story});

  @override
  State<ChildStoryPage> createState() => _ChildStoryPageState();
}

class _ChildStoryPageState extends State<ChildStoryPage> {
  //Page audio player.
  final AudioPlayer _audioPlayer = AudioPlayer();

  //Background music audio player.
  final AudioPlayer _backgroundMusicAudioPlayer = AudioPlayer();

  //Stores the audio setup Future. It is used so the application can
  //wait until both players are ready to play together.
  late final Future<void> audioSetupFuture;

  //Checks if the current page audio is being played.
  //It is used to switch between Play and Pause buttons.
  bool isPlaying = false;

  //Checks if the current page audio is paused.
  bool isPaused = false;

  //Checks if the background music has started.
  bool isBackgroundMusicStarted = false;

  //Checks if the background music is paused..
  bool isBackgroundMusicPaused = false;

  //Controls the background music volume.
  static const double backgroundMusicVolume = 0.025;

  //Stores the current page audio duration.
  Duration duration = Duration.zero;

  //Stores current page audio playback position.
  Duration position = Duration.zero;

  //Controls the page flip widget
  //GlobalKey grants access to PageFlipWidget's state,
  final GlobalKey<PageFlipWidgetState> _pageFlipController =
      GlobalKey<PageFlipWidgetState>();

  //Stores the current page index.
  //The first story page has index 0, so the cover page
  //must have index -1.
  int currentPageIndex = -1;

  //Formats seconds into HH:MM:SS format.
  String formatTime(int seconds) {
    return '${(Duration(seconds: seconds))}'.split('.')[0].padLeft(8, '0');
  }

  //Sets the audio for both audio players.
  //This allows current page audio and background music to play
  //at the same time instead of interrupting each other.
  Future<void> setupAudioPlayers() async {
    //Creates an audio context that allows multiple
    //audio players to mix their sounds.
    final audioContext = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();

    //Applies the audio context to the preview page audio player
    //and background music audio player.
    await _audioPlayer.setAudioContext(audioContext);
    await _backgroundMusicAudioPlayer.setAudioContext(audioContext);
  }

  @override
  void initState() {
    super.initState();

    //Sets up page audio player and background music
    // audio player so they can play simultaneously.
    //The result is stored in to audioSetupFuture so startPageAudio()
    //can wait for the setup to finish.
    audioSetupFuture = setupAudioPlayers();

    //Initialization of Audio Listeners.

    //Listens for audio state changes (playing, paused).
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        //If the audio player state is 'playing',
        //isPlaying becomes true.
        //Otherwise, isPlaying becomes false.
        isPlaying = state == PlayerState.playing;
      });
    });

    //Listens for changes in the current page audio duration.
    _audioPlayer.onDurationChanged.listen((newDuration) {
      //Keeps the longest valid duration as the maximum duration
      //of the  audio slider.
      setState(() {
        duration = newDuration;
      });
    });

    //Listens for changes in the current page audio position.
    _audioPlayer.onPositionChanged.listen((newPosition) {
      //Updates the current slider position while the audio is being played.
      setState(() {
        position = newPosition;
      });
    });

    //Listens for when the current page audio finishes completely.
    _audioPlayer.onPlayerComplete.listen((event) async {
      //Resets the audio slider position back to the beginning.
      await _audioPlayer.seek(Duration.zero);

      //Stops audio and background music,
      //audio button returns to 'Play'.
      setState(() {
        isPlaying = false;
        isPaused = false;
        position = Duration.zero;
      });
    });
  }

  //Starts background music if it hasn't started yet.
  Future<void> startBackgroundMusic({
    //If background music was paused,
    //it can resume only if resumeIfPaused is true.
    required bool resumeIfPaused,
  }) async {
    //If there is no selected background music, the function stops.
    if (widget.story.backgroundMusic.isEmpty) {
      return;
    }

    //Waits until both audio players are ready to play.
    await audioSetupFuture;

    //If background music is paused,
    // it resumes only when resumeIfPaused is true.
    if (isBackgroundMusicPaused) {
      if (resumeIfPaused) {
        await _backgroundMusicAudioPlayer.resume();
        isBackgroundMusicPaused = false;
        isBackgroundMusicStarted = true;
      }
      return;
    }

    //If background music has already started,
    //the function stops so the music can continue.

    if (isBackgroundMusicStarted) {
      return;
    }
    //Makes background music loop during the story.
    await _backgroundMusicAudioPlayer.setReleaseMode(ReleaseMode.loop);

    //Lowers the background music volume.
    await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);

    //Starts the selected background music from assets.
    await _backgroundMusicAudioPlayer.play(
      AssetSource(widget.story.backgroundMusic),
    );

    //Sets background music as started.
    isBackgroundMusicStarted = true;
    isBackgroundMusicPaused = false;
  }

  //Stops only the current page audio.
  //The background music continues.
  Future<void> stopPageAudio() async {
    //Stops only the current age audio.
    await _audioPlayer.stop();

    //Resets only the page audio UI.
    setState(() {
      isPlaying = false;
      isPaused = false;
      duration = Duration.zero;
      position = Duration.zero;
    });
  }

  //Fades out the background music at the end of the story
  //and then stops it.
  Future<void> fadeOutBackgroundMusic() async {
    //If background music hasn't started yet, there is
    //nothing to stop. The function stops.
    if (!isBackgroundMusicStarted) {
      return;
    }

    //Number of background music volume decreases.
    const int fadeSteps = 10;

    //Duration between each volume decrease.
    const Duration fadeStepDuration = Duration(milliseconds: 100);

    //Gradually lowers the background music volume.
    for (int step = fadeSteps; step >= 0; step--) {
      await _backgroundMusicAudioPlayer.setVolume(
        backgroundMusicVolume * step / fadeSteps,
      );

      await Future.delayed(fadeStepDuration);
    }

    //Stops the background music completely.
    await _backgroundMusicAudioPlayer.stop();

    //Restore volume for the next time the story starts.
    await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);

    //Sets background music as stopped.
    isBackgroundMusicStarted = false;
    isBackgroundMusicPaused = false;
  }

  //Starts current page's audio.
  Future<void> startPageAudio() async {
    //If there are no pages, the function stops.
    if (widget.story.pages.isEmpty) {
      return;
    }

    //If the current page is the cover page or the 'END' page,
    //the function stops.
    if (currentPageIndex < 0 || currentPageIndex >= widget.story.pages.length) {
      return;
    }

    //Gets the audio path of the current page.
    final currentPageAudio = widget.story.pages[currentPageIndex].pageAudio;

    //If there is no audio path on the current page,
    //the function stops.
    if (currentPageAudio.isEmpty) {
      return;
    }

    //Waits until both audio players are ready to play together.
    await audioSetupFuture;

    //If the preview page audio was paused before,
    //resume the preview page audio and the background music.
    if (isPaused) {
      //Resumes the preview page audio from the paused position.
      await _audioPlayer.resume();

      //Resumes the background music if it was paused.
      if (widget.story.backgroundMusic.isNotEmpty) {
        await startBackgroundMusic(resumeIfPaused: true);
      }

      //Resets isPreviewPaused because the preview audio is no longer paused.
      setState(() {
        isPaused = false;
      });

      return;
    }

    //Stops only audio the current page audio
    //The background music continues.
    await stopPageAudio();

    //Starts or resumes the background music.
    //If it is already playing, it continues to play.
    await startBackgroundMusic(resumeIfPaused: true);

    //Plays the selected page audio from the local device file path.
    await _audioPlayer.play(DeviceFileSource(currentPageAudio));
  }

  //Pauses the current page audio.
  Future<void> pauseAudio() async {
    //Pauses the current audio.
    await _audioPlayer.pause();

    //Pauses the background music if it has started.
    if (isBackgroundMusicStarted) {
      await _backgroundMusicAudioPlayer.pause();
      isBackgroundMusicPaused = true;
    }

    //Sets the audio as paused.
    setState(() {
      isPaused = true;
    });
  }

  //Runs when the user swipes to another page.
  Future<void> swipePage(int pageNumber) async {
    //Checks if page audio was playing before changing page.
    //This is used to decide if the next page should play audio automatically.
    final bool autoplayMode = isPlaying;

    //Stops the current page audio before changing the page.
    //The background music continues to play between story pages.
    await stopPageAudio();

    //Check if a page is an actual story page
    //and not the cover page or the 'END' page.
    final bool isStoryPage =
        (pageNumber > 0 && pageNumber <= widget.story.pages.length);

    setState(() {
      //If the current page is the cover page or the 'END' page,
      //there is no audio to play.
      if (!isStoryPage) {
        currentPageIndex = -1;
      } else {
        //PageFlipWidget counts the cover page in its page number,
        //but in widget.story.pages the first story page has index 0,
        //so we subtract 1 from pageNumber.
        currentPageIndex = pageNumber - 1;
      }

      //Stops audio, audio button returns to 'Play'
      //and resets the audio slider position back to the beginning.
      isPlaying = false;
      isPaused = false;
      duration = Duration.zero;
      position = Duration.zero;
    });

    //If the current page is an actual story,
    //background music starts or continues.
    if (isStoryPage) {
      await startBackgroundMusic(resumeIfPaused: autoplayMode);

      //If audio was already playing before the page changed,
      //the new page audio starts automatically.
      if (autoplayMode) {
        await startPageAudio();
      }
    }
    //If the current page is the cover page or the 'END' page,
    //background music fades and stops.
    else {
      await fadeOutBackgroundMusic();
    }

    //????AUTOPLAY????
    //If the current page is a real story page (with audio),
    //starts the audio playback automatically.
    //if (currentPageIndex != -1) {
    //  await startPageAudio();
    //}
  }

  //Creates a visual book page for each story page.
  Widget _buildStoryBookPage(int pageIndex) {
    //Gets the current story page.
    final storyPage = widget.story.pages[pageIndex];
    return Container(
      //Ads space around the book page.
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        //Adds shadow under the page.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            //Shifts shadow by 8 pixels down.
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          //Makes all Stack children fill the container.
          fit: StackFit.expand,
          children: [
            //Story Page Image
            if (storyPage.pageImage.isNotEmpty)
              Image.file(File(storyPage.pageImage), fit: BoxFit.cover)
            else
              Container(
                color: Colors.teal.withValues(alpha: 0.08),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  size: 120,
                  color: Colors.teal,
                ),
              ),

            //Page Number.
            Positioned(
              right: 20,
              bottom: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pageIndex + 1}/${widget.story.pages.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverPage() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            //Story Page Image
            if (widget.story.coverImage.isNotEmpty)
              Image.file(
                File(widget.story.coverImage),
                //height: 260,
                //width: double.infinity,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: Colors.teal.withValues(alpha: 0.08),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.story.title,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    //Disposes the page audio player.
    _audioPlayer.dispose();
    //Disposes the background music audio player.
    _backgroundMusicAudioPlayer.dispose();
    //Calls parent dispose method to complete cleanup.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Same Background as the Home Page.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.story.title),
      ),

      body: widget.story.pages.isEmpty
          ? Center(
              child: Text(
                'This story has no pages.',
                style: const TextStyle(fontSize: 20),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Expanded(
                    child: PageFlipWidget(
                      key: _pageFlipController,

                      //Runs when a page is flipped.
                      onPageFlipped: swipePage,

                      //Book background color.
                      backgroundColor: Colors.brown,

                      lastPage: Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(
                          child: Text(
                            'The End',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                      ),
                      children: <Widget>[
                        //Book Cover Page.
                        _buildCoverPage(),

                        for (
                          int pageIndex = 0;
                          pageIndex < widget.story.pages.length;
                          pageIndex++
                        )
                          _buildStoryBookPage(pageIndex),
                      ],
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Play/Pause Button.
                      IconButton(
                        iconSize: 90,
                        color: Colors.orange,

                        //If the current page is the cover page or the 'END' page,
                        //the Play button is disabled.
                        onPressed: currentPageIndex == -1
                            ? null
                            : () {
                                if (isPlaying) {
                                  pauseAudio();
                                } else {
                                  startPageAudio();
                                }
                              },

                        icon: Icon(
                          //Changes dynamically the button icon between Play and Pause.
                          isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
