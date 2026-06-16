//Import Packages
import 'package:flutter/material.dart';

//Reusable button styles class.
class ButtonStyles {
  //Main teal button style.
  static ButtonStyle tealButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
  );

  //Audio action button style.
  static ButtonStyle audioButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
  );

  //Red delete button style.
  static ButtonStyle deleteButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade700,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 60),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
  );

  //Parent Mode Buttons

  //Primary Parent Buttons.
  static final ButtonStyle primaryParentButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    elevation: 2,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  //Secondary Parent Buttons.
  static final ButtonStyle secondaryParentButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.teal,
    minimumSize: const Size(double.infinity, 54),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.teal, width: 1.5),
    ),
    elevation: 0,
  );

  //Audio Parent Buttons.
  static final ButtonStyle audioParentButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
    minimumSize: const Size(double.infinity, 56),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    elevation: 2,
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  //Outlined Audio Parent Buttons.
  static final ButtonStyle outlinedAudioParentButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.deepPurple,
    minimumSize: const Size(double.infinity, 54),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.deepPurple, width: 1.5),
    ),
    elevation: 0,
  );

  //Outlined Red Parent Buttons.
  static final ButtonStyle outlinedRedParentButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.red,
    minimumSize: const Size(double.infinity, 54),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Colors.red, width: 1.5),
    ),
    elevation: 0,
  );
}
