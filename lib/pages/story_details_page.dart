//Import Libraries
import 'dart:io';

//Import Packages
import 'package:digital_storytelling_app/pages/edit_story_page.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';

//My Imports
import 'button_styles.dart';
import '../models/story.dart';

//Displays details of the selected story and offers
//audio playback, story editing or deletion.
class StoryDetailsPage extends StatefulWidget {
  //Receives the selected story from previous page.
  final Story story;

  const StoryDetailsPage({super.key, required this.story});

  @override
  State<StoryDetailsPage> createState() => _StoryDetailsPageState();
}

class _StoryDetailsPageState extends State<StoryDetailsPage> {
  //Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  //Variable that shows if audio is playing or not.
  //It is used to switch between Play and Pause Buttons.
  bool isPlaying = false;

  //Total Audio Duration
  Duration duration = Duration.zero;

  //Audio position on Slider
  Duration position = Duration.zero;

  //Formats seconds into HH:MM:SS format.
  String formatTime(int seconds) {
    return '${(Duration(seconds: seconds))}'.split('.')[0].padLeft(8, '0');
  }

  //Calculates the total audio duration of all pages.
  int getTotalStoryDuration(Story story) {
    int totalDuration = 0;

    for (final page in story.pages) {
      totalDuration += page.pageAudioDuration;
    }
    return totalDuration;
  }

  //Returns the audio path of the first story page.
  String getFirstPageAudio() {
    if (widget.story.pages.isEmpty) {
      return '';
    }
    return widget.story.pages.first.pageAudio;
  }

  @override
  void initState() {
    super.initState();

    //Listens when audio playback is finished and
    //updates the button state.
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
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
      if (newDuration.inSeconds > duration.inSeconds) {
        setState(() {
          duration = newDuration;
        });
      }
    });

    //Updates the current slider position
    //while the audio is being played
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
  }

  //Starts audio playback.
  Future<void> startAudio() async {
    final audioPath = getFirstPageAudio();

    //Checks if there is no audio in the selected story.
    if (audioPath.isEmpty) {
      //print ('No Audio Found');
      return;
    }
    //Loads and starts the audio playback
    await _audioPlayer.play(DeviceFileSource(audioPath));

    //Updates UI and sets isPlaying as true.
    //setState(() {
    // isPlaying=true;
    //});
  }

  //Pauses audio playback.
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();

    //Updates UI and sets isPlaying as true.
    //setState(() {
    //  isPlaying=false;
    //});
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

  //Shares stories
  Future<void> shareStory() async {
    final audioPath = getFirstPageAudio();

    //Checks if story has no audio.
    if (audioPath.isEmpty) {
      return;
    }

    //Shares the story files using the device share menu.
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(audioPath)],
        text: 'Listen to my story: ${widget.story.title}',
      ),
    );
  }

  @override
  void dispose() {
    //Frees memory from audio player
    _audioPlayer.dispose();
    //Calls parent class dispose method to complete cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Uses the same app bar background color as the rest of the app.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        //Displays Story's title on the app bar.
        title: Text(widget.story.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          //Adds spacing so the UI doesn't touch the screen borders.
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //Column stretches widgets vertically.
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              //Cover Image Preview
              if (widget.story.coverImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.file(
                    File(widget.story.coverImage),
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

              //Displays Story Title.
              Text(
                widget.story.title,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              //Displays Story Pages.
              Text(
                'Pages: ${widget.story.pages.length}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
                        startAudio();
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

              const SizedBox(height: 5),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Story Edit Button
                  Expanded(
                    child: ElevatedButton(
                      //Imported button style.
                      style: ButtonStyles.tealButton,

                      onPressed: () async {
                        //Opens EditStoryPage and wait for the updated Story.
                        final updatedStory = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditStoryPage(story: widget.story),
                          ),
                        );

                        //If the story is updated,
                        // returns the updated story to the previous page.
                        if (updatedStory != null) {
                          Navigator.pop(context, updatedStory);
                        }
                      },

                      child: const Text('Edit Story'),
                    ),
                  ),
                  const SizedBox(width: 16),

                  /*
                //Story Share Button
                Expanded(
                child: ElevatedButton(
                style: ButtonStyles.tealButton,

                onPressed: () async{

                },
                child: const Text('Share Story'),
                ),
                ),
                const SizedBox(width: 16),
               */
                  //Story Deletion Button
                  Expanded(
                    child: ElevatedButton(
                      style: ButtonStyles.deleteButton,

                      onPressed: () async {
                        //Displays delete confirmation dialog.
                        bool? confirmDelete = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('Delete Story'),
                            content: Text(
                              'Are you sure you want to delete this story?',
                            ),
                            actions: [
                              //Cancel deletion button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text('Cancel'),
                              ),

                              //Confirm deletion button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        //If story deletion is confirmed,
                        //returns delete 'action' message to the previous page
                        if (confirmDelete == true) {
                          Navigator.pop(context, 'delete');
                        }
                      },
                      child: const Text('Delete Story'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
