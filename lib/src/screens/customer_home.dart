part of '../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpen,
    required this.myLocation,
    required this.stores,
    required this.isLoadingStores,
    required this.storesError,
    required this.onRefreshStores,
    required this.onStoreOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  final List<DongNeuStore> stores;
  final bool isLoadingStores;
  final String? storesError;
  final Future<void> Function() onRefreshStores;
  final ValueChanged<DongNeuStore> onStoreOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              text: '안녕하세요, ',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _secondaryText,
                              ),
                              children: [
                                TextSpan(
                                  text: '동네 주민님!',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => onOpen(AppScreen.location),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: _primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  myLocation,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _secondaryText,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => onOpen(AppScreen.mypage),
                        icon: const Icon(Icons.person_outline_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _AiHeroCard(onTap: () => onOpen(AppScreen.aiChat)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '이런 상황인가U?',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _SituationChip(
                              icon: Icons.rice_bowl_rounded,
                              label: '혼밥',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.favorite_rounded,
                              label: '데이트',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.savings_rounded,
                              label: '가성비',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.umbrella_rounded,
                              label: '비 오는 날',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.groups_rounded,
                              label: '모임',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _SurfaceCard(
                    onTap: () => onOpen(AppScreen.filters),
                    child: Row(
                      children: [
                        const _IconTile(
                          icon: Icons.tune_rounded,
                          background: Color(0x1AFF7E33),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '직접 찾아보기',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '필터를 설정해서 취향대로 검색해요',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: _secondaryText,
                        ),
                      ],
                    ),
                  ),
                ),
                _LocalPicksSection(
                  onOpen: onOpen,
                  stores: stores,
                  isLoading: isLoadingStores,
                  error: storesError,
                  onRefresh: onRefreshStores,
                  onStoreOpen: onStoreOpen,
                ),
              ],
            ),
          ),
          _BottomNav(current: AppScreen.home, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _AiHeroCard extends StatelessWidget {
  const _AiHeroCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'AI 맞춤 추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '지금 내 상황에 딱 맞는\n동네 맛집을 찾아드릴까요?',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '상황, 예산, 취향만 말해주세요',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.80),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: _primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppDefaults.aiSearchExample,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _accentText,
                              ),
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
        ),
      ),
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: _Pill(icon: icon, label: label),
      ),
    );
  }
}

