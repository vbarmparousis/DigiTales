//Import Packages
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';



//My Imports
import '../models/story.dart';
import 'button_styles.dart';
import '../widgets/recording_bottom_sheet.dart';

class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({super.key});

  @override
  State<StoryCreationPage> createState() => _StoryCreationPageState();
}

//Private Clash (underscore: _)
class _StoryCreationPageState extends State<StoryCreationPage> {

  //Controls the story title TextField
  final TextEditingController _titleController = TextEditingController();

  //Controls the story description TextField
  final TextEditingController _descriptionController = TextEditingController();

  //Controls audio recording
  final AudioRecorder _audioRecorder = AudioRecorder();

  //ImagePicker allows to pick an image from gallery.
  final ImagePicker imagePicker = ImagePicker();

  //Stores the local file path of the selected image.
  String coverImagePath='';

  //Boolean that checks if audio is being recorded.
  bool isRecording=false;

  //String that stores the local file path
  //where the recorded audio file will be saved.
  String audioPath='';

  //Timer object. it updates the recording duration in seconds.
  Timer? recordingTimer;

  //Stores recording's duration.
  int recordingSeconds =0;

  //Stores audio duration in seconds.
  int audioDuration=0;

  String formatRecordingTime(int seconds){
    return Duration(seconds:seconds)
        .toString()
        .split('.')
        .first
        .padLeft(8,'0');
  }

  //Opens device gallery and allows
  //user to pick a cover image for the story.
  Future <void> pickCoverImage() async{
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
     return;
    }

    //Stores the selected image file path and updates the UI.
    setState(() {
      coverImagePath=selectedImage.path;
    });
    }

  //Starts Audio Recording
  Future <void> startRecording() async{
    //Prevents the start of another recording while
    //an audio is already being recorded.
    if (isRecording) return;

    //Waits for microphone permission before starting recording.
    if (await _audioRecorder.hasPermission()){
      //Permission granted, proceed with recording

      //Gets the application's local document directory.
      final directory = await getApplicationDocumentsDirectory();
      //print('Path=============================: ${directory.path}');

      //Creates unique filenames and replaces special character
      //in the date in order to avoid errors on filename path.
      final now = DateTime.now().toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_');

      //Creates the full local file path in order to save the audio file.
      //It uses the variable 'now' to create unique filenames
      //and avoid filename conflicts.
      final filePath = '${directory.path}/audio_recording_$now.m4a';

      //Stores the generated file path.
      audioPath=filePath;

      //Starts Recording audio and saves it into the previously created path
      await _audioRecorder.start(
        const RecordConfig(),
        path: audioPath,
      );

      //Updates the UI and sets isRecording as true.
      setState(() {
        isRecording = true;
      });

      recordingTimer=Timer.periodic(
          const Duration(seconds:1),

          (timer){

            //Updates UI every second
            setState(() {

              //Increase recording duration by 1 second.
              recordingSeconds++;
            });
          },
      );


    } else{
      //print ('Microphone Permission Denied');
    }
  }

  //Stops audio recording.
  Future <void> stopRecording() async{

    //Prevents stopping if there is no active audio recording
    if (!isRecording) return;

    //Stops Recording and returns the final file path.
    final path = await _audioRecorder.stop();

    //Stops recording timer.
    recordingTimer?.cancel();

    //Updates recording state to false and saves the final audio path.
    setState(() {
      isRecording=false;

      //Stores the final recording duration before resetting it.
      audioDuration = recordingSeconds;

      //Resets recording duration to 0.
      recordingSeconds=0;

      if(path!=null){
        audioPath=path;
      }

    });

  }

  @override
  //Clean Memory when Page Closes
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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

          title: const Text ('Create New Story'),
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
                    'Create your Story Here',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  //Cover Image Preview
                  if(coverImagePath.isNotEmpty)
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

                //Enter Story Title Form
                  SizedBox(
                      width: double.infinity,
                      child:TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Enter Story Title',
                          labelStyle: const TextStyle( color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                        ),
                      )
                  ),

                  const SizedBox(height: 32),

                  //Enter Story Description Form
                  SizedBox(
                      width: double.infinity,
                      child:TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Enter Story Description',
                          labelStyle: const TextStyle( color: Colors.teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                        ),
                      )
                  ),

                  const SizedBox(height: 32),


                //Select Cover Image Button
                ElevatedButton(
                    //Imported button style.
                    style: ButtonStyles.tealButton,

                    onPressed: pickCoverImage,
                    child: Text (
                      coverImagePath.isEmpty
                          ? 'Select Cover Image'
                          : 'Select a new Cover Image'
                    ),
                ),

                  const SizedBox(height: 32),



                  //Audio Recording Button
                  ElevatedButton(
                    //Imported button style.
                    style: ButtonStyles.audioButton,

                    onPressed:() {
                      //Changes dynamically the recording button
                      //between 'Start Recording' and 'Stop Recording'.
                      if (isRecording) {
                        stopRecording();
                      }else {
                        startRecording();
                      }
                    },
                    child: Text(isRecording ? 'Stop Recording':'Start Recording' ),
                  ),
                  Text(
                    isRecording
                        ? 'Recording: ${formatRecordingTime(recordingSeconds)}'
                        :'Not Recording',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 32),

                  //Save Story Button
                  ElevatedButton(
                    //Imported button style.
                    style: ButtonStyles.tealButton,

                    onPressed:() {
                      //trim() trims the spaces on the beginning and end
                      //of title and description.
                      final storyTitle = _titleController.text.trim();
                      final storyDescription = _descriptionController.text.trim();
                      //Checks if story title is empty.
                      //If it is empty, it shows the appropriate
                      //message at the bottom of the screen.
                      if (storyTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please Enter a Story Title'),
                        ),
                        );
                      }
                      else if (audioPath.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Please Record an Audio before Saving'),
                        ),
                        );
                      }
                      else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Story Saved: $storyTitle'),
                        ),
                        );

                        //Creates an new Story object with the entered values.
                        final newStory = Story(
                          title: storyTitle,
                          description: storyDescription,
                          storyAudio: audioPath,
                          coverImage: coverImagePath,
                          audioDuration: audioDuration,
                        );

                        //Closes the page and returns the newly created
                        //story to the previous page.
                        Navigator.pop(context, newStory);

                      }
                    },
                    child: const Text('Save Story'),
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    //Imported button style.
                    style: ButtonStyles.deleteButton,


                    onPressed:() async{
                      final recording = await showRecordingBottomSheet(context);

                      if (recording != null){
                        setState(() {
                          audioPath= recording.audioPath;
                          audioDuration= recording.audioDuration;
                        });
                      }
                    },
                    child: Text('Audio Recorder Bottom Sheet' ),
                  ),

                ]
            )
        ),
        )
    );
  }
}
