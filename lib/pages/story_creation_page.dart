//Import Packages
import 'dart:io';
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

  //ImagePicker allows to pick an image from gallery.
  final ImagePicker imagePicker = ImagePicker();

  //Stores the local file path of the selected image.
  String coverImagePath = '';

  //Stores the local file path of the selected pages image.
  String pageImagePath = '';

  //Stores all pages of a story.
  List<StoryPage> pages = [];

  //String that stores the local file path
  //where the recorded audio file will be saved.
  String audioPath = '';

  //Stores audio duration in seconds.
  int audioDuration = 0;

  //Controls the story pages preview carousel
  final PageController pagePreviewController = PageController();

  //Page preview audio player.
  final AudioPlayer pagePreviewAudioPlayer = AudioPlayer();

  //Stores the selected page index
  int selectedPageIndex = 0;

  //Checks if selected page audio is being played.
  bool isPreviewPlaying = false;

  //Stores selected page audio duration.
  Duration previewDuration = Duration.zero;

  //Stores selected page audio position.
  Duration previewPosition = Duration.zero;

  //Formats seconds into MM:SS format.
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  //Initialization of Audio Listeners
  @override
  void initState() {
    super.initState();

    //Listens for audio state changes (playing, paused or stopped.)
    pagePreviewAudioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        //???Checks if the current audio player is playing.
        isPreviewPlaying = state == PlayerState.playing;
      });
    });

    //Audio Listener that detects changes on audio duration
    pagePreviewAudioPlayer.onDurationChanged.listen((newDuration) {
      //Keeps the longest valid duration.

      setState(() {
        previewDuration = newDuration;
      });
    });

    //Updates the current slider position
    //while the audio is being played
    pagePreviewAudioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        previewPosition = newPosition;
      });
    });

    //Audio Listener that detects when audio finishes completely.
    pagePreviewAudioPlayer.onPlayerComplete.listen((event) {
      //Stops audio and resets the slider position.
      setState(() {
        isPreviewPlaying = false;
        previewPosition = Duration.zero;
      });
      pagePreviewAudioPlayer.seek(Duration.zero);
    });
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

  //Opens device gallery and allows
  //user to pick an image for the current page of the story.
  Future<void> pickPageImage() async {
    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
      return;
    }

    //Stores the selected image file path and updates the UI.
    setState(() {
      pageImagePath = selectedImage.path;
    });
  }

  //Add a new page to the story.
  void addPage() {
    if (pageImagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a page image before adding a page.'),
        ),
      );
      return;
    }

    if (audioPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record audio before adding a new page.'),
        ),
      );
      return;
    }

    setState(() {
      pages.add(
        StoryPage(
          pageImage: pageImagePath,
          pageAudio: audioPath,
          pageAudioDuration: audioDuration,
        ),
      );

      //Clears page audio so the next page can record a new audio.
      pageImagePath = '';
      audioPath = '';
      audioDuration = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Page ${pages.length} added to the story.')),
    );
  }

  //Plays the selected page audio.
  Future<void> playPreviewAudio() async {
    if (pages.isEmpty) {
      return;
    }
    final selectedPageAudio = pages[selectedPageIndex].pageAudio;

    if (selectedPageAudio.isEmpty) {
      return;
    }
    await pagePreviewAudioPlayer.play(DeviceFileSource(selectedPageAudio));
  }

  //Pauses the selected page audio.
  Future<void> pausePreviewAudio() async {
    await pagePreviewAudioPlayer.pause();
  }

  //Changes preview page on carousel.
  Future<void> changePreviewPage(int index) async {
    await pagePreviewAudioPlayer.stop();

    setState(() {
      selectedPageIndex = index;
      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
    });
  }

  //Moves Carousel to previous page.
  Future<void> goToPreviousPreviewPage() async {
    if (selectedPageIndex <= 0) {
      return;
    }

    await pagePreviewController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //Moves Carousel to next page.
  Future<void> goToNextPreviewPage() async {
    if (selectedPageIndex >= pages.length - 1) {
      return;
    }

    await pagePreviewController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  //Changes selected page preview image.
  Future<void> changeSelectedPagePreviewImage() async {
    if (pages.isEmpty) {
      return;
    }

    final XFile? selectedImage = await imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    //If the image selection is canceled, stop the function.
    if (selectedImage == null) {
      return;
    }

    //Stores the selected image file path and updates the UI.
    setState(() {
      final StoryPage oldPage = pages[selectedPageIndex];

      pages[selectedPageIndex] = StoryPage(
        pageImage: selectedImage.path,
        pageAudio: oldPage.pageAudio,
        pageAudioDuration: oldPage.pageAudioDuration,
      );
    });
  }

  //Changes selected page preview audio.
  Future<void> changeSelectedPagePreviewAudio() async {
    if (pages.isEmpty) {
      return;
    }

    final recording = await showRecordingBottomSheet(context);

    if (recording == null) {
      return;
    }

    await pagePreviewAudioPlayer.stop();

    //Stores
    setState(() {
      final StoryPage oldPage = pages[selectedPageIndex];

      pages[selectedPageIndex] = StoryPage(
        pageImage: oldPage.pageImage,
        pageAudio: recording.audioPath,
        pageAudioDuration: recording.audioDuration,
      );

      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
    });
  }

  //Deletes the selected page.
  Future<void> deleteSelectedPage() async {
    if (pages.isEmpty) {
      return;
    }

    await pagePreviewAudioPlayer.stop();

    //
    setState(() {
      pages.removeAt(selectedPageIndex);

      if (pages.isEmpty) {
        selectedPageIndex = 0;
      } else if (selectedPageIndex >= pages.length) {
        selectedPageIndex = pages.length - 1;
      }

      isPreviewPlaying = false;
      previewDuration = Duration.zero;
      previewPosition = Duration.zero;
    });
  }

  @override
  //Clean Memory when Page Closes
  void dispose() {
    _titleController.dispose();
    //Free memory from page preview controller.
    pagePreviewController.dispose();
    //Free memory from page preview audio player.
    pagePreviewAudioPlayer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //Same Background as the Home Page
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: const Text('Create New Story'),
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
              SectionCard(
                title: 'Story Information',
                icon: Icons.info_rounded,
                children: [
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

                  //Cover Image Preview
                  if (coverImagePath.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.file(
                        File(coverImagePath),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )else
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

                  if (coverImagePath.isNotEmpty) const SizedBox(height: 20),

                  //Select Cover Image Button
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
                        fit: BoxFit.cover,
                      ),
                    )
                  else
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

                  //Select Page Image Button
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

                  //Audio status.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
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
                        Icon(
                          audioPath.isEmpty
                              ? Icons.mic_off_rounded
                              : Icons.check_circle_rounded,
                          color: audioPath.isEmpty ? Colors.grey : Colors.teal,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          audioPath.isEmpty
                              ? 'No audio recorded.'
                              : 'Audio recorded.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: audioPath.isEmpty
                                ? Colors.grey
                                : Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  //Pages counter.
                  Center(
                    child: Chip(
                      avatar: const Icon(Icons.auto_stories_rounded),
                      label: Text('${pages.length} pages added.'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  //Add Page Button
                  ElevatedButton.icon(
                    //Imported button style.
                    style: ButtonStyles.primaryParentButton,

                    onPressed: addPage,
                    icon: const Icon(Icons.add_circle_rounded),
                    label: const Text('Add Page'),
                  ),
                ],
              ),

              //Preview Carousel
              if (pages.isNotEmpty) ...[
                SectionCard(
                  title: 'Story Pages Preview',
                  icon: Icons.view_carousel_rounded,
                  children: [
                    SizedBox(
                      height: 270,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PageView.builder(
                            controller: pagePreviewController,
                            itemCount: pages.length,
                            onPageChanged: changePreviewPage,
                            itemBuilder: (context, index) {
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
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Chip(
                                    avatar: const Icon(
                                      Icons.auto_stories_rounded,
                                      size: 18,
                                    ),
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

                                  Text(
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
                          if (pages.length > 1 && selectedPageIndex > 0)
                            Positioned(
                              left: 0,
                              top: 175,
                              child: CircleAvatar(
                                backgroundColor: Colors.teal.withValues(
                                  alpha: 0.5,
                                ),
                                child: IconButton(
                                  onPressed: goToPreviousPreviewPage,
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                          //Right Arrow.
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
                      children: List.generate(pages.length, (index) {
                        final bool isSelected = index == selectedPageIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: isSelected ? 16 : 8,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.teal
                                : Colors.grey.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
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
                                  if (isPreviewPlaying) {
                                    pausePreviewAudio();
                                  } else {
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

                              //Audio Player Slider
                              Expanded(
                                child: Column(
                                  children: [
                                    Slider(
                                      min: 0,
                                      max:
                                          previewDuration.inSeconds.toDouble() >
                                              0
                                          ? previewDuration.inSeconds.toDouble()
                                          //: pages[selectedPageIndex].pageAudioDuration.toDouble() > 0
                                          //? pages[selectedPageIndex].pageAudioDuration.toDouble()
                                          : 1,
                                      //clamp() prevents slider from
                                      //exceeding duration limits.
                                      value: previewPosition.inSeconds.toDouble().clamp(
                                        0,
                                        previewDuration.inSeconds.toDouble() > 0
                                            ? previewDuration.inSeconds
                                                  .toDouble()
                                            //: pages[selectedPageIndex].pageAudioDuration.toDouble() > 0
                                            //? pages[selectedPageIndex].pageAudioDuration.toDouble()
                                            : 1,
                                      ),

                                      activeColor: Colors.teal,
                                      inactiveColor: Colors.grey,

                                      onChanged: (value) async {
                                        //Allows jumping to another position on slider.
                                        await pagePreviewAudioPlayer.seek(
                                          Duration(seconds: value.toInt()),
                                        );
                                      },
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatTime(previewPosition.inSeconds),
                                          style: const TextStyle(fontSize: 14),
                                        ),
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

                    //Change Selected Page Image Button
                    ElevatedButton.icon(
                      style: ButtonStyles.secondaryParentButton,
                      onPressed: changeSelectedPagePreviewImage,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Change Image'),
                    ),
                    const SizedBox(height: 16),

                    //Change Selected Page Audio Button
                    ElevatedButton.icon(
                      style: ButtonStyles.audioParentButton,
                      onPressed: changeSelectedPagePreviewAudio,
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('Change Audio'),
                    ),

                    const SizedBox(height: 12),

                    //Delete Selected Page Button
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

              //Save Story Button
              ElevatedButton.icon(
                //Imported button style.
                style: ButtonStyles.primaryParentButton,

                onPressed: () {
                  //trim() trims the spaces on the
                  //beginning and end of title.
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
                  } else if (coverImagePath.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please Select an Image Cover.'),
                      ),
                    );
                  } else if (pages.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please add at least one page before saving.',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Story Saved: $storyTitle')),
                    );

                    //Creates an new Story object with the entered values.
                    final newStory = Story(
                      title: storyTitle,
                      coverImage: coverImagePath,
                      pages: pages,
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