class _LocalPicksSection extends StatelessWidget {
  const _LocalPicksSection({
    required this.onOpen,
    required this.stores,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onStoreOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final List<DongNeuStore> stores;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<DongNeuStore> onStoreOpen;

  Color _colorForIndex(int index) {
    return switch (index % 3) {
      0 => _info,
      1 => _success,
      _ => _warning,
    };
  }

  String _tagForStore(DongNeuStore store, int index) {
    if (store.features.contains('착한가격업소') || store.tags.contains('가성비')) {
      return '아껴U';
    }
    if (store.features.contains('새로생긴가게') || store.tags.contains('새로운')) {
      return '새로워U';
    }
    if (index == 0) return '가까워U';
    return '동네픽';
  }

  IconData _iconForCategory(String category) {
    if (category.contains('카페')) return Icons.local_cafe_rounded;
    if (category.contains('분식')) return Icons.local_dining_rounded;
    if (category.contains('국수') || category.contains('면')) {
      return Icons.ramen_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘의 동네픽', style: theme.textTheme.titleMedium),
                _PrimaryButton(
                  label: isLoading ? '불러오는 중' : '새로고침',
                  compact: true,
                  ghost: true,
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _EmptyStateCard(
                icon: Icons.cloud_off_rounded,
                title: '가게 목록을 불러오지 못했어요',
                message: error!,
                actionLabel: '다시 불러오기',
                onAction: onRefresh,
              ),
            )
          else if (stores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _EmptyStateCard(
                icon: Icons.storefront_rounded,
                title: '등록된 가게가 없어요',
                message: 'Supabase stores에 active 가게가 있으면 여기에 표시돼요.',
                actionLabel: '새로고침',
                onAction: onRefresh,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: stores.take(8).toList().asMap().entries.map((entry) {
                  final store = entry.value;
                  final tagColor = _colorForIndex(entry.key);
                  return _LocalPickCard(
                    tag: _tagForStore(store, entry.key),
                    tagColor: tagColor,
                    tagBg: tagColor.withOpacity(0.10),
                    name: store.name,
                    rating: store.ratingLabel,
                    icon: _iconForCategory(store.category),
                    onTap: () => onStoreOpen(store),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalPickCard extends StatelessWidget {
  const _LocalPickCard({
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.name,
    required this.rating,
    required this.icon,
    required this.onTap,
  });
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final String name;
  final String rating;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 16),
      child: _SurfaceCard(
        padding: EdgeInsets.zero,
        radius: 24,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tagColor.withOpacity(0.22), _surfaceVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Icon(icon, color: tagColor, size: 42),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tagColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _secondaryText,
                        ),
                      ),
                    ],
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

class AiConditionConfirmationScreen extends StatelessWidget {
  const AiConditionConfirmationScreen({
    super.key,
    required this.onOpen,
    this.query = AppDefaults.aiConditionQuery,
  });
  final ValueChanged<AppScreen> onOpen;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollScreen(
      padding: EdgeInsets.zero,
      bottom: _BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrimaryButton(
              label: '이대로 추천 받기',
              onPressed: () => onOpen(AppScreen.recommendations),
            ),
            const SizedBox(height: 10),
            _PrimaryButton(
              label: '조건 수정하기',
              ghost: true,
              onPressed: () => onOpen(AppScreen.filters),
            ),
          ],
        ),
      ),
      children: [
        _TopBar(
          title: '',
          onBack: () => onOpen(AppScreen.home),
          trailing: _IconButton(
            icon: Icons.close_rounded,
            onPressed: () => onOpen(AppScreen.home),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '맞춤 추천을 위해\n조건을 확인해볼까U?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'AI가 분석한 오늘의 방문 조건이에요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              _SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '“$query”',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: _alternate),
                    const SizedBox(height: 14),
                    const _ConditionRow(
                      icon: Icons.location_on_rounded,
                      label: '위치',
                      value: '충남대 근처',
                    ),
                    const _ConditionRow(
                      icon: Icons.payments_rounded,
                      label: '예산',
                      value: '만 원 이하',
                    ),
                    const _ConditionRow(
                      icon: Icons.schedule_rounded,
                      label: '시간대',
                      value: '저녁',
                    ),
                    const _ConditionRow(
                      icon: Icons.person_rounded,
                      label: '상황',
                      value: '혼밥',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('추출된 키워드', style: theme.textTheme.titleSmall),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Pill(label: '가성비', selected: true),
                        _Pill(label: '조용한', selected: false),
                        _Pill(label: '로컬맛집', selected: false),
                        _Pill(label: '든든한', selected: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SurfaceCard(
                color: _primary.withOpacity(0.08),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '이 조건으로 맛집 3곳을 찾아드릴게요!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: _secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class Top3RecommendationsScreen extends StatelessWidget {
  const Top3RecommendationsScreen({
    super.key,
    required this.onOpen,
    required this.query,
    required this.recommendations,
    required this.stores,
    required this.onStoreNameOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final String query;
  final List<AiRecommendation> recommendations;
  final List<DongNeuStore> stores;
  final Future<bool> Function(String storeName) onStoreNameOpen;

  DongNeuStore? _matchedStore(String storeName) {
    final normalizedName = storeName.replaceAll(RegExp(r'\s+'), '');
    for (final store in stores) {
      if (store.name.replaceAll(RegExp(r'\s+'), '') == normalizedName) {
        return store;
      }
    }
    return null;
  }

  Color _colorForTag(String tag) {
    if (tag.contains('가까')) return _info;
    if (tag.contains('아껴') || tag.contains('가격')) return _success;
    if (tag.contains('새로')) return _warning;
    return _primary;
  }

  IconData _iconForTag(String tag) {
    if (tag.contains('가까')) return Icons.near_me_rounded;
    if (tag.contains('아껴') || tag.contains('가격')) return Icons.savings_rounded;
    if (tag.contains('새로')) return Icons.auto_awesome_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '동네U의 추천',
            subtitle: '오늘의 완벽한 3곳을 찾았어요!',
            onBack: () => onOpen(AppScreen.aiCondition),
            trailing: _IconButton(
              icon: Icons.refresh_rounded,
              onPressed: () => onOpen(AppScreen.aiChat),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                if (recommendations.isEmpty) ...[
                  _SurfaceCard(
                    color: _surfaceVariant.withOpacity(0.55),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: _primary,
                          size: 34,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '아직 추천 결과가 없어요',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI 동네 검색에서 원하는 조건을 먼저 입력해주세요.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _PrimaryButton(
                          label: 'AI 검색하러 가기',
                          compact: true,
                          onPressed: () => onOpen(AppScreen.aiChat),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _SurfaceCard(
                    color: _primary.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: _primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text('“$query” 조건에 맞춰 찾은 추천입니다.')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recommendations.asMap().entries.expand((entry) {
                    final item = entry.value;
                    final color = _colorForTag(item.cardType);
                    final matchedStore = _matchedStore(item.storeName);
                    return [
                      _RecommendationCard(
                        rank: entry.key + 1,
                        tag: item.cardType,
                        name: item.storeName,
                        rating: matchedStore?.ratingLabel ?? '-',
                        price: matchedStore?.priceRange ?? 'AI 추천',
                        category: matchedStore?.category ?? '동네 맛집',
                        distance: matchedStore == null ? '매칭 대기' : '상세 가능',
                        reason: item.reason,
                        color: color,
                        icon: _iconForTag(item.cardType),
                        onTap: () async {
                          final opened = await onStoreNameOpen(item.storeName);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${item.storeName}"을 stores에서 찾지 못했어요.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ];
                  }),
                ],
                const SizedBox(height: 24),
                Text(
                  '추천 결과가 마음에 드셨나요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryButton(
                        label: '다시 추천',
                        outline: true,
                        onPressed: () => onOpen(AppScreen.aiCondition),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PrimaryButton(
                        label: '조건 수정',
                        onPressed: () => onOpen(AppScreen.filters),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _BottomNav(current: AppScreen.home, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.rank,
    required this.tag,
    required this.name,
    required this.rating,
    required this.price,
    required this.category,
    required this.distance,
    required this.reason,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final int rank;
  final String tag;
  final String name;
  final String rating;
  final String price;
  final String category;
  final String distance;
  final String reason;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconTile(
                    icon: icon,
                    color: color,
                    background: color.withOpacity(0.12),
                    size: 58,
                  ),
                  Positioned(
                    left: -7,
                    top: -7,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SmallTag(label: tag, color: color),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          color: _warning,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(rating, style: theme.textTheme.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MetaText(price),
                        _MetaText(category),
                        _MetaText(distance),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText),
          ),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: _secondaryText),
    );
  }
}
