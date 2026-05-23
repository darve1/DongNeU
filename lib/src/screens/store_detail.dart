part of '../../main.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({
    super.key,
    required this.onOpen,
    required this.store,
    required this.isSaved,
    required this.onToggleSaved,
  });
  final ValueChanged<AppScreen> onOpen;
  final DongNeuStore? store;
  final bool isSaved;
  final Future<void> Function(String storeId) onToggleSaved;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isLoadingMenus = false;
  bool _isTogglingSaved = false;
  List<StoreMenuItem> _menus = const [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void didUpdateWidget(covariant StoreDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.id != widget.store?.id) {
      _loadMenus();
    }
  }

  IconData _iconForCategory(String category) {
    if (category.contains('카페')) return Icons.local_cafe_rounded;
    if (category.contains('분식')) return Icons.local_dining_rounded;
    if (category.contains('국수') || category.contains('면')) {
      return Icons.ramen_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  Future<void> _loadMenus() async {
    final store = widget.store;
    if (store == null || !AppConfig.isSupabaseConfigured) {
      setState(() {
        _menus = const [];
        _isLoadingMenus = false;
      });
      return;
    }

    setState(() => _isLoadingMenus = true);
    try {
      final response = await Supabase.instance.client
          .from('menu_items')
          .select('id, name, description, price, is_representative')
          .eq('store_id', store.id)
          .order('is_representative', ascending: false)
          .order('price');
      if (!mounted) return;
      setState(() {
        _menus = (response as List)
            .whereType<Map>()
            .map(
              (item) => StoreMenuItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
        _isLoadingMenus = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingMenus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleSaved() async {
    final store = widget.store;
    if (store == null || _isTogglingSaved) return;

    setState(() => _isTogglingSaved = true);
    try {
      await widget.onToggleSaved(store.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSaved ? '저장을 해제했어요.' : '가게를 저장했어요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isTogglingSaved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = widget.store;
    if (store == null) {
      return _PhoneFrame(
        child: Column(
          children: [
            _TopBar(
              title: '가게 상세',
              onBack: () => widget.onOpen(AppScreen.home),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyStateCard(
                    icon: Icons.storefront_rounded,
                    title: '선택된 가게가 없어요',
                    message: '홈이나 저장 목록에서 가게를 선택하면 상세 정보를 볼 수 있어요.',
                    actionLabel: '홈으로 가기',
                    onAction: () => widget.onOpen(AppScreen.home),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final visibleTags = [
      store.category,
      if (store.priceRange?.isNotEmpty == true) store.priceRange!,
      ...store.tags.take(2),
    ];

    return _PhoneFrame(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              Stack(
                children: [
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _tertiary.withOpacity(0.95),
                          _primary.withOpacity(0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _iconForCategory(store.category),
                        color: Colors.white,
                        size: 92,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _CircleAction(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => widget.onOpen(AppScreen.home),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _CircleAction(
                          icon: Icons.share_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(AppMessages.backendPending),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _CircleAction(
                          icon: widget.isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          onTap: _toggleSaved,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 22,
                    child: _SmallTag(
                      label: store.features.contains('착한가격업소') ? '아껴U' : '동네U',
                      color: store.features.contains('착한가격업소')
                          ? _success
                          : _info,
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: _warning,
                                  size: 18,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  store.ratingLabel,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: visibleTags
                              .map((tag) => _Pill(label: tag))
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: _alternate),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: _primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '동네U 추천 이유',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.description?.isNotEmpty == true
                              ? store.description!
                              : 'Supabase stores에 등록된 가게 정보입니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('대표 메뉴', style: theme.textTheme.titleMedium),
                        Text(
                          '${_menus.length}개',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingMenus)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (_menus.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.restaurant_menu_rounded,
                        title: '등록된 메뉴가 없어요',
                        message: 'menu_items에 메뉴가 추가되면 여기에 표시돼요.',
                        actionLabel: '다시 불러오기',
                        onAction: _loadMenus,
                      )
                    else
                      ..._menus.expand((menu) {
                        return [
                          _MenuItemCard(
                            icon: menu.isRepresentative
                                ? Icons.restaurant_menu_rounded
                                : Icons.local_dining_rounded,
                            name: menu.name,
                            desc: menu.description?.isNotEmpty == true
                                ? menu.description!
                                : menu.isRepresentative
                                ? '대표 메뉴'
                                : '일반 메뉴',
                            price: _formatWon(menu.price),
                          ),
                          const SizedBox(height: 10),
                        ];
                      }),
                    const SizedBox(height: 20),
                    _SurfaceCard(
                      color: _surfaceVariant.withOpacity(0.50),
                      child: Column(
                        children: [
                          _StoreInfoRow(
                            icon: Icons.schedule_rounded,
                            text: store.openingHours?.isNotEmpty == true
                                ? store.openingHours!
                                : '운영시간 정보 없음',
                          ),
                          _StoreInfoRow(
                            icon: Icons.payments_rounded,
                            text: store.priceRange?.isNotEmpty == true
                                ? store.priceRange!
                                : '가격 정보 없음',
                          ),
                          _StoreInfoRow(
                            icon: Icons.info_outlined,
                            text: store.address,
                            bottom: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomActionBar(
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _isTogglingSaved ? null : _toggleSaved,
                          icon: Icon(
                            widget.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                        ),
                        Text(
                          widget.isSaved ? '저장됨' : '저장',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: '길찾기',
                      icon: Icons.near_me_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppMessages.backendPending),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: _primaryText, size: 22),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.icon,
    required this.name,
    required this.desc,
    required this.price,
  });
  final IconData icon;
  final String name;
  final String desc;
  final String price;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
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
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(price, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _StoreInfoRow extends StatelessWidget {
  const _StoreInfoRow({
    required this.icon,
    required this.text,
    this.bottom = true,
  });
  final IconData icon;
  final String text;
  final bool bottom;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom ? 16 : 0),
      child: Row(
        children: [
          Icon(icon, color: _secondaryText, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
