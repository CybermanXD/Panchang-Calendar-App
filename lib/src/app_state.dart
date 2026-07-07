import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    this.textColor = 0xff402b25,
    this.backgroundColor = 0xfffffbf5,
    this.language = 'en',
  });

  final int textColor;
  final int backgroundColor;
  final String language;

  AppSettings copyWith({int? textColor, int? backgroundColor, String? language}) {
    return AppSettings(
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      language: language ?? this.language,
    );
  }
}

class AppState extends ChangeNotifier {
  AppSettings settings = const AppSettings();
  bool hasSeenWelcome = false;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
    settings = AppSettings(
      textColor: prefs.getInt('textColor') ?? settings.textColor,
      backgroundColor: prefs.getInt('backgroundColor') ?? settings.backgroundColor,
      language: prefs.getString('language') ?? settings.language,
    );
    notifyListeners();
  }

  Future<void> completeWelcome() async {
    hasSeenWelcome = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWelcome', true);
  }

  Future<void> setTextColor(int value) async {
    settings = settings.copyWith(textColor: value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('textColor', value);
  }

  Future<void> setBackgroundColor(int value) async {
    settings = settings.copyWith(backgroundColor: value);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('backgroundColor', value);
  }
}
