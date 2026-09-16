//Library Imports
import 'dart:async';
import 'dart:io';

//Package Imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

//My Imports
import '../models/story.dart';
import '../models/background_music.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/button_styles.dart';
import '../widgets/recording_bottom_sheet.dart';
import '../widgets/image_source_bottom_sheet.dart';
import '../widgets/section_card.dart';
import '../widgets/story_image_preview_frame.dart';
import '../theme/app_colors.dart';

class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({super.key});

  @override
  State<StoryCreationPage> createState() => _StoryCreationPageState();
}

//Private Class (underscore: _)
class _StoryCreationPageState extends State<StoryCreationPage> {
  //Controls the story title TextField
  final TextEditingController _titleController = TextEditingController();

  //Allows to pick images from device gallery or camera.
  final ImagePicker imagePicker = ImagePicker();

  //Stores the local file path of the selected cover image.
  String coverImagePath = '';

  //Stores the selected background music.
  String selectedBackgroundMusic = '';

  //Stores the local file path of the selected page image.
  String pageImagePath = '';

  //Stores all pages of a story.
  List<StoryPage> pages = [];

  //Stores the local file path of the selected page's recorded audio.
  String audioPath = '';

  //Stores the duration (in seconds) of the selected page's recorded audio.
  int audioDuration = 0;

  //Controls the story pages preview carousel.
  final PageController pagePreviewController = PageController();

  //Page preview audio player.
  final AudioPlayer pagePreviewAudioPlayer = AudioPlayer();

  //Background music audio player.
  final AudioPlayer backgroundMusicAudioPlayer = AudioPlayer();

  //Listens for preview page audio player state changes.
  StreamSubscription<PlayerState>? playerStateSubscription;

  //Listens for preview page audio duration changes.
  StreamSubscription<Duration>? durationSubscription;

  //Listens for preview page audio position changes.
  StreamSubscription<Duration>? positionSubscription;

  //Listens for when the preview page audio is completed.
  StreamSubscription<void>? playerCompleteSubscription;

  //Stores the audio setup Future. It is used so the application can
  //wait until both players are ready to play together.
  late final Future<void> audioSetupFuture;

  //Stores the selected page index.
  int selectedPageIndex = 0;

  //Checks if the selected page audio is being played.
  //It is used to switch between Play and Pause buttons.
  bool isPreviewPlaying = false;

  //Checks if the preview audio is paused.
  bool isPreviewPaused = false;

  //Stores the selected page audio duration.
  Duration previewDuration = Duration.zero;

  //Stores selected page audio playback position.
  Duration previewPosition = Duration.zero;

  //Checks if the cover image is in zoom mode.
  bool isCoverImageZoomed = false;

  //Checks if the page creation image is in zoom mode.
  bool isPageImageZoomed = false;

  //Checks if the carousel image is in zoom mode.
  bool isCarouselImageZoomed = false;

  //Checks if the user is currently interacting directly with a zoomed image.
  bool isInteractingWithZoomedImage = false;

  //Updates whether the user is currently interacting with a zoomed image.
  void handleZoomInteractionChanged(bool isInteracting) {
    if (isInteractingWithZoomedImage != isInteracting) {
      setState(() {
        isInteractingWithZoomedImage = isInteracting;
      });
    }
  }

  //Formats seconds into MM:SS format.
  String formatTime(int seconds) {
    //Calculates the amount of full minutes (exactly 60 seconds).
    final minutes = seconds ~/ 60;

    //Calculates the remaining seconds after removing the amount of full minutes.
    final remainingSeconds = seconds % 60;

    //Minutes and remaining seconds will always have two digits.
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  //Sets the audio for both audio players.
  //This allows preview page audio and background music to play
  //at the same time instead of interrupting each other.
  Future<void> setupAudioPlayers() async {
    //Creates an audio context that allows multiple
    //audio players to mix their sounds.
    final audioContext = AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
    ).build();

    //Applies the audio context to the preview page audio player
    //and background music audio player.
    await pagePreviewAudioPlayer.setAudioContext(audioContext);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    await backgroundMusicAudioPlayer.setAudioContext(audioContext);
  }

