//Import Libraries
import 'dart:io';
import 'dart:async';

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

  //Checks if the background music is paused.
  bool isBackgroundMusicPaused = false;

  //Controls the page recording voice volume.
  static const double pageAudioVolume = 1.0;

  //Controls the background music volume.
  static const double backgroundMusicVolume = 0.05;

  //Checks if automatic page turning is enabled.
  bool isAutoplayEnabled = false;

  //Book UI colors.
  static const Color bookBrown = Color(0xFF8A5A2B);
  static const Color bookDarkBrown = Color(0xFF4A2A12);
  static const Color bookCream = Color(0xFFFFF1D0);
  static const Color bookPageCream = Color(0xFFFFFAEC);

  //Controls the page flip widget
  //GlobalKey grants access to PageFlipWidget's state.
  final GlobalKey<PageFlipWidgetState> _pageFlipController =
      GlobalKey<PageFlipWidgetState>();

  //Stores the current page index:
  //Cover page: -1.
  //Real story pages: from 0 to (story.pages.length-1).
  //"THE END" page: story.pages.length.
  int currentPageIndex = -1;

  //Sets the audio for both audio players.
  //This allows current page audio and background music to play
  //at the same time instead of interrupting each other.
  Future<void> setupAudioPlayers() async {
    //Creates an audio context that allows multiple
    //audio players to mix their sounds.
    final audioContext = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();

    //Applies the audio context to the page audio player
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

    //Listens for when the current page audio finishes completely.
    _audioPlayer.onPlayerComplete.listen((_) async {
      await handlePageAudioComplete();
    });
  }

  //Calculates a suitable decoding width for both phones and tablets.
  int calculateStoryImageCacheWidth() {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    //Converts the screen width from logical pixels to physical pixels
    final int physicalScreenWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).round();

    return physicalScreenWidth.clamp(1200, 2048).toInt();
  }

  //Creates the same resized provider for displaying and precaching images.
  ImageProvider<Object> getStoryImageProvider(String imagePath) {
    return ResizeImage.resizeIfNeeded(
      calculateStoryImageCacheWidth(),
      null,
      FileImage(File(imagePath)),
    );
  }

  //Precaches a small group of images without blocking the story page.
  //This helps prevent white flashing when a page image is shown
  //for the first time during the page flip animation.
  Future<void> precacheImagePaths(Iterable<String> imagePaths) async {
    //Removes duplicate and empty paths.
    final Set<String> validPaths = imagePaths
        .where((imagePath) => imagePath.isNotEmpty)
        .toSet();

    for (final imagePath in validPaths) {
      if (!mounted) {
        return;
      }

      final imageFile = File(imagePath);

      if (!imageFile.existsSync()) {
        continue;
      }
      try {
        await precacheImage(getStoryImageProvider(imagePath), context);
      } catch (_) {
        //The story can still open if an image can't be decoded.
      }
    }
  }

  //Prepares the pages near the current page.
  Future<void> precacheNearbyPages(int currentIndex) async {
    if (widget.story.pages.isEmpty) {
      return;
    }
    final List<String> nearbyImagePaths = [];

    //Prepares the previous page, current page and the next two story pages.
    for (
      int pageIndex = currentIndex - 1;
      pageIndex <= currentIndex + 2;
      pageIndex++
    ) {
      if (pageIndex >= 0 && pageIndex < widget.story.pages.length) {
        nearbyImagePaths.add(widget.story.pages[pageIndex].pageImage);
      }
    }
    await precacheImagePaths(nearbyImagePaths);
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
        await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);
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
    //Stops only the current page audio.
    await _audioPlayer.stop();

    //Resets only the page audio UI.
    setState(() {
      isPlaying = false;
      isPaused = false;
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

  //Starts or Resumes the current page's audio.
  Future<void> startPageAudio() async {
    //If there are no pages, the function stops.
    if (widget.story.pages.isEmpty) {
      return;
    }

    //If the current page is the cover page or the 'The End' page,
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

    //If the page audio was paused before,
    //resume the page audio and the background music.
    if (isPaused) {
      //Sets the page recording voice volume.
      await _audioPlayer.setVolume(pageAudioVolume);

      //Resumes the page audio from the paused position.
      await _audioPlayer.resume();

      //Resumes the background music if it was paused.
      if (widget.story.backgroundMusic.isNotEmpty) {
        await startBackgroundMusic(resumeIfPaused: true);
      }

      //Resets isPaused and isPlaying because the audio is no longer paused.
      setState(() {
        isPaused = false;
        isPlaying = true;
      });

      return;
    }

    //Stops only the current page audio
    //The background music continues.
    await _audioPlayer.stop();

    //Resets isPaused and isPlaying because the audio is no longer being played.
    setState(() {
      isPlaying = false;
      isPaused = false;
    });

    //Starts or resumes the background music.
    //If it is already playing, it continues to play.
    await startBackgroundMusic(resumeIfPaused: true);

    //Sets the page recording voice volume.
    await _audioPlayer.setVolume(pageAudioVolume);

    //Plays the selected page audio from the local device file path.
    await _audioPlayer.play(DeviceFileSource(currentPageAudio));

    //Resets isPaused and isPlaying because the audio is no longer paused.
    setState(() {
      isPlaying = true;
      isPaused = false;
    });
  }

  //Pauses the current page audio and the background music.
  Future<void> pauseAudio() async {
    //Pauses the current page audio.
    await _audioPlayer.pause();

    //Pauses the background music if it has started.
    if (isBackgroundMusicStarted) {
      await _backgroundMusicAudioPlayer.pause();
      isBackgroundMusicPaused = true;
    }

    //Sets the audio as paused.
    setState(() {
      isPlaying = false;
      isPaused = true;
    });
  }

  //Runs when the current page audio finishes.
  Future<void> handlePageAudioComplete() async {
    //Stops audio and background music,
    //audio button returns to 'Play'.
    setState(() {
      isPlaying = false;
      isPaused = false;
    });

    //If Auto Play is enabled, continues automatically to the next page.
    if (isAutoplayEnabled) {
      await goToNextPage();
      return;
    }

    //If Auto Play is off, the background music pauses,
    // if it has already started.
    if (isBackgroundMusicStarted) {
      await _backgroundMusicAudioPlayer.pause();
      isBackgroundMusicPaused = true;
    }
  }

  //Runs when the user swipes to another page.
  Future<void> swipePage(int pageNumber) async {
    //Stops the current page audio before changing the page.
    //The background music continues to play between story pages.
    await stopPageAudio();

    //Check if a page is an actual story page
    //and not the cover page or the 'The End' page.
    final bool isStoryPage =
        (pageNumber > 0 && pageNumber <= widget.story.pages.length);

    setState(() {
      //If the current page is the cover page,
      //there is no audio to play.
      if (pageNumber == 0) {
        currentPageIndex = -1;
      }
      //If the current page is the 'The End' page,
      //there is no audio to play.
      else if (pageNumber > widget.story.pages.length) {
        currentPageIndex = widget.story.pages.length;

        //Turns off Auto Play.
        isAutoplayEnabled = false;
      }
      //If the current page is a real story page, it contains audio.
      else {
        //PageFlipWidget counts the cover page in its page number,
        //but in widget.story.pages the first story page has index 0,
        //so we subtract 1 from pageNumber.
        currentPageIndex = pageNumber - 1;
      }

      //Stops audio, audio button returns to 'Play'
      //and resets the audio slider position back to the beginning.
      isPlaying = false;
      isPaused = false;
    });

    //Prepares nearby page images in the background.
    if (currentPageIndex >= 0 && currentPageIndex < widget.story.pages.length) {
      unawaited(precacheNearbyPages(currentPageIndex));
    }

    //If the current page is an actual story page,
    //the audio starts automatically.
    if (isStoryPage) {
      await startPageAudio();
    }
    //If the current page is the cover page or the 'The End' page,
    //background music fades and stops.
    else {
      await fadeOutBackgroundMusic();
    }
  }

  //Moves the story book to the previous page.
  Future<void> goToPreviousPage() async {
    //If the current page is the cover page, the function stops.
    if (currentPageIndex <= -1) {
      return;
    }

    //Moves the PageFlipWidget to the previous page.
    await _pageFlipController.currentState?.previousPage();
  }

  //Moves the story book to the next page.
  Future<void> goToNextPage() async {
    //If the current page is the "THE END" page, the function stops.
    if (currentPageIndex >= widget.story.pages.length) {
      return;
    }

    //Moves the PageFlipWidget to the next page.
    await _pageFlipController.currentState?.nextPage();
  }

  //Creates a visual book page for each story page.
  Widget _buildStoryBookPage(int pageIndex) {
    //Gets the current story page.
    final storyPage = widget.story.pages[pageIndex];

    return Container(
      //Adds space around the book page.
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 18),

      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      //Black frame on all sides.
      child: Padding(
        padding: const EdgeInsets.all(3.5),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            //Makes all Stack children fill the container.
            fit: StackFit.expand,
            children: [
              //Story Page Image.
              if (storyPage.pageImage.isNotEmpty)
                Image(
                  image: getStoryImageProvider(storyPage.pageImage),
                  fit: BoxFit.cover,
                  //Keeps the currently displayed image frame while Flutter
                  //resolves the image provider during rebuild.
                  gaplessPlayback: true,

                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: bookPageCream,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 100,
                        color: bookBrown,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: bookPageCream,
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 120,
                    color: bookBrown,
                  ),
                ),

              //Adds shadow overlay on the lower part of the page
              //so that the page number is easier to see.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
              ),

              //Page Number.
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPage() {
    return Container(
      //Cover page is bigger than the actual story pages.
      margin: const EdgeInsets.all(8),

      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color: bookDarkBrown,

        //Outer line border.
        border: Border.all(color: bookBrown, width: 4),

        borderRadius: BorderRadius.circular(10),

        //Adds shadow under the page.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Container(
        decoration: BoxDecoration(
          color: bookDarkBrown,
          borderRadius: BorderRadius.circular(10),
          //Inner line border.
          border: Border.all(color: bookBrown, width: 2),
        ),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              //Story Page Image.
              if (widget.story.coverImage.isNotEmpty)
                Image(
                  image: getStoryImageProvider(widget.story.coverImage),
                  fit: BoxFit.cover,

                  //Keeps the cover image frame while Flutter
                  //resolves the image provider during rebuild.
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: bookDarkBrown,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 100,
                        color: bookCream,
                      ),
                    );
                  },
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
      ),
    );
  }

  //Creates the final book page.
  Widget _buildEndPage() {
    return Container(
      decoration: BoxDecoration(
        color: bookDarkBrown,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        //Adds space around the book page.
        margin: const EdgeInsets.all(8),

        //Outer frame thickness.
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: bookDarkBrown,

          //Outer line border.
          border: Border.all(color: bookBrown, width: 3),
          borderRadius: BorderRadius.circular(10),

          //Adds shadow under the page.
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bookDarkBrown,
            borderRadius: BorderRadius.circular(10),
            //Inner line border.
            border: Border.all(color: bookBrown, width: 2),
          ),

          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, size: 90, color: bookCream),
                SizedBox(height: 20),
                Text(
                  'The End',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: bookCream,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Builds the story book section.
  Widget _buildStoryBookSection() {
    return PageFlipWidget(
      key: _pageFlipController,

      //Runs when a page is flipped.
      onPageFlipped: swipePage,

      //Book background color.
      backgroundColor: Colors.transparent,

      lastPage: _buildEndPage(),
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
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),

                      child: _buildStoryBookSection(),
                    ),
                  ),

                  Container(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            //Previous Page Button.
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                //If the current page is the cover page,
                                //the button is disabled.
                                onPressed: currentPageIndex <= -1
                                    ? null
                                    : goToPreviousPage,
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  size: 36,
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            //Main Play/Pause Button.
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey,
                                    disabledForegroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),

                                  //If the current page is the cover page or the 'The End' page,
                                  //the Play button is disabled.
                                  onPressed:
                                      currentPageIndex < 0 ||
                                          currentPageIndex >=
                                              widget.story.pages.length
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
                                    size: 34,
                                  ),
                                  label: Text(
                                    isPlaying ? 'Pause' : 'Play',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            //Next Page Button.
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  disabledForegroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                //If the current page is the "THE END" page,
                                //the button is disabled.
                                onPressed:
                                    currentPageIndex >=
                                        widget.story.pages.length
                                    ? null
                                    : goToNextPage,
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 36,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        //Auto Play Switch.
                        Container(
                          height: 54,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: currentPageIndex >= widget.story.pages.length
                                ? Colors.grey
                                : isAutoplayEnabled
                                ? bookBrown
                                : bookDarkBrown,

                            border: Border.all(
                              color:
                                  currentPageIndex >= widget.story.pages.length
                                  ? Colors.grey
                                  : isAutoplayEnabled
                                  ? bookDarkBrown
                                  : bookBrown,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: SwitchListTile(
                            //Current Auto Play state.
                            value: isAutoplayEnabled,

                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),

                            //Auto Play icon.
                            secondary: Icon(
                              Icons.auto_awesome_rounded,
                              color:
                                  currentPageIndex >= widget.story.pages.length
                                  ? Colors.white
                                  : bookCream,
                            ),

                            //Auto Play text.
                            title: Text(
                              currentPageIndex >= widget.story.pages.length
                                  ? 'Auto Play: Disabled'
                                  : isAutoplayEnabled
                                  ? 'Auto Play: On'
                                  : 'Auto Play: Off',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    currentPageIndex >=
                                        widget.story.pages.length
                                    ? Colors.white
                                    : bookCream,
                              ),
                            ),

                            activeThumbColor: bookCream,
                            activeTrackColor: bookDarkBrown,
                            inactiveThumbColor:
                                currentPageIndex >= widget.story.pages.length
                                ? Colors.white
                                : bookCream,
                            inactiveTrackColor:
                                currentPageIndex >= widget.story.pages.length
                                ? Colors.grey
                                : bookBrown,

                            //The Auto Play Switch is disabled on the "The END" page.
                            onChanged:
                                currentPageIndex >= widget.story.pages.length
                                ? null
                                : (bool value) async {
                                    //Updates Auto Play using the switch value.
                                    setState(() {
                                      isAutoplayEnabled = value;
                                    });

                                    //If Auto Play was turned off, keeps the same current audio state.
                                    if (!isAutoplayEnabled) {
                                      return;
                                    }

                                    //If Auto Play starts while the current page is the cover page,
                                    //moves the story to the first actual story page.
                                    if (currentPageIndex == -1) {
                                      await goToNextPage();
                                      return;
                                    }

                                    //If Auto Play starts while the current page is an actual story page
                                    //and audio is not playing, starts or resumes the current page audio.
                                    if (currentPageIndex >= 0 &&
                                        currentPageIndex <
                                            widget.story.pages.length &&
                                        !isPlaying) {
                                      await startPageAudio();
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
