//Library Imports
import 'dart:io';
import 'dart:async';

//Package Imports
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:page_flip/page_flip.dart';

//My Imports
import '../models/story.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/story_book_cover.dart';

//Defines the mode from which the Story Page was opened.
//It is used to decide the AppBar colour.
enum StoryTimeMode { parent, child }

class StoryTimePage extends StatefulWidget {
  final Story story;
  final StoryTimeMode mode;

  const StoryTimePage({super.key, required this.story, required this.mode});

  @override
  State<StoryTimePage> createState() => _StoryTimePageState();
}

class _StoryTimePageState extends State<StoryTimePage> {
  //Page audio player.
  final AudioPlayer _audioPlayer = AudioPlayer();

  //Background music audio player.
  final AudioPlayer _backgroundMusicAudioPlayer = AudioPlayer();

  //Listens for page audio player state changes.
  StreamSubscription<PlayerState>? playerStateSubscription;

  //Listens for when the page audio is completed.
  StreamSubscription<void>? playerCompleteSubscription;

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

  //Checks if a page flip is currently in progress.
  bool isPageTurning = false;

  //Controls the page recording voice volume.
  static const double pageAudioVolume = 1.0;

  //Controls the background music volume.
  static const double backgroundMusicVolume = 0.04;

  //Checks if automatic page turning is enabled.
  bool isAutoplayEnabled = false;

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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    await _backgroundMusicAudioPlayer.setAudioContext(audioContext);
  }

  @override
  void initState() {
    super.initState();

    //Sets up page audio player and background music
    // audio player so they can play simultaneously.
    //The result is stored in audioSetupFuture so startPageAudio()
    //can wait for the setup to finish.
    audioSetupFuture = setupAudioPlayers();

    //Initialization of Audio Listeners.

    //Listens for audio state changes (playing, paused).
    playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      setState(() {
        //If the audio player state is 'playing',
        //isPlaying becomes true.
        //Otherwise, isPlaying becomes false.
        isPlaying = state == PlayerState.playing;
      });
    });

    //Listens for when the current page audio finishes completely.
    playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((
      _,
    ) async {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If background music is paused,
    // it resumes only when resumeIfPaused is true.
    if (isBackgroundMusicPaused) {
      if (resumeIfPaused) {
        await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);

        //Stops the function if the page is no longer active.
        if (!mounted) {
          return;
        }

        await _backgroundMusicAudioPlayer.resume();

        //Stops the function if the page is no longer active.
        if (!mounted) {
          return;
        }
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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Lowers the background music volume.
    await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Starts the selected background music from assets.
    await _backgroundMusicAudioPlayer.play(
      AssetSource(widget.story.backgroundMusic),
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Sets background music as started.
    isBackgroundMusicStarted = true;
    isBackgroundMusicPaused = false;
  }

  //Stops only the current page audio.
  //The background music continues.
  Future<void> stopPageAudio() async {
    //Stops only the current page audio.
    await _audioPlayer.stop();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

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
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //If the user returns to an actual story page,
      //the fade-out stops and the normal volume is restored.
      if (currentPageIndex >= 0 &&
          currentPageIndex < widget.story.pages.length) {
        await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);
        return;
      }
      await _backgroundMusicAudioPlayer.setVolume(
        backgroundMusicVolume * step / fadeSteps,
      );
      await Future.delayed(fadeStepDuration);
    }

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Checks again before stopping the background music.
    if (currentPageIndex >= 0 && currentPageIndex < widget.story.pages.length) {
      await _backgroundMusicAudioPlayer.setVolume(backgroundMusicVolume);
      return;
    }

    //Stops the background music completely.
    await _backgroundMusicAudioPlayer.stop();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the page audio was paused before,
    //resume the page audio and the background music.
    if (isPaused) {
      //Sets the page recording voice volume.
      await _audioPlayer.setVolume(pageAudioVolume);

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Resumes the page audio from the paused position.
      await _audioPlayer.resume();

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Resumes the background music if it was paused.
      if (widget.story.backgroundMusic.isNotEmpty) {
        await startBackgroundMusic(resumeIfPaused: true);
      }

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Resets isPaused and isPlaying because the audio is no longer being played.
    setState(() {
      isPlaying = false;
      isPaused = false;
    });

    //Starts or resumes the background music.
    //If it is already playing, it continues to play.
    await startBackgroundMusic(resumeIfPaused: true);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Sets the page recording voice volume.
    await _audioPlayer.setVolume(pageAudioVolume);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Plays the selected page audio from the local device file path.
    await _audioPlayer.play(DeviceFileSource(currentPageAudio));

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

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

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Pauses the background music if it has started.
    if (isBackgroundMusicStarted) {
      await _backgroundMusicAudioPlayer.pause();

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

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
    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

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

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      isBackgroundMusicPaused = true;
    }
  }

  //Runs when the user swipes to another page.
  Future<void> swipePage(int pageNumber) async {
    //Stops the current page audio before changing the page.
    //The background music continues to play between story pages.
    await stopPageAudio();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

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
      //and resets the audio button to 'Play'.
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

    //Prevents multiple page flips at the same time.
    if (isPageTurning) {
      return;
    }

    isPageTurning = true;

    try {
      //Moves the PageFlipWidget to the previous page.
      await _pageFlipController.currentState?.previousPage();
    } finally {
      //Allows another page flip after the current one is finished.
      isPageTurning = false;
    }
  }

  //Moves the story book to the next page.
  Future<void> goToNextPage() async {
    //If the current page is the "THE END" page, the function stops.
    if (currentPageIndex >= widget.story.pages.length) {
      return;
    }

    //Prevents multiple page flips at the same time.
    if (isPageTurning) {
      return;
    }

    isPageTurning = true;

    try {
      //Moves the PageFlipWidget to the next page.
      await _pageFlipController.currentState?.nextPage();
    } finally {
      //Allows another page flip after the current one is finished.
      isPageTurning = false;
    }
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
                      color: AppColors.bookPageCream,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 100,
                        color: AppColors.bookBrown,
                      ),
                    );
                  },
                )
              else
                Container(
                  color: AppColors.bookPageCream,
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 120,
                    color: AppColors.bookBrown,
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

  //Creates a full size story book cover.
  Widget _buildCoverPage() {
    return StoryBookCover(
      title: widget.story.title,
      imagePath: widget.story.coverImage,
      imageCacheWidth: calculateStoryImageCacheWidth(),
    );
  }

  //Creates the final book page.
  Widget _buildEndPage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bookDarkBrown,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        //Adds space around the book page.
        margin: const EdgeInsets.all(8),

        //Outer frame thickness.
        padding: const EdgeInsets.all(8),

        decoration: BoxDecoration(
          color: AppColors.bookDarkBrown,

          //Outer line border.
          border: Border.all(color: AppColors.bookBrown, width: 3),
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
            color: AppColors.bookDarkBrown,
            borderRadius: BorderRadius.circular(10),
            //Inner line border.
            border: Border.all(color: AppColors.bookBrown, width: 2),
          ),

          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 90,
                  color: AppColors.bookCream,
                ),
                SizedBox(height: 20),
                Text(
                  'The End',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: AppColors.bookCream,
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
  //Cleans memory when Page closes.
  void dispose() {
    //Stops listening to audio events.
    playerStateSubscription?.cancel();
    playerCompleteSubscription?.cancel();

    //Disposes the page audio player.
    _audioPlayer.dispose();
    //Disposes the background music audio player.
    _backgroundMusicAudioPlayer.dispose();
    //Calls parent dispose method to complete cleanup.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Story Time',
          foregroundColor: Colors.white,
          textColor: Colors.white,
          backgroundColor: widget.mode == StoryTimeMode.child
              ? AppColors.childMode
              : AppColors.parentMode,
        ),
        body: SafeArea(
          //the AppBar already protects the top system area so top:false.
          top: false,
          child: widget.story.pages.isEmpty
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
                      //Story Book Section Card.
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

                      //Story Controls Section Card.
                      SectionCard(
                        sectionCardMargin: EdgeInsets.zero,
                        sectionCardPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),

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
                                    backgroundColor: AppColors.parentPrimary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.disabled,
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
                                      backgroundColor: AppColors.childMode,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor:
                                          AppColors.disabled,
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
                                    backgroundColor: AppColors.parentPrimary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: AppColors.disabled,
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
                              color:
                                  currentPageIndex >= widget.story.pages.length
                                  ? AppColors.disabled
                                  : isAutoplayEnabled
                                  ? AppColors.bookBrown
                                  : AppColors.bookDarkBrown,

                              border: Border.all(
                                color:
                                    currentPageIndex >=
                                        widget.story.pages.length
                                    ? AppColors.disabled
                                    : isAutoplayEnabled
                                    ? AppColors.bookDarkBrown
                                    : AppColors.bookBrown,
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
                                    currentPageIndex >=
                                        widget.story.pages.length
                                    ? Colors.white
                                    : AppColors.bookCream,
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
                                      : AppColors.bookCream,
                                ),
                              ),

                              activeThumbColor: AppColors.bookCream,
                              activeTrackColor: AppColors.bookDarkBrown,
                              inactiveThumbColor:
                                  currentPageIndex >= widget.story.pages.length
                                  ? Colors.white
                                  : AppColors.bookCream,
                              inactiveTrackColor:
                                  currentPageIndex >= widget.story.pages.length
                                  ? AppColors.disabled
                                  : AppColors.bookBrown,

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
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
