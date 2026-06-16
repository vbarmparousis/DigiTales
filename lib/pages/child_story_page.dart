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

  //Checks if the current page audio is being played.
  //It is used to switch between Play and Pause buttons.
  bool isPlaying = false;

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

  @override
  void initState() {
    super.initState();

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
    _audioPlayer.onPlayerComplete.listen((event) {
      //Stops audio, audio button returns to 'Play'
      //and resets the audio slider position back to the beginning.
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
      _audioPlayer.seek(Duration.zero);
    });
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

    //Plays the current page audio from the local device file path.
    await _audioPlayer.play(DeviceFileSource(currentPageAudio));
  }

  //Pauses the current page audio.
  Future<void> pauseAudio() async {
    //Pauses the current audio.
    await _audioPlayer.pause();
  }

  //Runs when the user swipes to another page.
  Future<void> swipePage(int pageNumber) async {
    //Stops the current audio.
    await _audioPlayer.stop();

    setState(() {
      //If the current page is the cover page or the 'END' page,
      //there is no audio to play.
      if (pageNumber <= 0 || pageNumber > widget.story.pages.length) {
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
      duration = Duration.zero;
      position = Duration.zero;
    });

    //If the current page is a real story page (with audio),
    //starts the audio playback automatically.
    if (currentPageIndex != -1) {
      await startPageAudio();
    }
  }

  //Skips audio 10 seconds backwards.
  Future<void> skipBackward() async {
    //Calculate new position.
    final newPosition = position - Duration(seconds: 10);

    //Prevents negative duration values.
    await _audioPlayer.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  //Skips audio 10 seconds forwards.
  Future<void> skipForward() async {
    //Calculate new position.
    final newPosition = position + Duration(seconds: 10);

    //Prevents skipping past the audio duration.
    await _audioPlayer.seek(newPosition > duration ? duration : newPosition);
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
    //Free memory from audio player.
    _audioPlayer.dispose();

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

                  //Audio Player Slider
                  Slider(
                    min: 0,
                    max: duration.inSeconds.toDouble() > 0
                        ? duration.inSeconds.toDouble()
                        : 1,
                    //clamp() prevents slider from
                    //exceeding duration limits.
                    value: position.inSeconds.toDouble().clamp(
                      0,
                      duration.inSeconds.toDouble() > 0
                          ? duration.inSeconds.toDouble()
                          : 1,
                    ),

                    activeColor: Colors.teal,
                    inactiveColor: Colors.grey,

                    onChanged: (value) async {
                      //Allows jumping to another position on slider.
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(position.inSeconds)),
                      Text(
                        formatTime(
                          (duration - position).inSeconds.clamp(
                            0,
                            duration.inSeconds,
                          ),
                        ),
                      ),
                    ],
                  ),

                  //const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Skip Backward Button.
                      IconButton(
                        iconSize: 60,
                        color: Colors.teal,
                        //If the current page is the cover page or the 'END' page,
                        //the Skip Backward button is disabled.
                        onPressed: currentPageIndex == -1 ? null : skipBackward,
                        icon: const Icon(Icons.replay_10_rounded),
                      ),

                      const SizedBox(width: 20),

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

                      const SizedBox(width: 20),

                      //Skip Forward Button.
                      IconButton(
                        iconSize: 60,
                        color: Colors.teal,
                        //If the current page is the cover page or the 'END' page,
                        //the Skip Forward button is disabled.
                        onPressed: currentPageIndex == -1 ? null : skipForward,
                        icon: const Icon(Icons.forward_10_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
