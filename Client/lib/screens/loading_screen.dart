import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/loading_game.dart'; // Add this import
import 'dart:async';

class LoadingScreen extends StatefulWidget {
  final String message;
  final Map<String, dynamic>? apiResponse;
  final VoidCallback onAnalysisButtonPressed; // Changed to non-nullable VoidCallback

  const LoadingScreen({
    super.key,
    this.message = 'Analyzing your speech...',
    this.apiResponse,
    required this.onAnalysisButtonPressed, // Made required
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String dots = '';
  late Timer dotsTimer;
  bool isAnalyzing = false;
  bool isComplete = false;

  @override
  void initState() {
    super.initState();
    dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        dots = dots.length >= 3 ? '' : dots + '.';
      });
    });

    // Set analyzing state after a delay
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !isComplete) {
        setState(() {
          isAnalyzing = true;
        });
      }
    });

    // Check if we already have an API response
    if (widget.apiResponse != null) {
      isComplete = true;
    }
  }

  @override
  void didUpdateWidget(LoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if API response was received
    if (widget.apiResponse != null && !isComplete) {
      setState(() {
        isComplete = true;
        isAnalyzing = false;
      });
    }
  }

  String get loadingMessage {
    if (isComplete) {
      return 'Analysis Complete!';
    }
    return isAnalyzing ? 'Analyzing speech' : 'Transcribing speech';
  }

  @override
  void dispose() {
    dotsTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isComplete) ...[
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.message,
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          loadingMessage,
                          style: AppTextStyles.body2,
                        ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            dots,
                            style: AppTextStyles.body2,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Show completion state
                    const Icon(
                      Icons.check_circle_outline,
                      color: AppColors.success,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analysis Complete!',
                      style: AppTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200, // Fixed width for the button
                      child: CustomButton(
                        text: 'Display Analysis',
                        onPressed: widget.onAnalysisButtonPressed,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Game positioned at bottom with safe area
          Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              bottom: MediaQuery.of(context).padding.bottom + 20.0,
            ),
            child: const LoadingGame(),
          ),
        ],
      ),
    );
  }
}
