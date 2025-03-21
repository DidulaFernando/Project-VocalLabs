// lib/screens/speech_history_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:intl/intl.dart';
import 'package:vocallabs_flutter_app/models/speech_model.dart';
import 'package:vocallabs_flutter_app/services/speech_storage_service.dart';

class SpeechHistoryScreen extends StatefulWidget {
  const SpeechHistoryScreen({super.key});

  @override
  State<SpeechHistoryScreen> createState() => _SpeechHistoryScreenState();
}

class _SpeechHistoryScreenState extends State<SpeechHistoryScreen> {
  List<SpeechModel> _speechHistory = [];
  List<SpeechModel> _filteredSpeeches = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpeeches();
  }

  Future<void> _loadSpeeches() async {
    setState(() {
      _isLoading = true;
    });
    
    final speeches = await SpeechStorageService.getSpeeches();
    
    setState(() {
      _speechHistory = speeches;
      _filteredSpeeches = List.from(speeches);
      _isLoading = false;
    });
  }

  void _filterSpeeches(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSpeeches = List.from(_speechHistory);
      } else {
        _filteredSpeeches = _speechHistory
            .where(
              (speech) => speech.topic.toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
              _showFilterOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search speeches...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: _filterSpeeches,
            ),
          ),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _filteredSpeeches.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No speeches recorded yet'
                                : 'No speeches matching "$_searchQuery"',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredSpeeches.length,
                      itemBuilder: (context, index) {
                        final speech = _filteredSpeeches[index];
                        return _buildSpeechHistoryItem(
                          title: speech.topic,
                          date: speech.recordedAt,
                          duration: _formatDuration(speech.duration ?? 0),
                          score: speech.score ?? 0,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechHistoryItem({
    required String title,
    required DateTime date,
    required String duration,
    required int score,
  }) {
    final formattedDate = _formatDate(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardLayout(
        onTap: () {
          Navigator.pushNamed(context, '/feedback');
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getScoreColor(score).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: _getScoreColor(score),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$formattedDate • $duration',
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Speeches', style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              _buildFilterOption(
                title: 'Most Recent',
                icon: Icons.access_time,
                onTap: () {
                  setState(() {
                    _filteredSpeeches.sort(
                      (a, b) => (b.recordedAt).compareTo(
                        a.recordedAt,
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                title: 'Highest Score',
                icon: Icons.trending_up,
                onTap: () {
                  setState(() {
                    _filteredSpeeches.sort(
                      (a, b) =>
                          (b.score ?? 0).compareTo(a.score ?? 0),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                title: 'Longest Duration',
                icon: Icons.timer,
                onTap: () {
                  setState(() {
                    _filteredSpeeches.sort((a, b) {
                      final durationA = a.duration ?? 0;
                      final durationB = b.duration ?? 0;
                      return durationB.compareTo(durationA);
                    });
                  });
                  Navigator.pop(context);
                },
              ),
              _buildFilterOption(
                title: 'Alphabetical',
                icon: Icons.sort_by_alpha,
                onTap: () {
                  setState(() {
                    _filteredSpeeches.sort(
                      (a, b) => (a.topic).compareTo(
                        b.topic,
                      ),
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 16),
            Text(title, style: AppTextStyles.body1),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final int totalSeconds = seconds.round();
    final int minutes = totalSeconds ~/ 60;
    final int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _parseDuration(String duration) {
    final parts = duration.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
