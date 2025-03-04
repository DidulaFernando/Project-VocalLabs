import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

//to confirm the upload of the speech

class UploadConfirmationScreen extends StatelessWidget {
  const UploadConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Confirmation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: AppPadding.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Text('Confirm Upload', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to upload this speech for analysis?',
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Confirm Upload',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/feedback');
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Cancel',
              backgroundColor: Colors.grey,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
