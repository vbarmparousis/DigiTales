import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_colors.dart';

//Image source bottom sheet popup.
//Returns the selected image source between gallery image and camera photo.
Future<ImageSource?> showImageSourceBottomSheet(BuildContext context) async {
  //Opens a bottom sheet with two options.
  final ImageSource? selectedSource = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),

          child: Column(
            //Column takes only the minimum height needed.
            mainAxisSize: MainAxisSize.min,
            //Column stretches widgets horizontally.
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const Text(
                'Select Image Source',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.parentPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.childMode,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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
      );
    },
  );

  //Returns the selected image source.
  //If the bottom sheet closes, it returns null.
  return selectedSource;
}
