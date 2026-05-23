part of '../../main.dart';

class OwnerStoreManageScreen extends StatefulWidget {
  const OwnerStoreManageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<OwnerStoreManageScreen> createState() => _OwnerStoreManageScreenState();
}

class _OwnerStoreManageScreenState extends State<OwnerStoreManageScreen> {
  List<DongNeuStore> _stores = const [];
  List<StoreMenuItem> _menus = const [];
  String? _selectedStoreId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  DongNeuStore? get _selectedStore {
    for (final store in _stores) {
      if (store.id == _selectedStoreId) return store;
    }
    return _stores.isEmpty ? null : _stores.first;
  }

  Future<void> _loadStores() async {
    if (!AppConfig.isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select(StoreQueries.storeSelectColumns)
          .order('created_at', ascending: false);
      if (!mounted) return;
      final stores = (response as List)
          .whereType<Map>()
          .map((item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)))
          .where((store) => store.id.isNotEmpty)
          .toList(growable: false);
      setState(() {
        _stores = stores;
        _selectedStoreId = _selectedStoreId ?? stores.firstOrNull?.id;
        _isLoading = false;
      });
      await _loadMenus();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가게 정보를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadMenus() async {
    final store = _selectedStore;
    if (store == null || !AppConfig.isSupabaseConfigured) {
      if (mounted) setState(() => _menus = const []);
      return;
    }

    final response = await Supabase.instance.client
        .from('menu_items')
        .select('id, name, description, price, is_representative')
        .eq('store_id', store.id)
        .order('is_representative', ascending: false)
        .order('created_at', ascending: true);
    if (!mounted) return;
    setState(() {
      _menus = (response as List)
          .whereType<Map>()
          .map(
            (item) => StoreMenuItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    });
  }

  void _showPendingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppMessages.backendPending),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = _selectedStore;
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '가게 관리',
            onBack: () => widget.onOpen(AppScreen.ownerDashboard),
            trailing: _IconButton(
              icon: Icons.refresh_rounded,
              onPressed: _loadStores,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                else if (_stores.isEmpty)
                  _EmptyStateCard(
                    icon: Icons.storefront_rounded,
                    title: '관리할 가게가 없어요',
                    message: '가게를 먼저 등록하면 메뉴와 상태를 확인할 수 있어요.',
                    actionLabel: '가게 등록하기',
                    onAction: () => widget.onOpen(AppScreen.ownerRegistration),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    value: store?.id,
                    decoration: const InputDecoration(
                      labelText: '관리할 가게',
                      border: OutlineInputBorder(),
                    ),
                    items: _stores
                        .map(
                          (store) => DropdownMenuItem(
                            value: store.id,
                            child: Text(store.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedStoreId = value);
                      await _loadMenus();
                    },
                  ),
                  const SizedBox(height: 18),
                  if (store != null)
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(
                            store.category,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            store.address,
                            style: theme.textTheme.bodyMedium,
                          ),
                          if (store.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            Text(
                              store.description!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: true,
                    onChanged: (_) => _showPendingMessage(),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('영업 중'),
                    subtitle: const Text('영업 상태 변경 저장은 추후 연결 예정'),
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: '메뉴'),
                  const SizedBox(height: 12),
                  if (_menus.isEmpty)
                    _SurfaceCard(
                      color: _surfaceVariant.withOpacity(0.50),
                      child: Text(
                        '등록된 메뉴가 없어요.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ..._menus.map((menu) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SurfaceCard(
                          padding: const EdgeInsets.all(16),
                          onTap: _showPendingMessage,
                          child: Row(
                            children: [
                              _IconTile(
                                icon: menu.isRepresentative
                                    ? Icons.star_rounded
                                    : Icons.restaurant_menu_rounded,
                                color: menu.isRepresentative
                                    ? _tertiary
                                    : _primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.name,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatWon(menu.price),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_rounded,
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
          _OwnerBottomNav(
            current: AppScreen.ownerStoreManage,
            onOpen: widget.onOpen,
          ),
        ],
      ),
    );
  }
}
