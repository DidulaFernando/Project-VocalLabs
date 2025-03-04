// lib/main.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

// Screens
import 'package:vocallabs_flutter_app/screens/splash_screen.dart';
import 'package:vocallabs_flutter_app/screens/landing_screen.dart';
import 'package:vocallabs_flutter_app/screens/login_screen.dart';
import 'package:vocallabs_flutter_app/screens/registration_screen.dart';
import 'package:vocallabs_flutter_app/screens/home_screen.dart';
import 'package:vocallabs_flutter_app/screens/audio_recording_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_playback_screen.dart';
import 'package:vocallabs_flutter_app/screens/feedback_screen.dart';
import 'package:vocallabs_flutter_app/screens/profile_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_history_screen.dart';
import 'package:vocallabs_flutter_app/screens/progress_dashboard_screen.dart';
import 'package:vocallabs_flutter_app/screens/filler_word_detection_screen.dart';
import 'package:vocallabs_flutter_app/screens/vocal_modulation_analysis_screen.dart';
import 'package:vocallabs_flutter_app/screens/settings_screen.dart';
import 'package:vocallabs_flutter_app/screens/theme_selector_screen.dart';
import 'package:vocallabs_flutter_app/screens/about_screen.dart';
import 'package:vocallabs_flutter_app/screens/contact_us_screen.dart';
import 'package:vocallabs_flutter_app/screens/notification_center_screen.dart';
import 'package:vocallabs_flutter_app/screens/tutorial_help_screen.dart';
import 'package:vocallabs_flutter_app/screens/search_screen.dart';

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
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Poppins', // Make sure to add this font in pubspec.yaml
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryBlue,
          secondary: AppColors.accent,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const HomeScreen(),
        '/analysis': (context) => const AudioRecordingScreen(),
        '/playback': (context) => const SpeechPlaybackScreen(),
        '/playback_history':
            (context) => const SpeechPlaybackScreen(isFromHistory: true),
        '/feedback': (context) => const FeedbackScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/history': (context) => const SpeechHistoryScreen(),
        '/progress': (context) => const ProgressDashboardScreen(),
        '/filler_words': (context) => const FillerWordDetectionScreen(),
        '/vocal_modulation': (context) => const VocalModulationAnalysisScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/theme': (context) => const ThemeSelectorScreen(),
        '/about': (context) => const AboutScreen(),
        '/contact': (context) => const ContactUsScreen(),
        '/notifications': (context) => const NotificationCenterScreen(),
        '/tutorial': (context) => const TutorialHelpScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
