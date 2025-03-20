import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:file_selector/file_selector.dart'; // Use file_selector instead of file_picker
import 'dart:typed_data'; // Add this import

class UploadConfirmationScreen extends StatelessWidget {
  const UploadConfirmationScreen({super.key});

  Future<void> _pickFile(BuildContext context) async {
    const typeGroup = XTypeGroup(
      label: 'audio',
      extensions: ['mp3', 'wav', 'm4a'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      final Uint8List fileBytes = await file.readAsBytes();
      // Navigate to SpeechPlaybackScreen with the selected file bytes
      Navigator.pushReplacementNamed(
        context,
        '/playback',
        arguments: fileBytes,
      );
    } else {
      // User canceled the picker
    }
  }

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
              onPressed: () => _pickFile(context),
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
