part of '../../main.dart';

class AiPromotionHelperScreen extends StatefulWidget {
  const AiPromotionHelperScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<AiPromotionHelperScreen> createState() =>
      _AiPromotionHelperScreenState();
}

class _AiPromotionHelperScreenState extends State<AiPromotionHelperScreen> {
  final _eventController = TextEditingController();
  final _keywordsController = TextEditingController();
  List<DongNeuStore> _ownerStores = const [];
  List<Map<String, dynamic>> _promotionHistory = const [];
  String? _selectedStoreId;
  String _selectedTone = '친절한';
  String? _generatedCopy;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  @override
  void dispose() {
    _eventController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  String _formatDate(String? value) {
    if (value == null) return '날짜 없음';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  List<String> _keywordList() {
    return _keywordsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  DongNeuStore? get _selectedStore {
    for (final store in _ownerStores) {
      if (store.id == _selectedStoreId) return store;
    }
    return _ownerStores.isEmpty ? null : _ownerStores.first;
  }

  Future<void> _loadOwnerData() async {
    if (!AppConfig.isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('stores')
            .select(StoreQueries.storeSelectColumns)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('promotion_history')
            .select(
              'id, store_id, promotion_type, event_text, tone, generated_copy, created_at',
            )
            .order('created_at', ascending: false)
            .limit(10),
      ]);
      if (!mounted) return;
      final stores = (responses[0] as List)
          .whereType<Map>()
          .map((item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)))
          .where((store) => store.id.isNotEmpty)
          .toList(growable: false);
      setState(() {
        _ownerStores = stores;
        _selectedStoreId =
            _selectedStoreId ?? (stores.isEmpty ? null : stores.first.id);
        _promotionHistory = (responses[1] as List)
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
          content: Text('홍보 데이터를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _generatePromotionCopy() async {
    if (_isGenerating) return;
    final session = Supabase.instance.client.auth.currentSession;
    final store = _selectedStore;
    final eventText = _eventController.text.trim();
    final keywords = _keywordList();

    if (!AppConfig.isSupabaseConfigured || session == null) {
      _showMessage('로그인 후 사용할 수 있어요.');
      return;
    }
    if (store == null) {
      _showMessage('먼저 사장님 계정으로 가게를 등록해주세요.');
      return;
    }
    if (eventText.isEmpty) {
      _showMessage('홍보할 메뉴나 이벤트를 입력해주세요.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final input = [
        '가게명: ${store.name}',
        '업종: ${store.category}',
        '홍보 내용: $eventText',
        if (keywords.isNotEmpty) '키워드: ${keywords.join(', ')}',
        '문구 분위기: $_selectedTone',
      ].join('\n');

      final response = await http
          .post(
            Uri.parse('$AppConfig.flaskAiBaseUrl/api/ai'),
            headers: _jsonHeadersWithAuth(),
            body: jsonEncode({'input': input, 'role': 'owner'}),
          )
          .timeout(const Duration(seconds: 35));
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('AI 서버 응답 형식이 올바르지 않아요.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded['message'] as String? ?? 'AI 요청에 실패했어요.');
      }
      if (decoded['status'] != 'success') {
        throw Exception(decoded['message'] as String? ?? '홍보 문구 생성에 실패했어요.');
      }

      final data = decoded['data'];
      final marketing = data is Map<String, dynamic> ? data['marketing'] : null;
      if (marketing is! Map) {
        throw Exception('홍보 문구 응답을 해석하지 못했어요.');
      }
      final postText = (marketing['post_text'] as String?)?.trim();
      final hashtags = marketing['hashtags'] is List
          ? (marketing['hashtags'] as List)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[];
      if (postText == null || postText.isEmpty) {
        throw Exception('생성된 홍보 문구가 비어 있어요.');
      }

      final generatedCopy = [
        postText,
        if (hashtags.isNotEmpty) '',
        if (hashtags.isNotEmpty) hashtags.join(' '),
      ].join('\n');

      await Supabase.instance.client.from('promotion_history').insert({
        'owner_id': session.user.id,
        'store_id': store.id,
        'promotion_type': 'sns',
        'event_text': eventText,
        'keywords': keywords,
        'tone': _selectedTone,
        'generated_copy': generatedCopy,
      });

      if (!mounted) return;
      setState(() => _generatedCopy = generatedCopy);
      _showMessage('홍보 문구를 생성하고 기록에 저장했어요.');
      await _loadOwnerData();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: 'AI 홍보 도우미',
            onBack: () => widget.onOpen(AppScreen.ownerRegistration),
            trailing: _IconButton(
              icon: Icons.history_rounded,
              onPressed: _loadOwnerData,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_secondary, _primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: _softCircle(86, Colors.white.withOpacity(0.16)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '우리 가게 홍보,\nAI에게 맡겨보세U!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '메뉴 설명부터 SNS 문구까지\n클릭 한 번으로 완성됩니다.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.82),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '필요한 홍보물을 선택해U'),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.campaign_rounded,
                  title: 'SNS 홍보 문구',
                  subtitle: '인스타그램, 당근마켓용 감성 문구',
                  status: _promotionHistory.isEmpty
                      ? '생성 기록 없음'
                      : '최근 생성: ${_formatDate(_promotionHistory.first['created_at'] as String?)}',
                  action: '작성하기',
                ),
                const _FeatureCard(
                  icon: Icons.description_rounded,
                  title: '메뉴/가게 소개',
                  subtitle: '손님들의 침샘을 자극하는 설명글',
                  status: '미작성',
                  action: '생성하기',
                ),
                const _FeatureCard(
                  icon: Icons.local_offer_rounded,
                  title: '타임딜 쿠폰',
                  subtitle: '조용한 시간대 손님 모시는 문구',
                  status: '최근 생성: 1시간 전',
                  action: '만들기',
                ),
                const SizedBox(height: 24),
                _SurfaceCard(
                  color: _surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: '홍보 정보 입력'),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        )
                      else if (_ownerStores.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.storefront_rounded,
                          title: '등록된 내 가게가 없어요',
                          message: '우리 가게 등록하기에서 가게를 먼저 등록해주세요.',
                          actionLabel: '가게 등록하기',
                          onAction: () =>
                              widget.onOpen(AppScreen.ownerRegistration),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedStoreId,
                          decoration: const InputDecoration(
                            labelText: '홍보할 가게',
                            border: OutlineInputBorder(),
                          ),
                          items: _ownerStores
                              .map(
                                (store) => DropdownMenuItem(
                                  value: store.id,
                                  child: Text(store.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedStoreId = value);
                          },
                        ),
                      const SizedBox(height: 16),
                      _TextFieldBox(
                        label: '홍보할 메뉴/이벤트',
                        hint: '예: 신메뉴 들기름 막국수 출시',
                        icon: Icons.restaurant_menu_rounded,
                        controller: _eventController,
                      ),
                      const SizedBox(height: 16),
                      _TextFieldBox(
                        label: '강조하고 싶은 키워드',
                        hint: '쉼표로 구분: 고소함, 로컬 식재료, 할머니 손맛',
                        icon: Icons.sell_rounded,
                        controller: _keywordsController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: '문구 분위기'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['친절한', '재치있는', '감성적인', '짧고 강한']
                      .map(
                        (tone) => _Pill(
                          label: tone,
                          selected: _selectedTone == tone,
                          onTap: () => setState(() => _selectedTone = tone),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                _PrimaryButton(
                  label: _isGenerating ? '생성 중...' : '문구 생성하기',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _isGenerating ? () {} : _generatePromotionCopy,
                ),
                const SizedBox(height: 16),
                if (_generatedCopy?.isNotEmpty == true) ...[
                  _SurfaceCard(
                    color: _primary.withOpacity(0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('생성된 홍보 문구', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 10),
                        Text(
                          _generatedCopy!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_promotionHistory.isNotEmpty) ...[
                  const _SectionHeader(title: '최근 생성 기록'),
                  const SizedBox(height: 12),
                  ..._promotionHistory.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['event_text'] as String? ?? '홍보 문구',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(item['created_at'] as String?),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['generated_copy'] as String? ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                _SurfaceCard(
                  color: _surfaceVariant.withOpacity(0.50),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: _primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '구체적인 메뉴명과 분위기를 넣으면 더 자연스러운 홍보 문구가 만들어져요.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.action,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: _secondaryText),
                  ),
                ],
              ),
            ),
            Text(
              action,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: _primary),
            ),
          ],
        ),
      ),
    );
  }
}
