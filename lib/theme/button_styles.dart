//Package Imports
import 'package:flutter/material.dart';

//My Imports
import '../theme/app_colors.dart';

//Reusable button styles class.
class ButtonStyles {
  static const double _buttonHeight = 56;

  static const double _buttonRadius = 16;

  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 14,
  );

  static const TextStyle _buttonTextStyle = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  //Reusable button styles.

  //Filled Button Style.
  static ButtonStyle _filledButtonStyle({
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: const Size(double.infinity, _buttonHeight),
      padding: _buttonPadding,
      elevation: 2,
      textStyle: _buttonTextStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
    );
  }

  //Outlined Button Style.
  static ButtonStyle _outlinedButtonStyle({required Color color}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      minimumSize: const Size(double.infinity, _buttonHeight),
      padding: _buttonPadding,
      elevation: 2,
      textStyle: _buttonTextStyle,
      side: BorderSide(color: color, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_buttonRadius),
      ),
    );
  }

  //Parent Mode Buttons.

  //Primary Parent Buttons.
  static final ButtonStyle primaryParentButton = _filledButtonStyle(
    backgroundColor: AppColors.parentPrimary,
  );

  //Secondary Parent Buttons.
  static final ButtonStyle secondaryParentButton = _filledButtonStyle(
    backgroundColor: AppColors.parentSecondary,
  );

  //Audio Parent Buttons.
  static final ButtonStyle audioParentButton = _filledButtonStyle(
    backgroundColor: AppColors.childMode,
  );

  //Outlined Red Parent Buttons.
  static final ButtonStyle outlinedRedParentButton = _outlinedButtonStyle(
    color: AppColors.danger,
  );
}