  //Runs once when the Page is first created.
  @override
  void initState() {
    super.initState();

    //Sets up preview page audio player and background music
    // audio player so they can play simultaneously.
    //The result is stored in audioSetupFuture so playPreviewAudio()
    //can wait for the setup to finish.
    audioSetupFuture = setupAudioPlayers();

    //Initialization of Audio Listeners.

    //Listens for audio state changes (playing, paused).
    playerStateSubscription = pagePreviewAudioPlayer.onPlayerStateChanged
        .listen((state) {
          //Stops the function if the page is no longer active.
          if (!mounted) {
            return;
          }

          setState(() {
            //If the audio player state is 'playing',
            //isPreviewPlaying becomes true.
            //Otherwise, isPreviewPlaying becomes false.
            isPreviewPlaying = state == PlayerState.playing;
          });
        });

    //Listens for changes in the selected page audio duration.
    durationSubscription = pagePreviewAudioPlayer.onDurationChanged.listen((
      newDuration,
    ) {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Stores the duration of the audio player.
      //It is used as the maximum value of the preview slider.
      setState(() {
        previewDuration = newDuration;
      });
    });

    //Listens for changes in the selected page audio position.
    positionSubscription = pagePreviewAudioPlayer.onPositionChanged.listen((
      newPosition,
    ) {
      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Updates the current slider position while the audio is being played.
      setState(() {
        previewPosition = newPosition;
      });
    });

    //Listens for when the selected page audio finishes completely.
    playerCompleteSubscription = pagePreviewAudioPlayer.onPlayerComplete.listen(
      (event) async {
        //Stops the function if the page is no longer active.
        if (!mounted) {
          return;
        }

        //Stops background music when the page audio finishes completely.
        await backgroundMusicAudioPlayer.stop();

        //Stops the function if the page is no longer active.
        if (!mounted) {
          return;
        }

        //Resets the audio slider position back to the beginning.
        await pagePreviewAudioPlayer.seek(Duration.zero);

        //Stops the function if the page is no longer active.
        if (!mounted) {
          return;
        }

        //Stops page audio and background music audio,
        //audio button returns to 'Play'.
        setState(() {
          isPreviewPlaying = false;
          isPreviewPaused = false;
          previewPosition = Duration.zero;
        });
      },
    );
  }

  //Copies the selected image into the app's local document folder.
  //This prevents image paths from breaking when Android clears temporary files.
  Future<String> copyImageToAppFolder(String originalImagePath) async {
    //Gets app's local document directory.
    final appDirectory = await getApplicationDocumentsDirectory();

    //Formats date time for the copied image's name.
    final dateTime = DateTime.now()
        .toString()
        .replaceAll(':', '_')
        .replaceAll(' ', '_');

    //Keeps the original image file extension.
    final extension = originalImagePath.split('.').last;

    //Creates a new permanent image path.
    final newImagePath =
        '${appDirectory.path}/story_image_$dateTime.$extension';

    //Copies the image into the app folder.
    final copiedImage = await File(originalImagePath).copy(newImagePath);

    //Returns the new image path.
    return copiedImage.path;
  }

