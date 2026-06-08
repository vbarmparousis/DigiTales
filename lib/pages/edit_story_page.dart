//Import Packages
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

//My Imports
import 'button_styles.dart';
import '../models/story.dart';

class EditStoryPage extends StatefulWidget {
  //Holds the story object from the previous page
  final Story story;

  //Page Constructor Creation.
  //It requires a Story Object from previous Page.
  const EditStoryPage({super.key, required this.story});

  @override
  State<EditStoryPage> createState() => _EditStoryPageState();
}

//Private Class (underscore: _)
class _EditStoryPageState extends State<EditStoryPage> {
  //Holds the Title of the Story
  final TextEditingController _titleController = TextEditingController();

  //Audio Recorder
  final AudioRecorder _audioRecorder = AudioRecorder();

  //ImagePicker allows to pick an image from gallery.
  final ImagePicker imagePicker = ImagePicker();

  //Stores the local file path of the selected image.
  String coverImagePath = '';

  //Boolean that checks if audio is being recorded.
  bool isRecording = false;

  //String that holds the local directory path
  //where the recorded audio file will be saved.
  String audioPath = '';

  //Stores audio duration in seconds.
  int audioDuration = 0;

  //Timer that updates recording duration.
  Timer? recordingTimer;

  //Stores current recording duration.
  int recordingSeconds = 0;

  String formatRecordingTime(int seconds) {
    return Duration(
      seconds: seconds,
    ).toString().split('.').first.padLeft(8, '0');
  }

  //Opens device gallery and allows
  //user to pick a cover image for the story.
  Future<void> pickCoverImage() async {
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
      return;
    }

    //Stores the selected image file path and updates the UI.
    setState(() {
      coverImagePath = selectedImage.path;
    });
  }

  //Starts Audio Recording
  Future<void> startRecording() async {
    //Prevents the start of another recording while
    //an audio is already being recorded.
    if (isRecording) return;

    //Waits for microphone permission before starting recording.
    if (await _audioRecorder.hasPermission()) {
      //Permission granted, proceed with recording

      //Gets the application's local document directory.
      final directory = await getApplicationDocumentsDirectory();
      //print('Path=============================: ${directory.path}');

      //Replaces special character in the date in order
      //to avoid errors on filename path.
      final now = DateTime.now()
          .toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_');

      //Creates the full local directory path in order to save the audio file.
      final filePath = '${directory.path}/audio_recording_$now.m4a';

      audioPath = filePath;

      //Starts Recording audio and saves it into the previously created path
      await _audioRecorder.start(const RecordConfig(), path: audioPath);

      //Updates the UI and sets isRecording as true.
      setState(() {
        isRecording = true;
      });

      //Starts recording timer.
      recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          recordingSeconds++;
        });
      });
    } else {
      //print ('Microphone Permission Denied');
    }
  }

  //Stops audio recording.
  Future<void> stopRecording() async {
    //Prevents stopping if there is no active audio recording
    if (!isRecording) return;

    //Stops Recording and returns the final file path.
    final path = await _audioRecorder.stop();

    //Stops recording timer.
    recordingTimer?.cancel();

    //Updates recording state to false and saves the final audio path.
    setState(() {
      isRecording = false;

      //Stores the final recording duration.
      audioDuration = recordingSeconds;
      //Resets recording counter.
      recordingSeconds = 0;

      //Stores the final audio file path.
      if (path != null) {
        audioPath = path;
      }
    });
  }

  //initState runs when the page opens
  @override
  void initState() {
    super.initState();

    //Loads existing story title, description, audio path and cover image.
    _titleController.text = widget.story.title;
    coverImagePath = widget.story.coverImage;
    if (widget.story.pages.isNotEmpty) {
      audioPath = widget.story.pages.first.pageAudio;
      audioDuration = widget.story.pages.first.pageAudioDuration;
    }
  }

  @override
  //Clean Memory when Page Closes
  void dispose() {
    _titleController.dispose();
    _audioRecorder.dispose();

    //Stops the recording timer when the page closes.
    recordingTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Same Background as the Home Page
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: const Text('Edit Story'),
      ),

      //Allows page scroll when keyboard appears
      body: SingleChildScrollView(
        child: Padding(
          //Adds spacing so the UI doesn't touch the screen borders.
          padding: const EdgeInsets.all(24),
          child: Column(
            //Column stretches widgets vertically.
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const Text(
                'Edit your Story Here',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 32),

              //Cover Image Preview
              if (coverImagePath.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(35),
                  child: Image.file(
                    File(coverImagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                //Story Title Field
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Edit Story Title',
                    labelStyle: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(35),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              //Select Cover Image Button
              ElevatedButton(
                //Imported button style.
                style: ButtonStyles.tealButton,

                onPressed: pickCoverImage,
                child: Text(
                  coverImagePath.isEmpty
                      ? 'Select a Cover Image'
                      : 'Select a new Cover Image',
                ),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                //Imported button style.
                style: ButtonStyles.audioButton,

                onPressed: () {
                  //Changes dynamically the recording button
                  //between 'Start Recording' and 'Stop Recording'.
                  if (isRecording) {
                    stopRecording();
                  } else {
                    startRecording();
                  }
                },
                child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
              ),

              Text(
                isRecording
                    ? 'Recording: ${formatRecordingTime(recordingSeconds)}'
                    : 'Not Recording',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 32),

              //Story Edit Button
              ElevatedButton(
                //Imported button style.
                style: ButtonStyles.tealButton,

                onPressed: () async {
                  //trim() trims the spaces on the beginning
                  // and end of title.
                  final storyTitle = _titleController.text.trim();
                  //Checks if story title is empty.
                  //If it is empty, it shows the appropriate
                  //message at the bottom of the screen.
                  if (storyTitle.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please Enter a Story Title')),
                    );
                  } else {
                    //Displays Update confirmation dialog.
                    bool? confirmUpdate = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: Text('Update Story'),
                        content: Text(
                          'Are you sure you want to update this story?',
                        ),
                        actions: [
                          //Cancel button.
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: Text('Cancel'),
                          ),

                          //Confirm Update button.
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },
                            child: Text('Update'),
                          ),
                        ],
                      ),
                    );

                    if (confirmUpdate != true) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Story Updated: $storyTitle')),
                    );

                    //Creates an updated Story object with the new values.
                    final updatedStory = Story(
                      title: storyTitle,
                      coverImage: coverImagePath,
                      pages: [
                        StoryPage(
                          pageImage: coverImagePath,
                          pageAudio: audioPath,
                          pageAudioDuration: audioDuration,
                        ),
                      ],
                    );

                    //Closes the page and returns the new story to the previous page.
                    Navigator.pop(context, updatedStory);
                  }
                },
                child: const Text('Update Story'),
              ),

              const SizedBox(height: 12),
              /*Text(
                    audioPath.isEmpty
                        ?'No Audio Recorded'
                        : 'Audio Recorded',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)

                  )  ,*/
            ],
          ),
        ),
      ),
    );
  }
}
