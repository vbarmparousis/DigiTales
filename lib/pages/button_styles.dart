//Import Packages
import 'package:flutter/material.dart';

//Reusable button styles
class ButtonStyles {

  //Main teal button style.
  static ButtonStyle tealButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35)
    ),
  );

  //Audio action button style.
  static ButtonStyle audioButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35)
    ),
  );

  //Red delete button style.
  static ButtonStyle deleteButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade700,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(35)
    ),
  );

}