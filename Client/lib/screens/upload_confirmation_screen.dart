import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:file_selector/file_selector.dart'; // Use file_selector instead of file_picker
import 'dart:typed_data'; // Add this import
import 'package:vocallabs_flutter_app/widgets/card_layout.dart'; // Add missing import for CardLayout

class UploadConfirmationScreen extends StatelessWidget {
  const UploadConfirmationScreen({super.key});

  Future<void> _pickFile(BuildContext context, Map<String, String> speechDetails) async {
    const typeGroup = XTypeGroup(
      label: 'audio',
      extensions: ['mp3', 'wav', 'm4a'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

    if (file != null) {
      final Uint8List fileBytes = await file.readAsBytes();
      // Navigate to SpeechPlaybackScreen with the selected file bytes and speech details
      Navigator.pushReplacementNamed(
        context,
        '/playback',
        arguments: {
          'fileBytes': fileBytes,
          ...speechDetails,
        },
      );
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the speech details from arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String speechTopic = args?['topic'] as String? ?? '';
    final String speechType = args?['speechType'] as String? ?? 'Prepared Speech';
    final String expectedDuration = args?['duration'] as String? ?? '5–7 minutes';
    
    // Combine all details for passing to _pickFile
    final Map<String, String> speechDetails = {
      'topic': speechTopic,
      'speechType': speechType,
      'duration': expectedDuration,
    };
    
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
            const SizedBox(height: 16),
            
            // Display the speech details
            if (speechTopic.isNotEmpty) ...[
              CardLayout(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Speech Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.darkText,
                        ),
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        icon: Icons.subject,
                        label: 'Topic',
                        value: speechTopic,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.category,
                        label: 'Type',
                        value: speechType,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        icon: Icons.timer,
                        label: 'Expected Duration',
                        value: expectedDuration,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            CustomButton(
              text: 'Confirm Upload',
              onPressed: () => _pickFile(context, speechDetails),
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
  
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
