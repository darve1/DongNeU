part of '../../main.dart';

class ManualSearchFiltersScreen extends StatefulWidget {
  const ManualSearchFiltersScreen({
    super.key,
    required this.onOpen,
    required this.myLocation,
  });
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  @override
  State<ManualSearchFiltersScreen> createState() =>
      _ManualSearchFiltersScreenState();
}

class _ManualSearchFiltersScreenState extends State<ManualSearchFiltersScreen> {
  int _selectedBudget = 1;
  int _selectedSituation = 0;
  String _selectedCategory = '한식';
  bool _isGoodPrice = true;
  bool _isMarket = false;
  bool _isNew = false;

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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      _IconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => widget.onOpen(AppScreen.home),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: _TextFieldBox(
                          label: '',
                          hint: '맛집, 메뉴 검색',
                          icon: Icons.search_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: _primary,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.myLocation,
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _secondaryText,
                        size: 18,
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
                _SectionHeader(title: '예산', subtitle: '1인분 기준'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['~7천원', '~1만원', '~1.5만원', '상관없음']
                      .asMap()
                      .entries
                      .map(
                        (e) => _Pill(
                          label: e.value,
                          selected: _selectedBudget == e.key,
                          onTap: () => setState(() => _selectedBudget = e.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                _SectionHeader(title: '오늘의 상황'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['혼밥', '데이트', '친구와', '가족모임', '빠른 식사']
                      .asMap()
                      .entries
                      .map(
                        (e) => _Pill(
                          label: e.value,
                          selected: _selectedSituation == e.key,
                          onTap: () =>
                              setState(() => _selectedSituation = e.key),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '카테고리'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _CategoryTile(
                      icon: Icons.rice_bowl_rounded,
                      label: '한식',
                      selected: _selectedCategory == '한식',
                      onTap: () => setState(() => _selectedCategory = '한식'),
                    ),
                    _CategoryTile(
                      icon: Icons.ramen_dining_rounded,
                      label: '일식/면',
                      selected: _selectedCategory == '일식/면',
                      onTap: () => setState(() => _selectedCategory = '일식/면'),
                    ),
                    _CategoryTile(
                      icon: Icons.local_pizza_rounded,
                      label: '양식',
                      selected: _selectedCategory == '양식',
                      onTap: () => setState(() => _selectedCategory = '양식'),
                    ),
                    _CategoryTile(
                      icon: Icons.local_cafe_rounded,
                      label: '카페',
                      selected: _selectedCategory == '카페',
                      onTap: () => setState(() => _selectedCategory = '카페'),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '로컬 특별 조건'),
                const SizedBox(height: 12),
                _CheckCard(
                  title: '착한가격업소',
                  subtitle: '행안부 지정 물가 안정 모범 업소',
                  checked: _isGoodPrice,
                  onTap: () => setState(() => _isGoodPrice = !_isGoodPrice),
                ),
                _CheckCard(
                  title: '전통시장 근처',
                  subtitle: '시장 상권 활성화 가게',
                  checked: _isMarket,
                  onTap: () => setState(() => _isMarket = !_isMarket),
                ),
                _CheckCard(
                  title: '새로 생긴 가게',
                  subtitle: '최근 6개월 이내 등록',
                  checked: _isNew,
                  onTap: () => setState(() => _isNew = !_isNew),
                ),
              ],
            ),
          ),
          _BottomActionBar(
            child: Row(
              children: [
                _IconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    setState(() {
                      _selectedBudget = 1;
                      _selectedSituation = 0;
                      _selectedCategory = '한식';
                      _isGoodPrice = true;
                      _isMarket = false;
                      _isNew = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('필터가 초기화되었습니다.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PrimaryButton(
                    label: '결과 보기',
                    onPressed: () => widget.onOpen(AppScreen.recommendations),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      radius: 16,
      color: selected ? _primary.withOpacity(0.10) : _surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? _primary : _secondaryText, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? _primaryText : _secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.title,
    required this.subtitle,
    this.checked = false,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: checked ? _primary : _secondaryText,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
