//Import Libraries
import 'dart:io';

//Import Packages
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

//My Imports
import '../models/story.dart';
import 'button_styles.dart';
import '../widgets/recording_bottom_sheet.dart';
import '../widgets/section_card.dart';

class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({super.key});

  @override
  State<StoryCreationPage> createState() => _StoryCreationPageState();
}

//Private Class (underscore: _)
class _StoryCreationPageState extends State<StoryCreationPage> {
  //Controls the story title TextField
  final TextEditingController _titleController = TextEditingController();

  //Allows to pick images from device gallery.
  final ImagePicker imagePicker = ImagePicker();

  //Stores the local file path of the selected cover image.
  String coverImagePath = '';

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

  //Stores the selected page index.
  int selectedPageIndex = 0;

  //Checks if the selected page audio is being played.
  //It is used to switch between Play and Pause buttons.
  bool isPreviewPlaying = false;

  //Stores the selected page audio duration.
  Duration previewDuration = Duration.zero;

  //Stores selected page audio playback position.
  Duration previewPosition = Duration.zero;

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

  //Runs once when the Page is first created.
  @override
  void initState() {
    super.initState();

    //Initialization of Audio Listeners.

    //Listens for audio state changes (playing, paused).
    pagePreviewAudioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        //If the audio player state is 'playing',
        //isPreviewPlaying becomes true.
        //Otherwise, isPreviewPlaying becomes false.
        isPreviewPlaying = state == PlayerState.playing;
      });
    });

    //Listens for changes in the selected page audio duration.
    pagePreviewAudioPlayer.onDurationChanged.listen((newDuration) {
      //Keeps the longest valid duration as the maximum duration
      //of the preview audio slider.
      setState(() {
        previewDuration = newDuration;
      });
    });

    //Listens for changes in the selected page audio position.
    pagePreviewAudioPlayer.onPositionChanged.listen((newPosition) {
      //Updates the current slider position while the audio is being played.
      setState(() {
        previewPosition = newPosition;
      });
    });

    //Listens for when the selected page audio finishes completely.
    pagePreviewAudioPlayer.onPlayerComplete.listen((event) {
      //Stops audio, audio button returns to 'Play'
      //and resets the audio slider position back to the beginning.
      setState(() {
        isPreviewPlaying = false;
        previewPosition = Duration.zero;
      });
      pagePreviewAudioPlayer.seek(Duration.zero);
    });
  }

  //Opens device gallery and allows the
  //user to pick a cover image for the story.
  Future<void> pickCoverImage() async {
    //Opens device gallery and waits for the user to pick a cover image.

    //The '?' in XFile is for when the user closes the device gallery
    //without picking a cover image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, the function stops.
    if (selectedImage == null) {
      return;
    }

    //Stores the selected image file path and updates the UI in order
    //to show the selected cover image.
    setState(() {
      coverImagePath = selectedImage.path;
    });
  }

  //Opens device gallery and allows the
  //user to pick an image for the current page of the story.
  Future<void> pickPageImage() async {
    //Opens device gallery and waits for the user to pick a page image.

    //The '?' in XFile is for when the user closes the device gallery
    //without picking a page image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, the function stops.
    if (selectedImage == null) {
      return;
    }

    //Stores the selected image file path and updates the UI in order
    //to show the selected page image.
    setState(() {
      pageImagePath = selectedImage.path;
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
          content: Text('Please record audio before adding a new page.'),
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

    //Plays the selected page audio from the local device file path.
    await pagePreviewAudioPlayer.play(DeviceFileSource(selectedPageAudio));
  }

  //Pauses the selected preview page audio.
  Future<void> pausePreviewAudio() async {
    //Pauses the current playback and keeps the current position,
    //so if the user presses play again, the audio continues from
    //the point it stopped.
    await pagePreviewAudioPlayer.pause();
  }

  //Changes the preview page on carousel everytime the user swipes
  //left or right.
  Future<void> changePreviewPage(int index) async {
    //Stops any preview audio that may already be playing.
    await pagePreviewAudioPlayer.stop();

    //Updates the UI by showing the next/previous story and resetting
    //the audio parameters.
    setState(() {
      selectedPageIndex = index;
      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
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

    //Opens device gallery and waits for the user to pick a new page image.

    //The '?' in XFile is for when the user closes the device gallery
    //without picking a new page image. (Nullable)
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
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
        pageImage: selectedImage.path,

        //Keeps the old audio and audio duration.
        pageAudio: oldPage.pageAudio,
        pageAudioDuration: oldPage.pageAudioDuration,
      );
    });
  }

  //Changes selected page preview audio.
  Future<void> changeSelectedPagePreviewAudio() async {
    //If there are no pages, the function stops.
    if (pages.isEmpty) {
      return;
    }

    //Opens recording bottom sheet.
    //It returns an AudioRecording object.
    final recording = await showRecordingBottomSheet(context);

    //If the audio recording is canceled, stop the function.
    if (recording == null) {
      return;
    }

    //Stops any preview audio that may already be playing.
    await pagePreviewAudioPlayer.stop();

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
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    //If the user cancels the alert dialog, the function stops.
    if (confirmDeletePage != true) {
      return;
    }

    //Stops any preview audio that may already be playing.
    await pagePreviewAudioPlayer.stop();

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
      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
    });
  }

  @override
  //Cleans memory when Page closes.
  void dispose() {
    //Disposes the title controller.
    _titleController.dispose();
    //Disposes the page controller used by the preview carousel.
    pagePreviewController.dispose();
    //Disposes the audio controller used by the preview carousel.
    pagePreviewAudioPlayer.dispose();
    //Calls the parent dispose method to complete the cleanup.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Everytime SetState() is called, this method runs and rebuilds the UI.
    return Scaffold(
      appBar: AppBar(
        //Same AppBar background as the Home Page.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: const Text('Create New Story'),
      ),

      //Allows page scroll and prevents overflow issues
      //when the keyboard appears.
      body: SingleChildScrollView(
        child: Padding(
          //Adds spacing so the UI doesn't touch the screen borders.
          padding: const EdgeInsets.all(24),
          child: Column(
            //Column stretches widgets vertically.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [


              //1. Section Card: Story Information (Title + Cover Image).
              SectionCard(
                title: 'Story Information',
                icon: Icons.info_rounded,
                children: [
                  const SizedBox(height: 15),
                  //Story Title Field.
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Enter Story Title',
                      labelStyle: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //Cover Image Preview.

                  //Displays the selected cover image.
                  if (coverImagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.file(
                        File(coverImagePath),
                        height: 160,
                        width: double.infinity,
                        //Crops image to fit the preview area.
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    //Default Image Placeholder.
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 70,
                        color: Colors.teal,
                      ),
                    ),

                  const SizedBox(height: 20),

                  //Select Cover Image Button.
                  ElevatedButton.icon(
                    //Imported button style.
                    style: ButtonStyles.primaryParentButton,
                    onPressed: pickCoverImage,
                    icon: const Icon(Icons.image_rounded),
                    label: Text(
                      coverImagePath.isEmpty
                          ? 'Select Cover Image'
                          : 'Select a new Cover Image',
                    ),
                  ),
                ],
              ),

              //2. Section Card: Page Creation.
              SectionCard(
                title: 'Current Page',
                icon: Icons.auto_stories_rounded,
                children: [
                  //Page Image Preview
                  if (pageImagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.file(
                        File(pageImagePath),
                        height: 160,
                        width: double.infinity,
                        //Crops image to fit the preview area.
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    //Default Image Placeholder.
                    Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.image_rounded,
                        size: 70,
                        color: Colors.teal,
                      ),
                    ),

                  const SizedBox(height: 20),

                  //Select Page Image Button.
                  ElevatedButton.icon(
                    //Imported button style.
                    style: ButtonStyles.primaryParentButton,
                    onPressed: pickPageImage,
                    icon: const Icon(Icons.image_rounded),
                    label: Text(
                      pageImagePath.isEmpty
                          ? 'Select Page Image'
                          : 'Select a new Page Image',
                    ),
                  ),

                  const SizedBox(height: 16),

                  //Record Page Audio Button.
                  ElevatedButton.icon(
                    //Imported button style.
                    style: ButtonStyles.audioParentButton,

                    onPressed: () async {
                      //Opens recording bottom sheet.
                      //It returns an AudioRecording object.
                      final recording = await showRecordingBottomSheet(context);

                      if (recording != null) {
                        setState(() {
                          audioPath = recording.audioPath;
                          audioDuration = recording.audioDuration;
                        });
                      }
                    },
                    icon: const Icon(Icons.mic_rounded),
                    label: const Text('Record Page Audio'),
                  ),

                  const SizedBox(height: 10),

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
                          ? Colors.grey.withValues(alpha: 0.08)
                          : Colors.teal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        width: 1.2,
                        color: audioPath.isEmpty
                            ? Colors.grey.withValues(alpha: 0.4)
                            : Colors.teal.withValues(alpha: 0.4),
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
                          color: audioPath.isEmpty ? Colors.grey : Colors.teal,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          //Changes status text depending
                          //on audio existence.
                          audioPath.isEmpty
                              ? 'No audio recorded.'
                              : 'Audio recorded.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: audioPath.isEmpty
                                //Changes status text color depending
                                //on audio existence.
                                ? Colors.grey
                                : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //Pages counter.
                  //Shows the number of added pages to the current story.
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.auto_stories_rounded),
                      label: Text('${pages.length} pages added.'),
                    ),
                  ),

                  const SizedBox(height: 20),

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

              //3. Section Card: Preview Carousel.

              //Shows the selection card if there is at least
              //one page added to the story.
              if (pages.isNotEmpty) ...[
                SectionCard(
                  title: 'Story Pages Preview',
                  icon: Icons.view_carousel_rounded,
                  children: [
                    SizedBox(
                      height: 270,
                      //Stacks left and right arrows in front of the preview page.
                      child: Stack(
                        alignment: Alignment.center,

                        children: [
                          //Creates a swipeable carousel.
                          PageView.builder(
                            //Controls the PageView movements.
                            controller: pagePreviewController,

                            itemCount: pages.length,
                            onPageChanged: changePreviewPage,
                            //Builds each preview page.
                            itemBuilder: (context, index) {
                              //Gets the StoryPage object at the current index.
                              final StoryPage page = pages[index];

                              return Column(
                                children: [
                                  //Selected page image preview.
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.file(
                                      File(page.pageImage),
                                      height: 160,
                                      width: double.infinity,
                                      //Crops image to fit the preview area.
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  //Page Number Chip.
                                  Chip(
                                    avatar: const Icon(
                                      Icons.auto_stories_rounded,
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
                                  ),

                                  const SizedBox(height: 8),

                                  //Shows the audio duration of the current page preview.
                                  Text(
                                    //Formats seconds into MM:SS format.
                                    'Audio duration: ${formatTime(page.pageAudioDuration)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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
                              top: 175,
                              child: CircleAvatar(
                                backgroundColor: Colors.teal.withValues(
                                  alpha: 0.5,
                                ),
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
                              top: 175,
                              child: CircleAvatar(
                                backgroundColor: Colors.teal.withValues(
                                  alpha: 0.5,
                                ),
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

                    //Page Indicator Dots.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      //Creates one dot for every added page.
                      children: List.generate(pages.length, (index) {
                        //Checks if the dot represents the selected story preview.
                        final bool isSelected = index == selectedPageIndex;

                        //Page Indicator Dots Animation.
                        return AnimatedContainer(
                          //The duration of the animation.
                          duration: const Duration(milliseconds: 250),

                          //Horizontal spacing between dots.
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          //selected dot is wider than the others.
                          width: isSelected ? 16 : 8,
                          decoration: BoxDecoration(
                            //Changes selected dot's color to differentiate it
                            //from the rest.
                            color: isSelected
                                ? Colors.teal
                                : Colors.grey.withValues(alpha: 0.35),
                            //Makes dot rounded.
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    //Audio Preview Container.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25),
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
                                color: Colors.orange,

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
                                child: Column(
                                  children: [
                                    //Audio Player Slider.
                                    Slider(
                                      min: 0,

                                      //If previewDuration is bigger than 0, it is used as the maximum
                                      //value of the audio player slider.
                                      //If previewDuration is 0, the maximum value becomes 1
                                      //to avoid errors.
                                      max:
                                          previewDuration.inSeconds.toDouble() >
                                              0
                                          ? previewDuration.inSeconds.toDouble()
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
                                                ? previewDuration.inSeconds
                                                      .toDouble()
                                                : 1,
                                          ),

                                      activeColor: Colors.teal,
                                      inactiveColor: Colors.grey,

                                      onChanged: (value) async {
                                        //Changes current audio position to another position
                                        //by dragging the slider.
                                        await pagePreviewAudioPlayer.seek(
                                          Duration(seconds: value.toInt()),
                                        );
                                      },
                                    ),

                                    //Audio Time Row.
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        //Current audio position.

                                        //Formats seconds into MM:SS format.
                                        Text(
                                          formatTime(previewPosition.inSeconds),
                                          style: const TextStyle(fontSize: 14),
                                        ),

                                        //Remaining audio time.

                                        //Formats seconds into MM:SS format.
                                        //clamp() prevents remaining time from becoming
                                        //smaller than 0 and bigger than tha maximum audio duration.
                                        Text(
                                          formatTime(
                                            (previewDuration - previewPosition)
                                                .inSeconds
                                                .clamp(
                                                  0,
                                                  previewDuration.inSeconds,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                      label: const Text('Change Audio'),
                    ),

                    const SizedBox(height: 12),

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
                        content: Text('Please Enter a Story Title.'),
                      ),
                    );
                  }
                  //Checks if the cover Image path is empty.
                  //If it is empty, it shows the appropriate
                  //message at the bottom of the screen.
                  else if (coverImagePath.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please Select an Image Cover.'),
                      ),
                    );
                  }
                  //Checks if story has at least one page.
                  //If there are no pages, it shows the appropriate
                  //message at the bottom of the screen.
                  else if (pages.isEmpty) {
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
                              style: TextStyle(color: Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    );

                    //If the user cancels the alert dialog, the function stops.
                    if (confirmSaveStory != true) {
                      return;
                    }

                    //Creates an new Story object with the entered values.
                    final newStory = Story(
                      title: storyTitle,
                      coverImage: coverImagePath,
                      pages: pages,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Story saved: $storyTitle')),
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
    );
  }
}
