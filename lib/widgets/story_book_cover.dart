//Library Imports.
import 'dart:io';

//Package Imports.
import 'package:flutter/material.dart';

//My Imports.
import '../theme/app_colors.dart';

//Reusable Story Book Cover.
//StoryTimePage: Full size version.
//ChildListPage: Miniature version.
//ParentListPage: Miniature version, no title.

class StoryBookCover extends StatelessWidget {
  final String title;

  final String imagePath;

  //Decoding width used by the cover image.
  final int imageCacheWidth;

  //Checks if the book cover should be full size or miniature mode.
  final bool isMiniatureMode;

  //Checks if the book cover should show the title on it or not.
  final bool showTitle;

  const StoryBookCover({
    super.key,
    required this.title,
    required this.imagePath,
    required this.imageCacheWidth,
    this.isMiniatureMode = false,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    //The parent list page uses miniature book cover without the title.
    final bool isParentListMode = isMiniatureMode && !showTitle;

    //Outer margin. In lists there is no need for outer margin.
    //Gridview provides spacing between books.
    final EdgeInsets outerMargin = isMiniatureMode
        ? EdgeInsets.zero
        : const EdgeInsets.all(8);

    final EdgeInsets innerPadding = isParentListMode
        ? const EdgeInsets.fromLTRB(4, 4, 4, 4)
        : isMiniatureMode
        ? const EdgeInsets.fromLTRB(8, 10, 8, 8)
        : const EdgeInsets.fromLTRB(16, 28, 16, 18);

    //Responsive measurements for full size and miniature mode covers.
    final double outerPadding = isParentListMode
        ? 1
        : isMiniatureMode
        ? 5
        : 8;
    final double outerBorderWidth = isMiniatureMode ? 3 : 4;
    final double outerRadius = 10;

    final double innerBorderWidth = isMiniatureMode ? 1.5 : 3;
    final double innerRadius = isMiniatureMode ? 7.5 : 10;
    final double imageRadius = isMiniatureMode ? 7.5 : 10;
    final double imageBorderWidth = isMiniatureMode ? 1 : 2;
    final double imageTitleSpacing = isMiniatureMode ? 8 : 18;

    return Container(
      //Cover page is bigger than the actual story pages.
      margin: outerMargin,

      //Creates spacing between outer and inner border.
      padding: EdgeInsets.all(outerPadding),

      decoration: BoxDecoration(
        //Leather like book cover color.
        color: AppColors.bookDarkBrown,

        //Outer decorative book border.
        border: Border.all(
          color: AppColors.bookDarkBrown,
          width: outerBorderWidth,
        ),

        borderRadius: BorderRadius.circular(outerRadius),
      ),

      //Creates the inner decorative frame of the cover.
      child: Container(
        padding: innerPadding,

        decoration: BoxDecoration(
          color: AppColors.bookDarkBrown,
          borderRadius: BorderRadius.circular(innerRadius),

          //Inner decorative book border.
          border: Border.all(
            color: AppColors.bookBrown,
            width: innerBorderWidth,
          ),
        ),

        //Responsive title size according to max width.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double titleFontSize = isMiniatureMode
                ? (constraints.maxWidth * 0.11).clamp(14.0, 18.0).toDouble()
                : (constraints.maxWidth * 0.095).clamp(28.0, 38.0).toDouble();

            return Column(
              children: [
                //Cover Image Section.
                Expanded(
                  flex: 10,
                  child: Container(
                    //Keeps the cover image inside the frame.
                    clipBehavior: Clip.antiAlias,

                    decoration: BoxDecoration(
                      color: AppColors.parentPrimary,
                      borderRadius: BorderRadius.circular(imageRadius),
                    ),
                    foregroundDecoration: BoxDecoration(
                      //Light border over the image.
                      borderRadius: BorderRadius.circular(imageRadius),
                      border: Border.all(
                        color: AppColors.bookCream,
                        width: imageBorderWidth,
                      ),
                    ),

                    //Cover Image.
                    child: Image.file(
                      File(imagePath),

                      fit: BoxFit.fitHeight,

                      cacheWidth: imageCacheWidth,

                      //Keeps the cover image stable during rebuilds.
                      gaplessPlayback: true,

                      filterQuality: FilterQuality.medium,

                      //Shows a fallback if the image is missing, damaged or cannot be decoded.
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.bookDarkBrown,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              size: isMiniatureMode ? 50 : 100,
                              color: AppColors.bookCream,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                //The title section is used by child library and story page,
                //but not by the parent list.
                if (showTitle) ...[
                  SizedBox(height: imageTitleSpacing),

                  //Story Title Section.
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMiniatureMode ? 2 : 8,
                      ),
                      child: Center(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,

                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: AppColors.bookCream,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            height: 1.10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
