//Package Imports
import 'package:flutter/material.dart';

//My Imports
import '../theme/app_colors.dart';

//Reusable card to separate the page in sections.
//It can be used with or without a title and icon.
class SectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry sectionCardPadding;
  final EdgeInsetsGeometry sectionCardMargin;
  final List<Widget> children;

  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.sectionCardPadding = const EdgeInsets.all(20),
    this.sectionCardMargin = const EdgeInsets.only(bottom: 20),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    //Checks if section has title and icon.
    final bool hasIconTitle = (title != null && icon != null);

    return Container(
      width: double.infinity,
      padding: sectionCardPadding,
      margin: sectionCardMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //Show title and icon only when both are provided.
          if (hasIconTitle) ...[
            Row(
              children: [
                Icon(icon, color: AppColors.appText, size: 28),

                const SizedBox(width: 12),

                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                    color: AppColors.appText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
          ],
          //Shows the content of the section card.
          ...children,
        ],
      ),
    );
  }
}
