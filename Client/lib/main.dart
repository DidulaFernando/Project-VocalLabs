// lib/main.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/screens/splash_screen.dart';
import 'package:vocallabs_flutter_app/screens/login_screen.dart';
import 'package:vocallabs_flutter_app/screens/registration_screen.dart';
import 'package:vocallabs_flutter_app/screens/home_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_analysis_screen.dart';
import 'package:vocallabs_flutter_app/screens/feedback_screen.dart';
import 'package:vocallabs_flutter_app/screens/progress_dashboard_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_history_screen.dart';
import 'package:vocallabs_flutter_app/screens/filler_word_detection_screen.dart';
import 'package:vocallabs_flutter_app/screens/vocal_modulation_analysis_screen.dart';
import 'package:vocallabs_flutter_app/screens/profile_screen.dart';
import 'package:vocallabs_flutter_app/screens/settings_screen.dart';
import 'package:vocallabs_flutter_app/screens/tutorial_help_screen.dart';
import 'package:vocallabs_flutter_app/screens/about_screen.dart';
import 'package:vocallabs_flutter_app/screens/contact_us_screen.dart';
import 'package:vocallabs_flutter_app/screens/notification_center_screen.dart';
import 'package:vocallabs_flutter_app/screens/theme_selector_screen.dart';
import 'package:vocallabs_flutter_app/screens/audio_recording_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_playback_screen.dart';
import 'package:vocallabs_flutter_app/screens/search_screen.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VocalLabs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins', // Make sure to add this font in pubspec.yaml
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkText),
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryBlue,
          secondary: AppColors.accent,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/analysis': (context) => const SpeechAnalysisScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/progress': (context) => const ProgressDashboardScreen(),
        '/history': (context) => const SpeechHistoryScreen(),
        '/filler_words': (context) => const FillerWordDetectionScreen(),
        '/vocal_modulation': (context) => const VocalModulationAnalysisScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/tutorial': (context) => const TutorialHelpScreen(),
        '/about': (context) => const AboutScreen(),
        '/contact': (context) => const ContactUsScreen(),
        '/notifications': (context) => const NotificationCenterScreen(),
        '/themes': (context) => const ThemeSelectorScreen(),
        '/recording': (context) => const AudioRecordingScreen(),
        '/playback': (context) => const SpeechPlaybackScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
