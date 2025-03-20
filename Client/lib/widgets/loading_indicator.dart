// lib/widgets/loading_indicator.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingIndicator({super.key, this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: color ?? AppColors.primaryBlue),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: AppTextStyles.body2,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
