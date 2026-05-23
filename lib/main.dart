import 'package:flutter/material.dart';

void main() {
  runApp(const DongNeuApp());
}

class DongNeuApp extends StatelessWidget {
  const DongNeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '동네유',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF7A1A),
          primary: const Color(0xFFFF7A1A),
          secondary: const Color(0xFF2BAE66),
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
          titleSmall: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.4,
          ),
          bodyMedium: TextStyle(fontSize: 14, height: 1.55),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 108),
                  children: const [
                    _HomeHeader(),
                    _AiRecommendationCard(),
                    _SituationSection(),
                    _ManualSearchCard(),
                    _LocalPickSection(),
                  ],
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: _BottomNavigation(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF757575),
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: '동네 주민님!',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text('충남대 궁동', style: theme.textTheme.titleMedium),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF757575),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            tooltip: '알림',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  const _AiRecommendationCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A1A), Color(0xFF2BAE66)],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24FF7A1A),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -36,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI 맞춤 추천',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
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
                  const SizedBox(height: 4),
                  Text(
                    '상황, 예산, 취향만 말해주세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '예: 충남대 근처 가성비 혼밥 추천해줘',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Color(0xFF777777)),
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
    );
  }
}

class _SituationSection extends StatelessWidget {
  const _SituationSection();

  static const _chips = [
    ('🍱', '혼밥'),
    ('💑', '데이트'),
    ('💸', '가성비'),
    ('☔', '비 오는 날'),
    ('🤝', '모임'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '이런 상황인가U?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (final chip in _chips) ...[
                  _SituationChip(emoji: chip.$1, label: chip.$2),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        children: [
          Text(emoji),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: const Color(0xFF202020)),
          ),
        ],
      ),
    );
  }
}

class _ManualSearchCard extends StatelessWidget {
  const _ManualSearchCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E2DC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6D5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('직접 찾아보기', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        '필터를 설정해서 취향대로 검색해요',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF757575),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocalPickSection extends StatelessWidget {
  const _LocalPickSection();

  static const _picks = [
    _LocalPick(
      imageUrl:
          'https://dimg.dreamflow.cloud/v1/image/korean%20noodle%20soup%20bowl',
      tag: '가까워U',
      tagColor: Color(0xFF1E88E5),
      tagBackground: Color(0xFFE3F2FD),
      name: '궁동 칼국수',
      rating: '4.8',
    ),
    _LocalPick(
      imageUrl:
          'https://dimg.dreamflow.cloud/v1/image/korean%20street%20food%20tteokbokki',
      tag: '아껴U',
      tagColor: Color(0xFF43A047),
      tagBackground: Color(0xFFE8F5E9),
      name: '할머니 분식',
      rating: '4.5',
    ),
    _LocalPick(
      imageUrl:
          'https://dimg.dreamflow.cloud/v1/image/modern%20minimal%20cafe%20interior',
      tag: '새로워U',
      tagColor: Color(0xFFFB8C00),
      tagBackground: Color(0xFFFFF3E0),
      name: '카페 오렌지',
      rating: '4.9',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘의 동네픽', style: Theme.of(context).textTheme.titleMedium),
                TextButton(onPressed: () {}, child: const Text('전체보기')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [for (final pick in _picks) _LocalPickCard(pick: pick)],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalPickCard extends StatelessWidget {
  const _LocalPickCard({required this.pick});

  final _LocalPick pick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            width: double.infinity,
            child: Image.network(
              pick.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFFFE6D5),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
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
                    color: pick.tagBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pick.tag,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: pick.tagColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pick.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFB300),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pick.rating,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E2DC))),
      ),
      child: SizedBox(
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: '홈', color: primary),
              const _NavItem(icon: Icons.search_rounded, label: '검색'),
              const _NavItem(icon: Icons.bookmark_rounded, label: '저장'),
              const _NavItem(icon: Icons.person_rounded, label: '마이'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF757575),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _LocalPick {
  const _LocalPick({
    required this.imageUrl,
    required this.tag,
    required this.tagColor,
    required this.tagBackground,
    required this.name,
    required this.rating,
  });

  final String imageUrl;
  final String tag;
  final Color tagColor;
  final Color tagBackground;
  final String name;
  final String rating;
}
