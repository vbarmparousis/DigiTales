//Library Imports
import 'dart:io';

//Package Imports
import 'package:flutter/material.dart';

//My Imports
import '../theme/app_colors.dart';

class StoryImagePreviewFrame extends StatelessWidget {
  final String imagePath;
  final bool isZoomed;
  final VoidCallback onZoomPressed;

  //Notifies the containing page when the user starts or stops interacting
  //directly with the zoomed image.
  final ValueChanged<bool>? onZoomInteractionChanged;

  final Color frameColor;

  const StoryImagePreviewFrame({
    super.key,
    required this.imagePath,
    required this.isZoomed,
    required this.onZoomPressed,
    this.onZoomInteractionChanged,
    this.frameColor = AppColors.parentPrimary,
  });

  //Height of the portrait image shown in normal preview mode.
  static const double previewImageHeight = 200;

  //Space between the inner portrait image
  //and the outer landscape frame.
  static const double previewInnerPadding = 10;

  //Height of the outer landscape frame.
  static const double previewFrameHeight =
      previewImageHeight + (previewInnerPadding * 2);

  //Portrait proportions of the image in the story book.
  static const double storyBookAspectRatio = 9 / 16;

  //Calculates the width of the image preview.
  static const double previewImageWidth =
      previewImageHeight * storyBookAspectRatio;

  //Creates the portrait image shown in normal preview mode.
  Widget buildPortraitImagePreview(String imagePath) {
    return Container(
      height: previewImageHeight,
      width: previewImageWidth,

      //Clips the image inside the rounded border.
      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: frameColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),

      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: frameColor.withValues(alpha: 0.75), width: 2),
      ),

      child: imagePath.isNotEmpty
          ? Image.file(
              File(imagePath),

              //Crops the image like the real story page.
              fit: BoxFit.cover,

              cacheWidth: 700,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,

              //Shows an icon if the image can't be loaded.
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: frameColor.withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 45,
                      color: frameColor == AppColors.parentPrimary
                          ? AppColors.appText.withValues(alpha: 0.75)
                          : AppColors.parentMode.withValues(alpha: 0.75),
                    ),
                  ),
                );
              },
            )
          : Container(
              color: frameColor.withValues(alpha: 0.08),

              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 45,
                  color: frameColor == AppColors.parentPrimary
                      ? AppColors.appText.withValues(alpha: 0.75)
                      : AppColors.parentMode.withValues(alpha: 0.75),
                ),
              ),
            ),
    );
  }

  //Creates a full-frame draggable image preview.
  //The selected image is resized to fit the width of the landscape preview frame.
  //If the resized image is taller than the landscape frame, it becomes
  //vertically draggable.
  Widget buildZoomedImagePreview(String imagePath) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          //Keeps the image at its original scale.
          minScale: 1,
          maxScale: 1,
          //Allows the image to be moved.
          panEnabled: true,
          //Disables pinch to zoom.
          scaleEnabled: false,

          //Allows portrait image to be taller than the frame.
          constrained: false,

          //Prevents the image from appearing outside the frame.
          clipBehavior: Clip.hardEdge,

          boundaryMargin: EdgeInsets.zero,
          alignment: Alignment.center,

          child: Image.file(
            File(imagePath),

            //Makes the image exactly as wide as the landscape frame.
            width: constraints.maxWidth,

            //The height of the image is adjusted while the image keeps its original proportions.
            fit: BoxFit.fitWidth,

            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,

            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: frameColor.withValues(alpha: 0.08),
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 45,
                    color: frameColor == AppColors.parentPrimary
                        ? AppColors.appText.withValues(alpha: 0.75)
                        : AppColors.parentMode.withValues(alpha: 0.75),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      //Notifies the containing page when an interaction
      //starts directly on a zoomed image frame.
      onPointerDown: (_) {
        if (isZoomed) {
          onZoomInteractionChanged?.call(true);
        }
      },
      //Re-enables page scrolling when the interaction ends.
      onPointerUp: (_) {
        onZoomInteractionChanged?.call(false);
      },
      //Re-enables page scrolling if the interaction is cancelled.
      onPointerCancel: (_) {
        onZoomInteractionChanged?.call(false);
      },

      child: Container(
        height: previewFrameHeight,
        width: double.infinity,

        //Keeps the content inside the rounded landscape frame.
        clipBehavior: Clip.antiAlias,

        decoration: BoxDecoration(
          color: frameColor == AppColors.parentPrimary
              ? AppColors.appBackground
              : AppColors.listCard,
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: frameColor.withValues(alpha: 0.75),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: isZoomed && imagePath.isNotEmpty
                  //No padding in zoom mode.
                  ? buildZoomedImagePreview(imagePath)
                  //Normal mode keeps the padding around the portrait preview.
                  : Padding(
                      padding: const EdgeInsets.all(previewInnerPadding),
                      child: Center(
                        child: buildPortraitImagePreview(imagePath),
                      ),
                    ),
            ),

            //Zoom Button.
            Positioned(
              right: 8,
              bottom: 8,

              child: Material(
                //The Zoom Button appears disabled when there is no image.
                color: imagePath.isEmpty ? AppColors.disabled : frameColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                //Clips the button ripple effect to the button's shape.
                clipBehavior: Clip.antiAlias,

                child: IconButton(
                  tooltip: imagePath.isEmpty
                      ? 'Select an image first'
                      : isZoomed
                      ? 'Close image zoom'
                      : 'Zoom image',

                  //The button is disabled when there is no image.
                  onPressed: imagePath.isEmpty ? null : onZoomPressed,

                  color: Colors.white,
                  disabledColor: Colors.white.withValues(alpha: 0.75),
                  icon: Icon(
                    isZoomed ? Icons.zoom_out_rounded : Icons.zoom_in_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
