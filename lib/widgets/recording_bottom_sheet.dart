//Library Imports
import 'dart:async';

//Package Imports
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

//My Imports
import '../theme/app_colors.dart';

//Stores the results of audio recordings.
class AudioRecording {
  final String audioPath;
  final int audioDuration;

  AudioRecording({required this.audioPath, required this.audioDuration});
}

//Audio recording bottom sheet popup
//Returns recorded audio path and duration when finished.
Future<AudioRecording?> showRecordingBottomSheet(BuildContext context) async {
  //Controls audio recording
  final AudioRecorder audioRecorder = AudioRecorder();

  //Boolean that checks if audio is being recorded.
  bool isRecording = false;

  //Boolean that checks if audio is being paused.
  bool isPaused = false;

  //String that stores the local file path
  //where the recorded audio file will be saved.
  String audioPath = '';

  //Timer object. it updates the recording duration in seconds.
  Timer? recordingTimer;

  //Stores recording's duration.
  int recordingSeconds = 0;

  //Stores audio duration in seconds.
  int audioDuration = 0;

  //Formats recording duration into HH:MM:SS format.
  String formatRecordingTime(int seconds) {
    return Duration(
      seconds: seconds,
    ).toString().split('.').first.padLeft(8, '0');
  }

  //Pencil Icon Animation Position.
  //0 : left position
  //1 : middle position
  //2 : right position
  int pencilAnimationIndex = 0;

  //Function that starts audio recording.
  //StateSetter updates the UI inside the bottom sheet.
  Future<void> startRecording(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    //Prevents the start of another recording while
    //an audio is already being recorded.
    if (isRecording) return;

    //Waits for microphone permission before starting recording.
    if (await audioRecorder.hasPermission()) {
      //Permission granted, proceed with recording

      //Gets the application's local document directory.
      final directory = await getApplicationDocumentsDirectory();

      //Stops the function if the page is no longer active.
      if (!context.mounted) {
        return;
      }

      //Creates unique filenames and replaces special character
      //in the date in order to avoid errors on filename path.
      final now = DateTime.now()
          .toString()
          .replaceAll(':', '_')
          .replaceAll(' ', '_');

      //Creates the full local file path in order to save the audio file.
      //It uses the variable 'now' to create unique filenames
      //and avoid filename conflicts.
      final filePath = '${directory.path}/audio_recording_$now.m4a';

      //Stores the generated file path.
      audioPath = filePath;

      //Starts Recording audio and saves it into the previously created path
      await audioRecorder.start(
        const RecordConfig(numChannels: 1, noiseSuppress: true),
        path: audioPath,
      );

      //Cancels the unfinished recording if the recording bottom is no longer active.
      if (!context.mounted) {
        await audioRecorder.cancel();
        return;
      }

      //Updates the UI and sets isRecording as true.
      setModalState(() {
        isRecording = true;
      });

      recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        //Stops the timer if the recording bottom sheet is no longer active.
        if (!context.mounted) {
          timer.cancel();
          return;
        }

        //Updates UI every second
        setModalState(() {
          //Increase recording duration by 1 second.
          recordingSeconds++;

          //Changes pencil icon position every second while audio recording is on.
          pencilAnimationIndex = (pencilAnimationIndex + 1) % 3;
        });
      });
    } else {
      //Shows a message when microphone permission is denied.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required to record narration.',
            ),
          ),
        );
      }
    }
  }

  //Function that pauses audio recording.
  Future<void> pauseRecording(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    if (!isRecording || isPaused) return;

    await audioRecorder.pause();
    recordingTimer?.cancel();

    //Stops the function if the recording bottom sheet is no longer active.
    if (!context.mounted) {
      return;
    }

    setModalState(() {
      isPaused = true;
    });
  }

  //Function that resumes paused audio recording.
  Future<void> resumeRecording(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    if (!isRecording || !isPaused) return;

    await audioRecorder.resume();

    //Stops the function if the recording bottom sheet is no longer active.
    if (!context.mounted) {
      return;
    }

    setModalState(() {
      isPaused = false;
    });

    recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      //Stops the timer if the recording bottom sheet is no longer active.
      if (!context.mounted) {
        timer.cancel();
        return;
      }

      //Updates UI every second
      setModalState(() {
        //Increase recording duration by 1 second.
        recordingSeconds++;

        //Changes pencil icon position every second while audio recording is on.
        pencilAnimationIndex = (pencilAnimationIndex + 1) % 3;
      });
    });
  }

  //Stops audio recording.
  Future<void> stopRecording(
    BuildContext context,
    StateSetter setModalState,
  ) async {
    //Prevents stopping if there is no active audio recording
    if (!isRecording) return;

    //Stops Recording and returns the final file path.
    final path = await audioRecorder.stop();

    //Stops recording timer.
    recordingTimer?.cancel();

    //Stops the function if the recording bottom sheet is no longer active.
    if (!context.mounted) {
      return;
    }

    //Updates recording state to false and saves the final audio path.
    setModalState(() {
      isRecording = false;

      //Stores the final recording duration before resetting it.
      audioDuration = recordingSeconds;

      //Resets recording duration to 0.
      recordingSeconds = 0;

      if (path != null) {
        audioPath = path;
      }
    });
  }

  final AudioRecording? recording = await showModalBottomSheet<AudioRecording>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,

    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: 400,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),

            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  //Column stretches widgets vertically.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Audio Recorder',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      formatRecordingTime(recordingSeconds),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.appText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    //Decorative animation that changes
                    //pencil icon position every second during recording.
                    Center(
                      child: SizedBox(
                        key: ValueKey(pencilAnimationIndex),
                        height: 90,
                        width: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 100,
                              color: isRecording
                                  ? AppColors.parentPrimary
                                  : AppColors.disabled,
                            ),

                            Positioned(
                              top: 2,
                              left: 5,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 50,
                                color: isRecording
                                    ? AppColors.childMode
                                    : AppColors.disabled,
                              ),
                            ),

                            //Moving Pencil.
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              bottom: 33,

                              //Move pencil left -> middle ->right
                              left: pencilAnimationIndex == 0
                                  ? 67
                                  : pencilAnimationIndex == 1
                                  ? 77
                                  : 87,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 36,
                                  color: isRecording && !isPaused
                                      ? AppColors.childMode
                                      : AppColors.disabled,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isRecording
                          ? isPaused
                                ? 'Recording Paused'
                                : 'Recording...'
                          : 'Not Recording',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRecording
                            ? isPaused
                                  ? AppColors.disabled
                                  : AppColors.childMode
                            : AppColors.disabled,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        //Start / Pause / Resume Button.
                        IconButton(
                          iconSize: 60,
                          color: AppColors.childMode,

                          onPressed: () {
                            if (!isRecording) {
                              startRecording(context, setModalState);
                            } else if (isPaused) {
                              resumeRecording(context, setModalState);
                            } else {
                              pauseRecording(context, setModalState);
                            }
                          },

                          icon: Icon(
                            isRecording && !isPaused
                                ? Icons.pause_circle_outline_rounded
                                : Icons.play_circle_filled_rounded,
                          ),
                        ),

                        const SizedBox(width: 24),

                        //Stop and Save Button.
                        IconButton(
                          iconSize: 60,
                          color: AppColors.parentPrimary,
                          onPressed: isRecording
                              ? () async {
                                  await stopRecording(context, setModalState);

                                  //Stops the function if the page is no longer active.
                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (audioPath.isNotEmpty) {
                                    Navigator.pop(
                                      context,
                                      AudioRecording(
                                        audioPath: audioPath,
                                        audioDuration: audioDuration,
                                      ),
                                    );
                                  }
                                }
                              : null,

                          icon: const Icon(Icons.check_circle_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  //Stops the recording timer when the bottom sheet closes.
  recordingTimer?.cancel();

  //Cancels an unfinished recording when the bottom sheet closes.
  if (isRecording) {
    await audioRecorder.cancel();
  }

  //Disposes the audio recorder.
  await audioRecorder.dispose();

  return recording;
}
