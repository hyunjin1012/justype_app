import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  // Define a variable to hold the current theme mode
  ThemeMode _themeMode = ThemeMode.light;

  // Define a variable to hold the accent color
  Color _accentColor = Colors.blue; // Default accent color

  // Define a variable to hold the speech rate
  double _speechRate = 1.0; // Default speech rate

  // Define a variable to hold the font size
  double _fontSize = 1.0; // Default font size

  // Getter for the current theme mode
  ThemeMode get themeMode => _themeMode;

  // Getter for the accent color
  Color get accentColor => _accentColor;

  // Getter to check if the current theme is dark mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Getter for the speech rate
  double get speechRate => _speechRate;

  // Getter for the font size
  double get fontSize => _fontSize;

  // Method to toggle between light and dark themes
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Method to set a specific theme mode
  void setTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
  }

  // Method to set the accent color
  void setAccentColor(Color color) {
    _accentColor = color;
    notifyListeners();
  }

  // Method to set the speech rate
  void setSpeechRate(double rate) {
    _speechRate = rate;
    notifyListeners();
  }

  // Method to set the font size
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  // Method to get the current theme data
  ThemeData getThemeData() {
    return themeMode == ThemeMode.dark ? darkTheme : lightTheme;
  }

  // Define your light theme
  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _accentColor, // Use accent color
      // Add other theme properties as needed
    );
  }

  // Define your dark theme
  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _accentColor, // Use accent color
      // Add other theme properties as needed
    );
  }
}
