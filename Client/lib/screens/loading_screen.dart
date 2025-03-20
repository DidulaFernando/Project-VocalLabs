import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

class LoadingScreen extends StatelessWidget {
  final String message;

  const LoadingScreen({
    super.key,
    this.message = 'Analyzing your speech...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              strokeWidth: 4,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'This might take a few moments',
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
