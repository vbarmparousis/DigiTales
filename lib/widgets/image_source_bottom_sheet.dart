//Package Imports
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

//My Imports
import '../theme/app_colors.dart';
import '../theme/button_styles.dart';

//Image source bottom sheet popup.
//Returns the selected image source between gallery image and camera photo.
Future<ImageSource?> showImageSourceBottomSheet(BuildContext context) async {
  //Opens a bottom sheet with two options.
  final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              //Column takes only the minimum height needed.
              mainAxisSize: MainAxisSize.min,
              //Column stretches widgets horizontally.
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                const Text(
                  'Choose Image Source',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.appText,
                  ),
                ),
                const SizedBox(height: 20),

                //Gallery Button.
                ElevatedButton.icon(
                  style: ButtonStyles.primaryParentButton,
                  //Closes the bottom sheet and returns gallery as selected source.
                  onPressed: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Choose from Gallery'),
                ),

                const SizedBox(height: 20),

                //Camera Button.
                ElevatedButton.icon(
                  style: ButtonStyles.secondaryParentButton,
                  //Closes the bottom sheet and returns camera as selected source.
                  onPressed: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Take a Photo'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  //Returns the selected image source.
  //If the bottom sheet closes, it returns null.
  return selectedSource;
}
