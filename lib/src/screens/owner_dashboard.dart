part of '../../main.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<DongNeuStore> _stores = const [];
  List<Map<String, dynamic>> _promotionHistory = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!AppConfig.isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() {
        _isLoading = false;
        _error = '로그인 후 사장님 대시보드를 확인할 수 있어요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('stores')
            .select(StoreQueries.storeSelectColumns)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('promotion_history')
            .select('id, generated_copy, created_at')
            .order('created_at', ascending: false)
            .limit(5),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = (responses[0] as List)
            .whereType<Map>()
            .map(
              (item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((store) => store.id.isNotEmpty)
            .toList(growable: false);
        _promotionHistory = (responses[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '대시보드 데이터를 불러오지 못했어요: $error';
      });
    }
  }

  int get _reviewCount {
    return _stores.fold<int>(0, (total, store) => total + store.reviewCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '사장님 대시보드',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      _IconButton(
                        icon: Icons.refresh_rounded,
                        onPressed: _loadDashboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else if (_error != null)
                    _EmptyStateCard(
                      icon: Icons.lock_outline_rounded,
                      title: '대시보드를 열 수 없어요',
                      message: _error!,
                      actionLabel: '가게 등록하기',
                      onAction: () =>
                          widget.onOpen(AppScreen.ownerRegistration),
                    )
                  else ...[
                    _SurfaceCard(
                      color: _primary.withOpacity(0.08),
                      child: Row(
                        children: [
                          _ExpandedStat(
                            label: '등록 가게',
                            value: '${_stores.length}',
                          ),
                          _ExpandedStat(label: '리뷰', value: '$_reviewCount'),
                          _ExpandedStat(
                            label: 'AI 홍보',
                            value: '${_promotionHistory.length}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: '빠른 메뉴'),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.add_business_rounded,
                      label: '새 가게 등록',
                      onTap: () => widget.onOpen(AppScreen.ownerRegistration),
                    ),
                    _MenuTile(
                      icon: Icons.edit_rounded,
                      label: '가게 정보 및 메뉴 관리',
                      onTap: () => widget.onOpen(AppScreen.ownerStoreManage),
                    ),
                    _MenuTile(
                      icon: Icons.campaign_rounded,
                      label: 'AI 홍보 문구 만들기',
                      onTap: () => widget.onOpen(AppScreen.promotion),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: '내 가게'),
                    const SizedBox(height: 12),
                    if (_stores.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.storefront_rounded,
                        title: '등록된 가게가 없어요',
                        message: '가게를 등록하면 AI 추천과 홍보 도우미에 연결됩니다.',
                        actionLabel: '가게 등록하기',
                        onAction: () =>
                            widget.onOpen(AppScreen.ownerRegistration),
                      )
                    else
                      ..._stores.take(3).map((store) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SurfaceCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () =>
                                widget.onOpen(AppScreen.ownerStoreManage),
                            child: Row(
                              children: [
                                const _IconTile(
                                  icon: Icons.restaurant_rounded,
                                  color: _secondary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${store.category} · ${store.address}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: _accentText,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
          _OwnerBottomNav(
            current: AppScreen.ownerDashboard,
            onOpen: widget.onOpen,
          ),
        ],
      ),
    );
  }
}
