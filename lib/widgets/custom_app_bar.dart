import 'package:flutter/material.dart';

//Reusable AppBar that allows every page to
//choose its own background and text colors.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  final Color backgroundColor;
  final Color foregroundColor;
  final Color textColor;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,

      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 25,
        fontWeight: FontWeight.bold,
        fontFamily: 'Nunito',
      ),

      //Automatically shows back arrow when there is a previous page.
      automaticallyImplyLeading: true,
    );
  }

  //Tells Scaffold how tall the custom AppBar is.
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
