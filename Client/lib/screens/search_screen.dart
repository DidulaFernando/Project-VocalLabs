import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _recentSearches = [
    {'term': 'filler words', 'type': 'search'},
    {'term': 'vocal range', 'type': 'search'},
    {'term': 'speed of speech', 'type': 'search'},
  ];
  final List<Map<String, dynamic>> _allItems = [
    {
      'title': 'Project Presentation',
      'type': 'speech',
      'date': 'Feb 25, 2025',
      'score': 78,
    },
    {
      'title': 'How to Reduce Filler Words',
      'type': 'tip',
      'date': 'Feb 24, 2025',
    },
    {
      'title': 'Speaking with Confidence',
      'type': 'article',
      'date': 'Feb 22, 2025',
    },
    {
      'title': 'Weekly Progress Report',
      'type': 'report',
      'date': 'Feb 21, 2025',
    },
    {
      'title': 'Toastmaster Introduction',
      'type': 'speech',
      'date': 'Feb 20, 2025',
      'score': 82,
    },
    {'title': 'Vocal Variety Exercises', 'type': 'tip', 'date': 'Feb 18, 2025'},
    {
      'title': 'Practice Session',
      'type': 'speech',
      'date': 'Feb 15, 2025',
      'score': 75,
    },
  ];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _searchResults = [];
      } else {
        _isSearching = true;
        _searchResults =
            _allItems.where((item) {
              return item['title'].toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  void _addToRecentSearches(String term) {
    if (term.isEmpty) return;

    setState(() {
      // Remove if already exists
      _recentSearches.removeWhere((item) => item['term'] == term);

      // Add to beginning
      _recentSearches.insert(0, {'term': term, 'type': 'search'});

      // Keep only most recent 5
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search speeches, tips, reports...',
            border: InputBorder.none,
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                    : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            _addToRecentSearches(value);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isSearching ? _buildSearchResults() : _buildRecentSearches(),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Searches', style: AppTextStyles.heading2),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _recentSearches.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final search = _recentSearches[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(search['term']),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _searchController.text = search['term'];
                    _addToRecentSearches(search['term']);
                  },
                );
              },
            ),
          ),
        ] else ...[
          const Expanded(child: Center(child: Text('No recent searches'))),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 8),
            const Text(
              'Try different keywords or check your spelling',
              style: AppTextStyles.body2,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CardLayout(
            onTap: () {
              // Navigate based on item type
              if (item['type'] == 'speech') {
                Navigator.pushNamed(context, '/feedback');
              } else if (item['type'] == 'tip') {
                Navigator.pushNamed(context, '/filler_words');
              } else if (item['type'] == 'report') {
                Navigator.pushNamed(context, '/progress');
              } else {
                Navigator.pushNamed(context, '/tutorial');
              }
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getItemColor(item['type']).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getItemIcon(item['type']),
                      color: _getItemColor(item['type']),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getItemTypeLabel(item['type']),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getItemColor(item['type']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(' • '),
                          Text(item['date'], style: AppTextStyles.body2),
                          if (item['type'] == 'speech' &&
                              item['score'] != null) ...[
                            const Text(' • '),
                            Text(
                              'Score: ${item['score']}',
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.lightText),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getItemIcon(String type) {
    switch (type) {
      case 'speech':
        return Icons.mic;
      case 'tip':
        return Icons.lightbulb_outline;
      case 'article':
        return Icons.article_outlined;
      case 'report':
        return Icons.analytics_outlined;
      default:
        return Icons.file_present;
    }
  }

  Color _getItemColor(String type) {
    switch (type) {
      case 'speech':
        return AppColors.primaryBlue;
      case 'tip':
        return AppColors.warning;
      case 'article':
        return AppColors.accent;
      case 'report':
        return AppColors.success;
      default:
        return AppColors.primaryBlue;
    }
  }

  String _getItemTypeLabel(String type) {
    switch (type) {
      case 'speech':
        return 'SPEECH';
      case 'tip':
        return 'TIP';
      case 'article':
        return 'ARTICLE';
      case 'report':
        return 'REPORT';
      default:
        return type.toUpperCase();
    }
  }
}
