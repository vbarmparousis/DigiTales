//Import Packages
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

//My Imports
import '../models/story.dart';

class ChildStoryPage extends StatefulWidget {
  final Story story;

  const ChildStoryPage({super.key, required this.story});

  @override
  State<ChildStoryPage> createState() => _ChildStoryPageState();
}

class _ChildStoryPageState extends State<ChildStoryPage> {
  //Create audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  //Variable that shows if audio is playing or not.
  //It is used to switch between Play and Pause Buttons.
  bool isPlaying = false;

  //Total Audio Duration
  Duration duration = Duration.zero;

  //Audio position on Slider
  Duration position = Duration.zero;

  //Controls the swipe pages
  final PageController _pageController = PageController();

  //Stores the current page index
  int currentPageIndex = 0;

  //Formats seconds into HH:MM:SS format.
  String formatTime(int seconds) {
    return '${(Duration(seconds: seconds))}'.split('.')[0].padLeft(8, '0');
  }

  //Initialization of Audio Listeners
  @override
  void initState() {
    super.initState();
    //Audio Listener that detects when audio finishes completely.
    _audioPlayer.onPlayerComplete.listen((event) {
      //Stops audio and resets the slider position.
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
      _audioPlayer.seek(Duration.zero);
    });

    //Listens for audio state changes (playing, paused or stopped.)
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        //???Checks if the current audio player is playing.
        isPlaying = state == PlayerState.playing;
      });
    });

    //Audio Listener that detects changes on audio duration
    _audioPlayer.onDurationChanged.listen((newDuration) {
      //Keeps the longest valid duration.

      setState(() {
        duration = newDuration;
      });
    });

    //Updates the current slider position
    //while the audio is being played
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  //Starts current page's audio.
  Future<void> startPageAudio() async {
    //Checks if story has no pages.
    if (widget.story.pages.isEmpty) {
      return;
    }

    //Gets the current page's audio path.
    final currentPageAudio = widget.story.pages[currentPageIndex].pageAudio;

    //Checks if current page's audio is empty.
    //If it is empty, the audio stops.
    if (currentPageAudio.isEmpty) {
      return;
    }

    //Loads and starts current page's audio.
    await _audioPlayer.play(DeviceFileSource(currentPageAudio));
  }

  Future<void> pauseAudio() async {
    //Pauses the current audio.
    await _audioPlayer.pause();
  }

  //Runs when the user swipes to another page.
  Future<void> swipePage(int index) async {
    //Stops the current audio.
    await _audioPlayer.stop();

    setState(() {
      currentPageIndex = index;
      isPlaying = false;
      duration = Duration.zero;
      position = Duration.zero;
    });
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

  @override
  void dispose() {
    //Free memory from audio player
    _audioPlayer.dispose();

    //Free memory from page controller
    _pageController.dispose();

    //Calls parent class dispose method to complete cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Same Background as the Home Page
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.story.title),
      ),

      body: widget.story.pages.isEmpty
          ? const Center(
              child: Text(
                'This story has no pages.',
                style: TextStyle(fontSize: 20),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.story.pages.length,
                      onPageChanged: swipePage,

                      itemBuilder: (context, index) {
                        final storyPage = widget.story.pages[index];

                        return Column(
                          children: [
                            //Story Page Image
                            if (storyPage.pageImage.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.file(
                                  File(storyPage.pageImage),
                                  height: 260,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              Container(
                                height: 260,
                                //Container takes full width.
                                width: double.infinity,

                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black,
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),

                                child: const Icon(
                                  Icons.headphones_rounded,
                                  size: 150,
                                  color: Colors.teal,
                                ),
                              ),
                            const SizedBox(height: 32),
                            Text(
                              widget.story.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Page ${index + 1} of ${widget.story.pages.length}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        );
                      },
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
                        onPressed: skipBackward,
                        icon: const Icon(Icons.replay_10_rounded),
                      ),

                      const SizedBox(width: 20),

                      //Play/Pause Button.
                      IconButton(
                        iconSize: 90,
                        color: Colors.orange,
                        onPressed: () {
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
                        onPressed: skipForward,
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