  //Opens image source bottom sheet and allows the
  //user to pick a cover image for the story.
  Future<void> pickCoverImage() async {
    //Opens image source bottom sheet and waits for user
    //to choose between gallery image and camera photo.
    final ImageSource? selectedImageSource = await showImageSourceBottomSheet(
      context,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image source selection is canceled, the function stops.
    if (selectedImageSource == null) {
      return;
    }

    //Opens gallery or camera depending on user's choice.

    //The '?' in XFile is for when the user closes the device gallery or camera
    //without picking a cover image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: selectedImageSource,

      //Prevents very large camera photos from causing delays
      //during the page flip animation.
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image selection is canceled, the function stops.
    if (selectedImage == null) {
      return;
    }

    //Copies the selected image into the app's local document folder
    //and stores the new path of the copied image.
    final copiedImagePath = await copyImageToAppFolder(selectedImage.path);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Stores the selected image file path and updates the UI in order
    //to show the selected cover image.
    setState(() {
      coverImagePath = copiedImagePath;

      //Returns the cover image preview to its normal portrait mode.
      isCoverImageZoomed = false;
    });
  }

  //Opens image source bottom sheet and allows the
  //user to pick an image for the current page of the story.
  Future<void> pickPageImage() async {
    //Opens image source bottom sheet and waits for user
    //to choose between gallery image and camera photo.
    final ImageSource? selectedImageSource = await showImageSourceBottomSheet(
      context,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image source selection is canceled, the function stops.
    if (selectedImageSource == null) {
      return;
    }

    //Opens gallery or camera depending on user's choice.

    //The '?' in XFile is for when the user closes device gallery or camera
    //without picking a page image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: selectedImageSource,

      //Prevents very large camera photos from causing delays
      //during the page flip animation.
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image selection is canceled, the function stops.
    if (selectedImage == null) {
      return;
    }

    //Copies the selected image into the app's local document folder
    //and stores the new path of the copied image.
    final copiedImagePath = await copyImageToAppFolder(selectedImage.path);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Stores the copied image file path and updates the UI in order
    //to show the selected page image.
    setState(() {
      pageImagePath = copiedImagePath;

      //Returns the page image preview to its normal portrait mode.
      isPageImageZoomed = false;
    });
  }

  //Adds a new page to the story.
  //In order to add a new page, the user must select a page image
  //and a page audio recording.
  void addPage() {
    //Checks if a page image has been selected.
    //If not, the page cannot be added and the proper message appears.
    if (pageImagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a page image before adding a page.'),
        ),
      );
      //Stops the function.
      return;
    }

    //Checks if an audio has been recorded.
    //If not, the page cannot be added and the proper message appears.
    if (audioPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record narration before adding a new page.'),
        ),
      );
      //Stops the function.
      return;
    }

    //Updates the UI after adding the new page.
    setState(() {
      //Creates a new StoryPage object and adds it to the page list.
      pages.add(
        StoryPage(
          pageImage: pageImagePath,
          pageAudio: audioPath,
          pageAudioDuration: audioDuration,
        ),
      );

      //Clears current page's image because the next page
      //will need a new image.
      pageImagePath = '';

      //Clears current page's audio because the next page
      //will need a new audio recording.
      audioPath = '';

      //Resets page's audio duration.
      audioDuration = 0;

      //Returns the now empty page image preview to its normal portrait mode.
      isPageImageZoomed = false;
    });

    //Shows confirmation message after the page is added to the story.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Page ${pages.length} added to the story.')),
    );
  }

  //Plays the selected preview page audio.
  Future<void> playPreviewAudio() async {
    //If there are no pages, the function stops.
    if (pages.isEmpty) {
      return;
    }

    //Gets the audio path of the selected page.
    final selectedPageAudio = pages[selectedPageIndex].pageAudio;

    //If there is no audio path on the selected page,
    //the function stops.
    if (selectedPageAudio.isEmpty) {
      return;
    }

    //Waits until both audio players are ready to play together.
    await audioSetupFuture;

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the preview page audio was paused before,
    //resume the preview page audio and the background music.
    if (isPreviewPaused) {
      //Resumes the preview page audio from the paused position.
      await pagePreviewAudioPlayer.resume();

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //If a background music has been selected,
      //resumes the background music audio from the paused position.
      if (selectedBackgroundMusic.isNotEmpty) {
        await backgroundMusicAudioPlayer.resume();
      }

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Resets isPreviewPaused because the preview audio is no longer paused.
      setState(() {
        isPreviewPaused = false;
      });

      return;
    }

    //Stops any preview audio that may already be playing.
    await stopAllPreviewAudio();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Plays the selected page audio from the local device file path.
    await pagePreviewAudioPlayer.play(DeviceFileSource(selectedPageAudio));

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If a background music has been selected, it starts playing behind
    //the preview page audio.
    if (selectedBackgroundMusic.isNotEmpty) {
      //Makes the background music loop while the recording is playing.
      await backgroundMusicAudioPlayer.setReleaseMode(ReleaseMode.loop);

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Lowers the volume of background music.
      await backgroundMusicAudioPlayer.setVolume(0.04);

      //Stops the function if the page is no longer active.
      if (!mounted) {
        return;
      }

      //Plays the selected background music from assets.
      await backgroundMusicAudioPlayer.play(
        AssetSource(selectedBackgroundMusic),
      );
    }
  }

  //Pauses the selected preview page audio.
  //If there is a selected background music audio, it pauses too.
  Future<void> pausePreviewAudio() async {
    //Pauses the current playback and keeps the current position,
    //so if the user presses play again, the audio continues from
    //the point it stopped.
    await pagePreviewAudioPlayer.pause();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If a background music has been selected,
    //pauses the background music audio and keeps its current position.
    if (selectedBackgroundMusic.isNotEmpty) {
      await backgroundMusicAudioPlayer.pause();
    }

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Sets the preview as paused.
    setState(() {
      isPreviewPaused = true;
    });
  }

  //Stops both the preview page audio and the background music audio.
  Future<void> stopAllPreviewAudio() async {
    //Stops the selected preview page audio.
    await pagePreviewAudioPlayer.stop();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Stops the background music audio.
    await backgroundMusicAudioPlayer.stop();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Resets the preview page audio UI.
    setState(() {
      isPreviewPlaying = false;
      isPreviewPaused = false;
      previewPosition = Duration.zero;
    });
  }

  //Changes the preview page on carousel everytime the user swipes
  //left or right.
  Future<void> changePreviewPage(int index) async {
    //Stops any preview audio that may already be playing.
    await stopAllPreviewAudio();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Updates the UI by showing the next/previous story and resetting
    //the audio parameters.
    setState(() {
      selectedPageIndex = index;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;

      //Returns the current page preview to its normal portrait mode
      //so the next or previous page image appears in portrait mode.
      isCarouselImageZoomed = false;
    });
  }

  //Moves the preview carousel to previous page.
  Future<void> goToPreviousPreviewPage() async {
    //If the first page is selected, the function stops.
    if (selectedPageIndex <= 0) {
      return;
    }

    //Moves the PageView to the previous page with a smooth animation.
    await pagePreviewController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //Moves the preview carousel to next page.
  Future<void> goToNextPreviewPage() async {
    //If the last page is selected, the function stops.
    if (selectedPageIndex >= pages.length - 1) {
      return;
    }

    //Moves the PageView to the next page with a smooth animation.
    await pagePreviewController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //Changes selected page preview image.
  Future<void> changeSelectedPagePreviewImage() async {
    //If there are no pages, the function stops.
    if (pages.isEmpty) {
      return;
    }

    //Opens image source bottom sheet and waits for user
    //to choose between gallery image and camera photo.
    final ImageSource? selectedImageSource = await showImageSourceBottomSheet(
      context,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image source selection is canceled, the function stops.
    if (selectedImageSource == null) {
      return;
    }

    //Opens gallery or camera depending on user's choice.

    //The '?' in XFile is for when the user closes the device gallery or camera
    //without picking a new page image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: selectedImageSource,

      //Prevents very large camera photos from causing delays
      //during the page flip animation.
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
      return;
    }

    //Copies the selected image into the app's local document folder
    //and stores the new path of the copied image.
    final copiedImagePath = await copyImageToAppFolder(selectedImage.path);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Updates the selected page image.
    setState(() {
      //Stores the old selected StoryPage before replacing it.
      //This is needed because StoryPage fields are final,
      //so instead of changing only the image field, it creates
      //a new StoryPage object with the updated image but
      //the old audio and audio duration.
      final StoryPage oldPage = pages[selectedPageIndex];

      //Replaces the selected StoryPage with a new StoryPage object.
      pages[selectedPageIndex] = StoryPage(
        //New selected image.
        pageImage: copiedImagePath,

        //Keeps the old audio and audio duration.
        pageAudio: oldPage.pageAudio,
        pageAudioDuration: oldPage.pageAudioDuration,
      );

      //Closes zoom mode because the selected page has a new image now.
      isCarouselImageZoomed = false;
    });
  }

  //Changes selected page preview audio.
  Future<void> changeSelectedPagePreviewAudio() async {
    //If there are no pages, the function stops.
    if (pages.isEmpty) {
      return;
    }

    //Stops any preview audio that may already be playing
    //before opening the recording bottom sheet.
    await stopAllPreviewAudio();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Opens recording bottom sheet.
    //It returns an AudioRecording object.
    final recording = await showRecordingBottomSheet(context);

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the audio recording is canceled, stop the function.
    if (recording == null) {
      return;
    }

    //Updates the selected page audio and audio duration.
    setState(() {
      //Stores the old selected StoryPage before replacing it.
      //This is needed because StoryPage fields are final,
      //so instead of changing only the audio path and audio duration
      //fields, it creates a new StoryPage object with the updated
      //audio and audio duration but the old image.
      final StoryPage oldPage = pages[selectedPageIndex];

      pages[selectedPageIndex] = StoryPage(
        //Keeps the old page image.
        pageImage: oldPage.pageImage,
        //New recorded audio path and audio duration.
        pageAudio: recording.audioPath,
        pageAudioDuration: recording.audioDuration,
      );

      //Resets preview audio parameters.
      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
    });
  }

  //Deletes the selected preview page.
  Future<void> deleteSelectedPage() async {
    //If there are no pages, the function stops.
    if (pages.isEmpty) {
      return;
    }

    //Shows delete confirmation dialog
    //to prevent page deletions by mistake.
    final bool? confirmDeletePage = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete Page'),
        content: Text('Are you sure you want to delete this page?'),
        actions: [
          //Cancel Button.
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
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //If the user cancels the alert dialog, the function stops.
    if (confirmDeletePage != true) {
      return;
    }

    //Stops any preview audio that may already be playing.
    await stopAllPreviewAudio();

    //Stops the function if the page is no longer active.
    if (!mounted) {
      return;
    }

    //Updates the page list and the UI.
    setState(() {
      //Removes the selected page from the page list.
      pages.removeAt(selectedPageIndex);

      //If there are no pages left, resets selectedPageIndex to 0.
      if (pages.isEmpty) {
        selectedPageIndex = 0;
      }
      //If the deleted page was the last page, moves the
      //selectedPageIndex to the new last page.
      else if (selectedPageIndex >= pages.length) {
        selectedPageIndex = pages.length - 1;
      }

      //Resets preview audio parameters.
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;

      //Closes zoom mode because the selected page is now removed.
      //Re-enables PageView swiping.
      isCarouselImageZoomed = false;
    });
  }

  @override
  //Cleans memory when Page closes.
  void dispose() {
    //Stops listening to preview audio events.
    playerStateSubscription?.cancel();
    durationSubscription?.cancel();
    positionSubscription?.cancel();
    playerCompleteSubscription?.cancel();

    //Disposes the title controller.
    _titleController.dispose();
    //Disposes the page controller used by the preview carousel.
    pagePreviewController.dispose();
    //Disposes the audio player used by the preview carousel.
    pagePreviewAudioPlayer.dispose();
    //Disposes the background music audio player used by the preview carousel.
    backgroundMusicAudioPlayer.dispose();
    //Calls the parent dispose method to complete the cleanup.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Everytime SetState() is called, this method runs and rebuilds the UI.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Create Story',
          foregroundColor: Colors.white,
          textColor: Colors.white,
          backgroundColor: AppColors.parentPrimary,
        ),

        //Allows page scroll and prevents overflow issues
        //when the keyboard appears.
        body: SafeArea(
          //the AppBar already protects the top system area so top:false.
          top: false,
          child: SingleChildScrollView(
            //Disables page scrolling only while
            //the user is interacting directly with a zoomed image.
            physics: isInteractingWithZoomedImage
                ? const NeverScrollableScrollPhysics()
                : null,
            child: Padding(
              //Adds spacing so the UI doesn't touch the screen borders.
              padding: const EdgeInsets.all(24),
              child: Column(
                //Stretches the children horizontally across the available width.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //1. Section Card: Story Details (Title + Cover Image).
                  SectionCard(
                    title: 'Story Details',
                    icon: Icons.info_rounded,
                    children: [
                      const SizedBox(height: 15),
                      //Story Title Field.
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Enter Story Title',
                          labelStyle: const TextStyle(
                            color: AppColors.appText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      //Cover Image Preview.

                      //Displays the selected cover image.
                      StoryImagePreviewFrame(
                        imagePath: coverImagePath,
                        isZoomed: isCoverImageZoomed,

                        //Controls page scrolling while interacting with the zoomed image.
                        onZoomInteractionChanged: handleZoomInteractionChanged,

                        onZoomPressed: () {
                          setState(() {
                            isCoverImageZoomed = !isCoverImageZoomed;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      //Select Cover Image Button.
                      ElevatedButton.icon(
                        //Imported button style.
                        style: ButtonStyles.primaryParentButton,
                        onPressed: pickCoverImage,
                        icon: const Icon(Icons.image_rounded),
                        label: Text(
                          coverImagePath.isEmpty
                              ? 'Select Cover Image'
                              : 'Change Cover Image',
                        ),
                      ),
                    ],
                  ),

                  //2. Section Card: Page Creation.
                  SectionCard(
                    title: 'Page Creation',
                    icon: Icons.auto_stories_rounded,
                    children: [
                      //Page Image Preview.
                      StoryImagePreviewFrame(
                        imagePath: pageImagePath,
                        isZoomed: isPageImageZoomed,

                        //Controls page scrolling while interacting with the zoomed image.
                        onZoomInteractionChanged: handleZoomInteractionChanged,

                        onZoomPressed: () {
                          setState(() {
                            isPageImageZoomed = !isPageImageZoomed;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      //Select Page Image Button.
                      ElevatedButton.icon(
                        //Imported button style.
                        style: ButtonStyles.secondaryParentButton,
                        onPressed: pickPageImage,
                        icon: const Icon(Icons.image_rounded),
                        label: Text(
                          pageImagePath.isEmpty
                              ? 'Select Page Image'
                              : 'Change Page Image',
                        ),
                      ),

                      const SizedBox(height: 16),

                      //Record Page Narration Button.
                      ElevatedButton.icon(
                        //Imported button style.
                        style: ButtonStyles.audioParentButton,

                        onPressed: () async {
                          //Stops any preview audio that may already be playing
                          //before opening the recording bottom sheet.
                          await stopAllPreviewAudio();

                          //Stops the function if the page is no longer active.
                          if (!context.mounted) {
                            return;
                          }

                          //Opens recording bottom sheet.
                          //It returns an AudioRecording object.
                          final recording = await showRecordingBottomSheet(
                            context,
                          );

                          //Stops the function if the page is no longer active.
                          if (!mounted) {
                            return;
                          }

                          if (recording != null) {
                            setState(() {
                              audioPath = recording.audioPath;
                              audioDuration = recording.audioDuration;
                            });
                          }
                        },
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text('Record Narration'),
                      ),

                      const SizedBox(height: 16),

                      //Audio status container.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          //Changes container background color depending
                          //on audio existence.
                          color: audioPath.isEmpty
                              ? AppColors.disabled.withValues(alpha: 0.08)
                              : AppColors.appText.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: 1.2,
                            color: audioPath.isEmpty
                                ? AppColors.disabled.withValues(alpha: 0.4)
                                : AppColors.appText.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //Audio Recording Status Icon.
                            Icon(
                              //Changes status icon depending
                              //on audio existence.
                              audioPath.isEmpty
                                  ? Icons.mic_off_rounded
                                  : Icons.check_circle_rounded,
                              color: audioPath.isEmpty
                                  ? AppColors.disabled
                                  : AppColors.appText,
                            ),

                            const SizedBox(width: 10),

                            Text(
                              //Changes status text depending
                              //on audio existence.
                              audioPath.isEmpty
                                  ? 'No Narration Recorded'
                                  : 'Narration Recorded',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: audioPath.isEmpty
                                    //Changes status text color depending
                                    //on audio existence.
                                    ? AppColors.disabled
                                    : AppColors.appText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      //Pages counter.
                      //Shows the number of added pages to the current story.
                      Center(
                        child: Chip(
                          avatar: const Icon(
                            Icons.auto_stories_rounded,
                            color: AppColors.appText,
                          ),
                          label: Text('${pages.length} pages added.'),
                          labelStyle: const TextStyle(
                            color: AppColors.appText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      //Add Page Button.
                      ElevatedButton.icon(
                        //Imported button style.
                        style: ButtonStyles.primaryParentButton,

                        //Adds the current page to the pages list.
                        onPressed: addPage,

                        icon: const Icon(Icons.add_circle_rounded),
                        label: const Text('Add Page'),
                      ),
                    ],
                  ),

                  //3. Section Card: Background Music.
                  SectionCard(
                    title: 'Background Music',
                    icon: Icons.music_note_rounded,
                    children: [
                      const SizedBox(height: 5),
                      //Background Music Dropdown.
                      DropdownButtonFormField<String>(
                        //Selected background music path.
                        initialValue: selectedBackgroundMusic,

                        decoration: InputDecoration(
                          labelStyle: const TextStyle(
                            color: AppColors.appText,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),

                        items: backgroundMusicList.map((backgroundMusic) {
                          return DropdownMenuItem<String>(
                            value: backgroundMusic.musicPath,

                            //The title that is being displayed inside the dropdown
                            child: Text(backgroundMusic.title),
                          );
                        }).toList(),

                        onChanged: (value) async {
                          //If no value is selected, the function stops.
                          if (value == null) {
                            return;
                          }

                          //Stops any preview audio that may already be playing.
                          await stopAllPreviewAudio();

                          //Stops the function if the page is no longer active.
                          if (!mounted) {
                            return;
                          }

                          //Stores  the selected background music path.
                          setState(() {
                            selectedBackgroundMusic = value;
                          });
                        },
                      ),
                    ],
                  ),

                  //4. Section Card: Preview Carousel.

                  //Shows the selection card if there is at least
                  //one page added to the story.
                  if (pages.isNotEmpty) ...[
                    SectionCard(
                      title: 'Story Pages Preview',
                      icon: Icons.view_carousel_rounded,
                      children: [
                        SizedBox(
                          height: 310,
                          //Stacks left and right arrows in front of the preview page.
                          child: Stack(
                            alignment: Alignment.center,

                            children: [
                              //Creates a swipeable carousel.
                              PageView.builder(
                                //Controls the PageView movements.
                                controller: pagePreviewController,

                                //Disables carousel swiping while the image is zoomed.
                                //It prevents the user from changing to another page accidentally.
                                physics: isCarouselImageZoomed
                                    ? const NeverScrollableScrollPhysics()
                                    : const PageScrollPhysics(),

                                itemCount: pages.length,
                                onPageChanged: changePreviewPage,
                                //Builds each preview page.
                                itemBuilder: (context, index) {
                                  //Gets the StoryPage object at the current index.
                                  final StoryPage page = pages[index];

                                  return Column(
                                    children: [
                                      //Selected page image preview.
                                      StoryImagePreviewFrame(
                                        imagePath: page.pageImage,
                                        isZoomed: isCarouselImageZoomed,

                                        //Controls page scrolling while interacting with the zoomed image.
                                        onZoomInteractionChanged:
                                            handleZoomInteractionChanged,

                                        onZoomPressed: () {
                                          setState(() {
                                            isCarouselImageZoomed =
                                                !isCarouselImageZoomed;
                                          });
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      //Page Number Chip.
                                      Chip(
                                        avatar: const Icon(
                                          Icons.auto_stories_rounded,
                                          color: AppColors.appText,
                                          size: 18,
                                        ),

                                        //Shows the number of the current page preview
                                        //out of the total number of added pages.
                                        label: Text(
                                          'Page ${index + 1} of ${pages.length}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        labelStyle: const TextStyle(
                                          color: AppColors.appText,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      //Shows the audio duration of the current page preview.
                                      Text(
                                        //Formats seconds into MM:SS format.
                                        'Narration duration: ${formatTime(page.pageAudioDuration)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.appText,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              //Left Arrow.

                              //Shows Left Arrow only when there is more than one page
                              //and the selected page is not the first page.
                              if (pages.length > 1 && selectedPageIndex > 0)
                                Positioned(
                                  left: 0,
                                  top:
                                      StoryImagePreviewFrame
                                          .previewFrameHeight +
                                      16,
                                  child: CircleAvatar(
                                    backgroundColor: AppColors.parentPrimary
                                        .withValues(alpha: 0.5),
                                    child: IconButton(
                                      //Moves carousel to the previous page.
                                      onPressed: goToPreviousPreviewPage,

                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                              //Right Arrow.
                              //Shows Right Arrow only when there is more than one page
                              //and the selected page is not the last page.
                              if (pages.length > 1 &&
                                  selectedPageIndex < pages.length - 1)
                                Positioned(
                                  right: 0,
                                  top:
                                      StoryImagePreviewFrame
                                          .previewFrameHeight +
                                      16,
                                  child: CircleAvatar(
                                    backgroundColor: AppColors.parentPrimary
                                        .withValues(alpha: 0.5),
                                    child: IconButton(
                                      //Moves carousel to the next page.
                                      onPressed: goToNextPreviewPage,

                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        //Audio Preview Container.
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.disabled.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  //Play/Pause Button.
                                  IconButton(
                                    iconSize: 56,
                                    color: AppColors.childMode,

                                    onPressed: () {
                                      //If the selected preview audio is playing,
                                      //the button pauses it.
                                      if (isPreviewPlaying) {
                                        pausePreviewAudio();
                                      }
                                      //If the selected preview audio is not playing,
                                      //the button starts the playback.
                                      else {
                                        playPreviewAudio();
                                      }
                                    },
                                    icon: Icon(
                                      //Changes dynamically the button icon between Play and Pause.
                                      isPreviewPlaying
                                          ? Icons.pause_circle_filled_rounded
                                          : Icons.play_circle_filled_rounded,
                                    ),
                                  ),

                                  //Expanded gives the audio player slider all the remaining horizontal space.
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),

                                      child: Column(
                                        children: [
                                          //Audio Player Slider.

                                          //Removes Slider's default horizontal padding.
                                          SliderTheme(
                                            data: SliderTheme.of(context)
                                                .copyWith(
                                                  padding: EdgeInsets.zero,
                                                ),
                                            child: Slider(
                                              min: 0,

                                              //If previewDuration is bigger than 0, it is used as the maximum
                                              //value of the audio player slider.
                                              //If previewDuration is 0, the maximum value becomes 1
                                              //to avoid errors.
                                              max:
                                                  previewDuration.inSeconds
                                                          .toDouble() >
                                                      0
                                                  ? previewDuration.inSeconds
                                                        .toDouble()
                                                  : 1,

                                              //The value of the slider is the current audio position.
                                              //clamp() prevents slider's value from becoming smaller than 0 and
                                              //bigger than the maximum audio duration.
                                              value: previewPosition.inSeconds
                                                  .toDouble()
                                                  .clamp(
                                                    0,
                                                    previewDuration.inSeconds
                                                                .toDouble() >
                                                            0
                                                        ? previewDuration
                                                              .inSeconds
                                                              .toDouble()
                                                        : 1,
                                                  ),

                                              activeColor:
                                                  AppColors.parentPrimary,
                                              inactiveColor: AppColors.disabled,

                                              onChanged: (value) async {
                                                //Changes current audio position to another position
                                                //by dragging the slider.
                                                await pagePreviewAudioPlayer
                                                    .seek(
                                                      Duration(
                                                        seconds: value.toInt(),
                                                      ),
                                                    );
                                              },
                                            ),
                                          ),

                                          //Audio Time Row.
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              //Current audio position.

                                              //Formats seconds into MM:SS format.
                                              Text(
                                                formatTime(
                                                  previewPosition.inSeconds,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),

                                              //Remaining audio time.

                                              //Formats seconds into MM:SS format.
                                              //clamp() prevents remaining time from becoming
                                              //smaller than 0 and bigger than tha maximum audio duration.
                                              Text(
                                                formatTime(
                                                  (pages[selectedPageIndex]
                                                              .pageAudioDuration -
                                                          previewPosition
                                                              .inSeconds)
                                                      .clamp(
                                                        0,
                                                        pages[selectedPageIndex]
                                                            .pageAudioDuration,
                                                      )
                                                      .toInt(),
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        //Change Selected Page Image Button.
                        ElevatedButton.icon(
                          style: ButtonStyles.secondaryParentButton,
                          onPressed: changeSelectedPagePreviewImage,
                          icon: const Icon(Icons.image_rounded),
                          label: const Text('Change Image'),
                        ),
                        const SizedBox(height: 16),

                        //Change Selected Page Audio Button.
                        ElevatedButton.icon(
                          style: ButtonStyles.audioParentButton,
                          onPressed: changeSelectedPagePreviewAudio,
                          icon: const Icon(Icons.mic_rounded),
                          label: const Text('Change Narration'),
                        ),

                        const SizedBox(height: 16),

                        //Delete Selected Page Button.
                        ElevatedButton.icon(
                          style: ButtonStyles.outlinedRedParentButton,
                          onPressed: deleteSelectedPage,
                          icon: const Icon(Icons.delete_rounded),
                          label: const Text('Delete Page'),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  //Save Story Button.
                  ElevatedButton.icon(
                    //Imported button style.
                    style: ButtonStyles.primaryParentButton,

                    onPressed: () async {
                      //Gets the story title from the TextField.
                      //trim() removes the spaces from the
                      //beginning and the end of title.
                      final storyTitle = _titleController.text.trim();

                      //Checks if story title is empty.
                      //If it is empty, it shows the appropriate
                      //message at the bottom of the screen.
                      if (storyTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a story title.'),
                          ),
                        );
                        return;
                      }
                      //Checks if the cover Image path is empty.
                      //If it is empty, it shows the appropriate
                      //message at the bottom of the screen.
                      if (coverImagePath.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a cover image.'),
                          ),
                        );
                        return;
                      }

                      //Checks if there is an unfinished page that is not added to the story yet.
                      if (pageImagePath.isNotEmpty || audioPath.isNotEmpty) {
                        final bool? discardPage = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('Unfinished Page'),
                            content: Text(
                              'The current page has not been added to the story. '
                              'Do you want to discard it?',
                            ),
                            actions: [
                              //Cancel Button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text('Cancel'),
                              ),

                              //Discard Current Page Button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: Text(
                                  'Discard Page',
                                  style: TextStyle(color: AppColors.appText),
                                ),
                              ),
                            ],
                          ),
                        );

                        //Stops the function if the page is no longer active.
                        if (!context.mounted) {
                          return;
                        }

                        //Stops saving process if the user decides
                        //to keep the unfinished page.
                        if (discardPage != true) {
                          return;
                        }

                        //Clears the unfinished page.
                        setState(() {
                          pageImagePath = '';
                          audioPath = '';
                          audioDuration = 0;
                          isPageImageZoomed = false;
                        });
                      }

                      //Checks if story has at least one added page.
                      //If there are no pages, it shows the appropriate
                      //message at the bottom of the screen.
                      if (pages.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please add at least one page before saving.',
                            ),
                          ),
                        );
                      } else {
                        //Shows save confirmation dialog
                        //to prevent story creation by mistake.
                        final bool? confirmSaveStory = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('Save Story'),
                            content: Text(
                              'Are you sure you want to save this story?',
                            ),
                            actions: [
                              //Cancel Button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text('Cancel'),
                              ),

                              //Confirm save button.
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    color: AppColors.parentPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                        //Stops the function if the page is no longer active.
                        if (!context.mounted) {
                          return;
                        }

                        //If the user cancels the alert dialog, the function stops.
                        if (confirmSaveStory != true) {
                          return;
                        }

                        //Creates a new Story object with the entered values.
                        final newStory = Story(
                          title: storyTitle,
                          coverImage: coverImagePath,
                          pages: pages,
                          backgroundMusic: selectedBackgroundMusic,
                        );

                        //Closes the page and returns the newly created
                        //story to the previous page.
                        Navigator.pop(context, newStory);
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Story'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
