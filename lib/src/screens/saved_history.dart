part of '../../main.dart';

class SavedHistoryScreen extends StatefulWidget {
  const SavedHistoryScreen({
    super.key,
    required this.onOpen,
    required this.onStoreIdOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<bool> Function(String storeId) onStoreIdOpen;

  @override
  State<SavedHistoryScreen> createState() => _SavedHistoryScreenState();
}

class _SavedHistoryScreenState extends State<SavedHistoryScreen> {
  bool _showSavedStores = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedStores = const [];
  List<Map<String, dynamic>> _recommendationHistory = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedAndHistory();
  }

  String _formatDate(String? value) {
    if (value == null) return '날짜 없음';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  int _recommendationCount(Map<String, dynamic> item) {
    final aiResponse = item['ai_response'];
    if (aiResponse is Map) {
      final recommendations = aiResponse['recommendations'];
      if (recommendations is List) return recommendations.length;
      final flaskResponse = aiResponse['flask_response'];
      if (flaskResponse is Map) {
        final data = flaskResponse['data'];
        if (data is Map && data['recommendations'] is List) {
          return (data['recommendations'] as List).length;
        }
      }
    }
    return 0;
  }

  Future<void> _loadSavedAndHistory() async {
    if (!AppConfig.isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('saved_stores')
            .select(
              'id, created_at, stores(id, name, category, rating, price_range)',
            )
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('recommendation_history')
            .select('id, query, created_at, ai_response')
            .order('created_at', ascending: false)
            .limit(100),
      ]);

      if (!mounted) return;
      setState(() {
        _savedStores = (responses[0] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _recommendationHistory = (responses[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장/추천 기록을 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          Container(
            color: _surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('저장', style: theme.textTheme.headlineSmall),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadSavedAndHistory,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Pill(
                              label: '저장한 가게',
                              selected: _showSavedStores,
                              onTap: () =>
                                  setState(() => _showSavedStores = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Pill(
                              label: '추천 기록',
                              selected: !_showSavedStores,
                              onTap: () =>
                                  setState(() => _showSavedStores = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _alternate),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  ),
                ] else if (_showSavedStores) ...[
                  Row(
                    children: [
                      Text(
                        '총 ${_savedStores.length}곳',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.sort_rounded,
                        color: _secondaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '최신순',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_savedStores.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.bookmark_border_rounded,
                      title: '저장한 가게가 없어요',
                      message: '마음에 드는 가게를 저장하면 여기에 모아볼 수 있어요.',
                      actionLabel: '추천 받기',
                      onAction: () => widget.onOpen(AppScreen.aiChat),
                    )
                  else
                    ..._savedStores.map((item) {
                      final store = item['stores'];
                      final storeMap = store is Map
                          ? Map<String, dynamic>.from(store)
                          : <String, dynamic>{};
                      return _SavedStoreCard(
                        icon: Icons.restaurant_rounded,
                        name: storeMap['name'] as String? ?? '이름 없는 가게',
                        rating: (storeMap['rating'] ?? '-').toString(),
                        category: storeMap['category'] as String? ?? '카테고리 없음',
                        distance: _formatDate(item['created_at'] as String?),
                        price: storeMap['price_range'] as String? ?? '가격 정보 없음',
                        onTap: () async {
                          final storeId = storeMap['id']?.toString();
                          if (storeId == null || storeId.isEmpty) return;
                          final opened = await widget.onStoreIdOpen(storeId);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('가게 상세를 불러오지 못했어요.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    }),
                ] else ...[
                  Text('최근 추천 기록', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_recommendationHistory.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.history_rounded,
                      title: '추천 기록이 없어요',
                      message: 'AI 맞춤 검색을 사용하면 추천 기록이 저장돼요.',
                      actionLabel: '추천 받기',
                      onAction: () => widget.onOpen(AppScreen.aiChat),
                    )
                  else
                    ..._recommendationHistory.map((item) {
                      final count = _recommendationCount(item);
                      return _HistoryItem(
                        query: item['query'] as String? ?? '추천 요청',
                        date: _formatDate(item['created_at'] as String?),
                        result: count == 0 ? '추천 결과 저장됨' : '$count곳 추천',
                      );
                    }),
                ],
              ],
            ),
          ),
          _BottomNav(current: AppScreen.saved, onOpen: widget.onOpen),
        ],
      ),
    );
  }
}

class _SavedStoreCard extends StatelessWidget {
  const _SavedStoreCard({
    required this.icon,
    required this.name,
    required this.rating,
    required this.category,
    required this.distance,
    required this.price,
    required this.onTap,
  });
  final IconData icon;
  final String name;
  final String rating;
  final String category;
  final String distance;
  final String price;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _warning, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(' · $category · $distance'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(price, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      color: _surfaceVariant.withOpacity(0.50),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 30),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: actionLabel,
            compact: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.query,
    required this.date,
    required this.result,
  });
  final String query;
  final String date;
  final String result;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(icon: Icons.history_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(query, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '$date · $result',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
