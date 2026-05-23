import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NaverMapSdk.instance.initialize(clientId: 'j13ue7xko4');
  runApp(const DongNeuApp());
}

const _primary = Color(0xFFFF7E33);
const _secondary = Color(0xFF5E8D5A);
const _tertiary = Color(0xFFFFB347);
const _background = Color(0xFFFFFDF9);
const _surface = Color(0xFFFFFFFF);
const _surfaceVariant = Color(0xFFF2EBE1);
const _primaryText = Color(0xFF2D241E);
const _secondaryText = Color(0xFF7A6F66);
const _alternate = Color(0xFFE8DFD5);
const _accentText = Color(0xFFBCAFA3);
const _success = Color(0xFF4CAF50);
const _warning = Color(0xFFFF9800);
const _info = Color(0xFF2196F3);

enum AppScreen {
  auth,
  userType,
  location,
  home,
  aiCondition,
  aiChat,
  recommendations,
  filters,
  storeDetail,
  saved,
  ownerRegistration,
  promotion,
  mypage,
}

class DongNeuApp extends StatefulWidget {
  const DongNeuApp({super.key});

  @override
  State<DongNeuApp> createState() => _DongNeuAppState();
}

class _DongNeuAppState extends State<DongNeuApp> {
  AppScreen _screen = AppScreen.auth;
  String _myLocation = '충남대 궁동';
  String _aiQuery = '충남대 근처 가성비 혼밥 추천해줘';

  void _open(AppScreen screen) {
    setState(() => _screen = screen);
  }

  void _setMyLocation(String loc) {
    setState(() => _myLocation = loc);
  }

  void _setAiQuery(String query) {
    setState(() => _aiQuery = query);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '동네유',
      debugShowCheckedModeBanner: false,
      theme: _dongNeuTheme(),
      home: _AppRouter(
        screen: _screen, 
        onOpen: _open, 
        myLocation: _myLocation,
        onLocationChange: _setMyLocation,
        aiQuery: _aiQuery,
        onAiQueryChange: _setAiQuery,
      ),
    );
  }
}

ThemeData _dongNeuTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: _background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      secondary: _secondary,
      tertiary: _tertiary,
      surface: _surface,
      error: const Color(0xFFE53935),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, height: 1.2, color: _primaryText),
      headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.3, color: _primaryText),
      headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.35, color: _primaryText),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4, color: _primaryText),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4, color: _primaryText),
      titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.45, color: _primaryText),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: _primaryText),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55, color: _primaryText),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5, color: _secondaryText),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
      labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1.2),
    ),
  );
}

class _AppRouter extends StatelessWidget {
  const _AppRouter({
    required this.screen, 
    required this.onOpen, 
    required this.myLocation,
    required this.onLocationChange,
    required this.aiQuery,
    required this.onAiQueryChange,
  });

  final AppScreen screen;
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  final ValueChanged<String> onLocationChange;
  final String aiQuery;
  final ValueChanged<String> onAiQueryChange;

  @override
  Widget build(BuildContext context) {
    return switch (screen) {
      AppScreen.auth => AuthOnboardingScreen(onOpen: onOpen),
      AppScreen.userType => UserTypeSelectionScreen(onOpen: onOpen),
      AppScreen.location => LocationSetupScreen(onOpen: onOpen, onLocationChange: onLocationChange),
      AppScreen.home => HomeScreen(onOpen: onOpen, myLocation: myLocation),
      AppScreen.aiCondition => AiConditionConfirmationScreen(onOpen: onOpen, query: aiQuery),
      AppScreen.aiChat => AiChatScreen(onOpen: onOpen, onQueryChange: onAiQueryChange),
      AppScreen.recommendations => Top3RecommendationsScreen(onOpen: onOpen),
      AppScreen.filters => ManualSearchFiltersScreen(onOpen: onOpen, myLocation: myLocation),
      AppScreen.storeDetail => StoreDetailScreen(onOpen: onOpen),
      AppScreen.saved => SavedHistoryScreen(onOpen: onOpen),
      AppScreen.ownerRegistration => OwnerStoreRegistrationScreen(onOpen: onOpen),
      AppScreen.promotion => AiPromotionHelperScreen(onOpen: onOpen),
      AppScreen.mypage => MyPageScreen(onOpen: onOpen),
    };
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: child),
        ),
      ),
    );
  }
}

class _ScrollScreen extends StatelessWidget {
  const _ScrollScreen({required this.children, this.bottom, this.padding = const EdgeInsets.all(24)});
  final List<Widget> children;
  final Widget? bottom;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: padding.add(EdgeInsets.only(bottom: bottom == null ? 24 : 8)),
              children: children,
            ),
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.subtitle, this.onBack, this.trailing});
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: _surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                _IconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: onBack ?? () {},
                  visible: onBack != null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                      ],
                    ],
                  ),
                ),
                trailing ?? const SizedBox(width: 40, height: 40),
              ],
            ),
          ),
          const Divider(height: 1, color: _alternate),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onPressed, this.visible = true});
  final IconData icon;
  final VoidCallback onPressed;
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40, height: 40,
      child: visible ? IconButton(padding: EdgeInsets.zero, onPressed: onPressed, icon: Icon(icon, color: _primaryText)) : const SizedBox.shrink(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.icon, this.outline = false, this.ghost = false, this.compact = false});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool outline;
  final bool ghost;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final foreground = outline || ghost ? _primary : Colors.white;
    final background = outline || ghost ? Colors.transparent : _primary;
    final border = outline ? _primary : Colors.transparent;
    return SizedBox(
      height: compact ? 40 : 52,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          textStyle: Theme.of(context).textTheme.labelLarge,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(compact ? 14 : 18), side: BorderSide(color: border)),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: _secondaryText)),
        ],
      ],
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({required this.label, required this.hint, required this.icon, this.trailing, this.obscureText = false, this.onChanged});
  final String label;
  final String hint;
  final IconData icon;
  final IconData? trailing;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _alternate)),
          child: TextField(
            obscureText: obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: _accentText),
              prefixIcon: Icon(icon, size: 20, color: _secondaryText),
              suffixIcon: trailing != null ? Icon(trailing, size: 20, color: _secondaryText) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(20), this.radius = 24, this.color = _surface, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius), border: Border.all(color: _alternate)),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(radius), child: card),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.color = _primary, this.background = const Color(0x1AFF7E33), this.size = 48});
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size >= 48 ? 16 : 12)),
      child: Icon(icon, color: color, size: size >= 48 ? 24 : 20),
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill({required this.label, this.icon, this.selected = false, this.onTap});
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selected;
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      setState(() {
        _isSelected = !_isSelected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const chipColor = _primary;
    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(9999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: _isSelected ? chipColor.withOpacity(0.10) : _surface,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: _isSelected ? chipColor : _alternate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 16, color: _isSelected ? chipColor : _secondaryText), const SizedBox(width: 6)],
            Text(widget.label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _isSelected ? chipColor : _primaryText)),
          ],
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: _alternate)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _secondaryText))),
        const Expanded(child: Divider(color: _alternate)),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onOpen});
  final AppScreen current;
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _alternate))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: '홈', selected: current == AppScreen.home, onTap: () => onOpen(AppScreen.home)),
          _NavItem(icon: Icons.search_rounded, label: '검색', selected: current == AppScreen.filters || current == AppScreen.aiChat, onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: _surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (context) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('어떤 방식으로 검색할까요?', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      _SurfaceCard(
                        onTap: () { Navigator.pop(context); onOpen(AppScreen.aiChat); },
                        child: Row(
                          children: [
                            const _IconTile(icon: Icons.auto_awesome_rounded),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('AI 맞춤 검색', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text('상황을 말하면 딱 맞는 곳을 추천해줘요', style: Theme.of(context).textTheme.bodySmall)])),
                            const Icon(Icons.chevron_right_rounded, color: _secondaryText)
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SurfaceCard(
                        onTap: () { Navigator.pop(context); onOpen(AppScreen.filters); },
                        child: Row(
                          children: [
                            const _IconTile(icon: Icons.tune_rounded, background: Color(0x1A7A6F66), color: _secondaryText),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('수동 상세 검색', style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text('카테고리, 예산 등을 직접 설정해요', style: Theme.of(context).textTheme.bodySmall)])),
                            const Icon(Icons.chevron_right_rounded, color: _secondaryText)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          _NavItem(icon: Icons.bookmark_rounded, label: '저장', selected: current == AppScreen.saved, onTap: () => onOpen(AppScreen.saved)),
          _NavItem(icon: Icons.person_rounded, label: '마이', selected: current == AppScreen.mypage, onTap: () => onOpen(AppScreen.mypage)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _secondaryText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, color: color, size: 24), const SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color))],
        ),
      ),
    );
  }
}

class AuthOnboardingScreen extends StatelessWidget {
  const AuthOnboardingScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollScreen(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(left: 28, top: 20, child: _softCircle(120, _primary.withOpacity(0.10))),
              Positioned(right: 54, bottom: 22, child: _softCircle(82, _success.withOpacity(0.10))),
              Container(
                width: 188, height: 138,
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: _alternate)),
                child: const Icon(Icons.storefront_rounded, color: _primary, size: 72),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('반가워U, 동네유!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('우리 동네 숨은 맛집을 찾아드릴게요', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
        const SizedBox(height: 28),
        const _TextFieldBox(label: '이메일', hint: 'example@email.com', icon: Icons.mail_outline_rounded),
        const SizedBox(height: 16),
        const _TextFieldBox(label: '비밀번호', hint: '비밀번호를 입력하세요', icon: Icons.lock_outline_rounded, trailing: Icons.visibility_off_rounded),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerRight, child: Text('비밀번호를 잊으셨나요?', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))),
        const SizedBox(height: 20),
        _PrimaryButton(label: '시작하기', onPressed: () => onOpen(AppScreen.userType)),
        const SizedBox(height: 20),
        const _DividerLabel('또는'),
        const SizedBox(height: 16),
        _SocialButton(label: '구글로 계속하기', icon: Icons.g_mobiledata_rounded, onTap: () => onOpen(AppScreen.userType)),
        const SizedBox(height: 12),
        _SocialButton(label: 'Apple로 계속하기', icon: Icons.apple_rounded, onTap: () => onOpen(AppScreen.userType)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('처음 오셨나요?', style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
            TextButton(onPressed: () => onOpen(AppScreen.userType), child: const Text('회원가입')),
          ],
        ),
      ],
    );
  }
}

Widget _softCircle(double size, Color color) {
  return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15), radius: 16, onTap: onTap,
      child: Row(children: [Icon(icon, color: _primary, size: 24), const SizedBox(width: 12), Text(label, style: Theme.of(context).textTheme.labelLarge)]),
    );
  }
}

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollScreen(
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 92, height: 92,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, _tertiary]), borderRadius: BorderRadius.circular(32)),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 46),
          ),
        ),
        const SizedBox(height: 24),
        Text('반가워U, 동네유!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('당신의 따뜻한 동네 생활을 시작해보세요', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
        const SizedBox(height: 32),
        _ModeSelectionCard(icon: Icons.restaurant_rounded, title: '손님으로 시작하기', subtitle: '우리 동네 숨은 맛집과\n따뜻한 가게를 추천해드려요', button: '추천 받으러 가기', onTap: () => onOpen(AppScreen.location)),
        const SizedBox(height: 16),
        _ModeSelectionCard(icon: Icons.add_business_rounded, title: '사장님으로 시작하기', subtitle: '가게를 등록하고 AI로\n효과적인 홍보 문구를 만들어보세요', button: '내 가게 등록하기', outline: true, onTap: () => onOpen(AppScreen.ownerRegistration)),
        const SizedBox(height: 24),
        Center(child: TextButton(onPressed: () => onOpen(AppScreen.promotion), child: const Text('도움이 필요하신가요?  문의하기'))),
      ],
    );
  }
}

class _ModeSelectionCard extends StatelessWidget {
  const _ModeSelectionCard({required this.icon, required this.title, required this.subtitle, required this.button, required this.onTap, this.outline = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;
  final bool outline;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: outline ? _secondary : _primary, background: outline ? _secondary.withOpacity(0.10) : _primary.withOpacity(0.10)),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _secondaryText)),
          const SizedBox(height: 20),
          _PrimaryButton(label: button, outline: outline, onPressed: onTap),
        ],
      ),
    );
  }
}

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({super.key, required this.onOpen, required this.onLocationChange});
  final ValueChanged<AppScreen> onOpen;
  final ValueChanged<String> onLocationChange;
  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  String _selectedNeighborhood = '궁동';
  void _select(String name) {
    setState(() => _selectedNeighborhood = name.split(' ').last);
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(title: '내 동네 설정', onBack: () => widget.onOpen(AppScreen.userType)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _alternate),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      NaverMap(
                        options: const NaverMapViewOptions(
                          initialCameraPosition: NCameraPosition(
                            target: NLatLng(36.3621, 127.3458), // 충남대 궁동 근처 좌표
                            zoom: 15,
                          ),
                          indoorEnable: true,
                          locationButtonEnable: false,
                          consumeSymbolTapEvents: false,
                        ),
                        onMapReady: (controller) {
                          // 지도 준비 완료 시 필요한 동작 추가 가능
                        },
                      ),
                      Positioned(right: 14, bottom: 14, child: FloatingActionButton.small(onPressed: () => _select('현재 위치 (궁동)'), backgroundColor: _surface, child: const Icon(Icons.my_location_rounded, color: _primaryText))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _TextFieldBox(label: '동네 검색', hint: '동네 이름이나 도로명으로 검색', icon: Icons.search_rounded),
                const SizedBox(height: 24),
                const _SectionHeader(title: '주변 동네'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: ['대전 유성구 궁동', '대전 유성구 어은동', '대전 유성구 봉명동', '대전 유성구 죽동'].map((loc) => _Pill(
                    label: loc, 
                    selected: loc.contains(_selectedNeighborhood),
                    onTap: () => _select(loc),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '현재 설정된 위치'),
                const SizedBox(height: 12),
                _LocationItem(title: _selectedNeighborhood, subtitle: '현재 선택된 동네입니다', selected: true, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
                const SizedBox(height: 20),
                const _SectionHeader(title: '최근 검색한 위치'),
                const SizedBox(height: 12),
                _LocationItem(title: '어은동 (카이스트)', subtitle: '대전광역시 유성구 어은동', onTap: () => _select('어은동')),
                const SizedBox(height: 10),
                _LocationItem(title: '봉명동 (유성온천역)', subtitle: '대전광역시 유성구 봉명동', onTap: () => _select('봉명동')),
              ],
            ),
          ),
          _BottomActionBar(child: _PrimaryButton(label: '이 위치로 설정', onPressed: () { widget.onLocationChange(_selectedNeighborhood); widget.onOpen(AppScreen.home); })),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  const _LocationItem({required this.title, required this.subtitle, this.selected = false, required this.onTap});
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap, padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(icon: Icons.place_rounded, color: selected ? _primary : _secondaryText, background: selected ? _primary.withOpacity(0.10) : _surfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
          if (selected) const Icon(Icons.check_circle_rounded, color: _primary, size: 20),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpen, required this.myLocation});
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
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
                          Text.rich(TextSpan(text: '안녕하세요, ', style: theme.textTheme.bodyLarge?.copyWith(color: _secondaryText), children: [
                            TextSpan(text: '동네 주민님!', style: theme.textTheme.bodyLarge?.copyWith(color: _primaryText, fontWeight: FontWeight.w700)),
                          ])),
                          const SizedBox(height: 4),
                          InkWell(onTap: () => onOpen(AppScreen.location), borderRadius: BorderRadius.circular(10), child: Row(children: [const Icon(Icons.location_on_rounded, color: _primary, size: 20), const SizedBox(width: 4), Text(myLocation, style: theme.textTheme.titleMedium), const Icon(Icons.keyboard_arrow_down_rounded, color: _secondaryText, size: 20)])),
                        ],
                      ),
                      IconButton(onPressed: () => onOpen(AppScreen.mypage), icon: const Icon(Icons.person_outline_rounded)),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), child: _AiHeroCard(onTap: () => onOpen(AppScreen.aiChat))),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('이런 상황인가U?', style: theme.textTheme.titleMedium)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [_SituationChip(icon: Icons.rice_bowl_rounded, label: '혼밥', onTap: () => onOpen(AppScreen.aiChat)), _SituationChip(icon: Icons.favorite_rounded, label: '데이트', onTap: () => onOpen(AppScreen.aiChat)), _SituationChip(icon: Icons.savings_rounded, label: '가성비', onTap: () => onOpen(AppScreen.aiChat)), _SituationChip(icon: Icons.umbrella_rounded, label: '비 오는 날', onTap: () => onOpen(AppScreen.aiChat)), _SituationChip(icon: Icons.groups_rounded, label: '모임', onTap: () => onOpen(AppScreen.aiChat))])),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), child: _SurfaceCard(onTap: () => onOpen(AppScreen.filters), child: Row(children: [const _IconTile(icon: Icons.tune_rounded, background: Color(0x1AFF7E33)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('직접 찾아보기', style: theme.textTheme.titleSmall), const SizedBox(height: 4), Text('필터를 설정해서 취향대로 검색해요', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))])), const Icon(Icons.chevron_right_rounded, color: _secondaryText)]))),
                _LocalPicksSection(onOpen: onOpen),
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
        onTap: onTap, borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [_primary, _secondary], begin: Alignment.bottomRight, end: Alignment.topLeft), borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: _primary.withOpacity(0.14), blurRadius: 24, offset: const Offset(0, 12))]),
          child: Stack(
            children: [
              Positioned(right: -40, top: -40, child: Container(width: 180, height: 180, decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), shape: BoxShape.circle))),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), borderRadius: BorderRadius.circular(9999)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16), SizedBox(width: 5), Text('AI 맞춤 추천', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])),
                    const SizedBox(height: 16),
                    Text('지금 내 상황에 딱 맞는\n동네 맛집을 찾아드릴까요?', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 5),
                    Text('상황, 예산, 취향만 말해주세요', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.80))),
                    const SizedBox(height: 16),
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(24)), child: Row(children: [const Icon(Icons.search_rounded, color: _primary, size: 22), const SizedBox(width: 8), Expanded(child: Text('예: 충남대 근처 가성비 혼밥 추천해줘', overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: _accentText)))])),
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
  const _SituationChip({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(right: 8), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(9999), child: _Pill(icon: icon, label: label)));
  }
}

class _LocalPicksSection extends StatelessWidget {
  const _LocalPicksSection({required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('오늘의 동네픽', style: theme.textTheme.titleMedium), _PrimaryButton(label: '전체보기', compact: true, ghost: true, onPressed: () => onOpen(AppScreen.recommendations))])),
          const SizedBox(height: 14),
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [_LocalPickCard(tag: '가까워U', tagColor: _info, tagBg: _info.withOpacity(0.10), name: '궁동 칼국수', rating: '4.8', icon: Icons.ramen_dining_rounded, onTap: () => onOpen(AppScreen.storeDetail)), _LocalPickCard(tag: '아껴U', tagColor: _success, tagBg: _success.withOpacity(0.10), name: '할머니 분식', rating: '4.5', icon: Icons.local_dining_rounded, onTap: () => onOpen(AppScreen.storeDetail)), _LocalPickCard(tag: '새로워U', tagColor: _warning, tagBg: _warning.withOpacity(0.10), name: '카페 오렌지', rating: '4.9', icon: Icons.local_cafe_rounded, onTap: () => onOpen(AppScreen.storeDetail))])),
        ],
      ),
    );
  }
}

class _LocalPickCard extends StatelessWidget {
  const _LocalPickCard({required this.tag, required this.tagColor, required this.tagBg, required this.name, required this.rating, required this.icon, required this.onTap});
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
      width: 148, margin: const EdgeInsets.only(right: 16),
      child: _SurfaceCard(
        padding: EdgeInsets.zero, radius: 24, onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 104, decoration: BoxDecoration(gradient: LinearGradient(colors: [tagColor.withOpacity(0.22), _surfaceVariant], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Icon(icon, color: tagColor, size: 42)),
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(4)), child: Text(tag, style: theme.textTheme.labelSmall?.copyWith(color: tagColor))), const SizedBox(height: 7), Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall), const SizedBox(height: 4), Row(children: [const Icon(Icons.star_rounded, color: _warning, size: 14), const SizedBox(width: 4), Text(rating, style: theme.textTheme.labelSmall?.copyWith(color: _secondaryText))])])),
          ],
        ),
      ),
    );
  }
}

class AiConditionConfirmationScreen extends StatelessWidget {
  const AiConditionConfirmationScreen({super.key, required this.onOpen, this.query = "충남대 근처에서 혼자 먹기 좋고 만 원 이하로 든든한 저녁 추천해줘"});
  final ValueChanged<AppScreen> onOpen;
  final String query;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollScreen(
      padding: EdgeInsets.zero,
      bottom: _BottomActionBar(child: Column(mainAxisSize: MainAxisSize.min, children: [_PrimaryButton(label: '이대로 추천 받기', onPressed: () => onOpen(AppScreen.recommendations)), const SizedBox(height: 10), _PrimaryButton(label: '조건 수정하기', ghost: true, onPressed: () => onOpen(AppScreen.filters))])),
      children: [
        _TopBar(title: '', onBack: () => onOpen(AppScreen.home), trailing: _IconButton(icon: Icons.close_rounded, onPressed: () => onOpen(AppScreen.home))),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('맞춤 추천을 위해\n조건을 확인해볼까U?', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('AI가 분석한 오늘의 방문 조건이에요', style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
              const SizedBox(height: 20),
              _SurfaceCard(
                child: Column(
                  children: [
                    Row(children: [Container(width: 54, height: 54, decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.auto_awesome_rounded, color: _primary)), const SizedBox(width: 14), Expanded(child: Text('“$query”', style: theme.textTheme.titleSmall))]),
                    const SizedBox(height: 18), const Divider(color: _alternate), const SizedBox(height: 14),
                    const _ConditionRow(icon: Icons.location_on_rounded, label: '위치', value: '충남대 근처'),
                    const _ConditionRow(icon: Icons.payments_rounded, label: '예산', value: '만 원 이하'),
                    const _ConditionRow(icon: Icons.schedule_rounded, label: '시간대', value: '저녁'),
                    const _ConditionRow(icon: Icons.person_rounded, label: '상황', value: '혼밥'),
                    const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: Text('추출된 키워드', style: theme.textTheme.titleSmall)), const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: const [_Pill(label: '가성비', selected: true), _Pill(label: '조용한', selected: false), _Pill(label: '로컬맛집', selected: false), _Pill(label: '든든한', selected: true)]),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SurfaceCard(color: _primary.withOpacity(0.08), child: Row(children: [const Icon(Icons.check_circle_rounded, color: _primary), const SizedBox(width: 12), Expanded(child: Text('이 조건으로 맛집 3곳을 찾아드릴게요!', style: theme.textTheme.bodyMedium?.copyWith(color: _primaryText)))]))
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Icon(icon, color: _primary, size: 20), const SizedBox(width: 10), SizedBox(width: 58, child: Text(label, style: theme.textTheme.labelLarge?.copyWith(color: _secondaryText))), Expanded(child: Text(value, textAlign: TextAlign.right, style: theme.textTheme.labelLarge))]));
  }
}

class Top3RecommendationsScreen extends StatelessWidget {
  const Top3RecommendationsScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(title: '동네U의 추천', subtitle: '오늘의 완벽한 3곳을 찾았어요!', onBack: () => onOpen(AppScreen.aiCondition), trailing: _IconButton(icon: Icons.refresh_rounded, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); })),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _SurfaceCard(color: _primary.withOpacity(0.08), child: const Row(children: [Icon(Icons.auto_awesome_rounded, color: _primary), SizedBox(width: 12), Expanded(child: Text('충남대 근처, 1만원 이하 혼밥하기 좋은 곳들입니다.'))])),
                const SizedBox(height: 16),
                _RecommendationCard(rank: 1, tag: '가까워U', name: '할머니 국수', rating: '4.8', price: '~8,000원', category: '한식/국수', distance: '도보 3분', reason: '현재 위치에서 가장 가깝고, 비 오는 날 따뜻한 멸치 육수가 일품이에요.', color: _info, icon: Icons.ramen_dining_rounded, onTap: () => onOpen(AppScreen.storeDetail)),
                const SizedBox(height: 14),
                _RecommendationCard(rank: 2, tag: '아껴U', name: '궁동 보리밥', rating: '4.5', price: '~7,000원', category: '한식/보리밥', distance: '도보 8분', reason: '착한가격업소로 선정된 곳이며 푸짐한 반찬을 즐길 수 있어 가성비가 좋아요.', color: _success, icon: Icons.eco_rounded, onTap: () => onOpen(AppScreen.storeDetail)),
                const SizedBox(height: 14),
                _RecommendationCard(rank: 3, tag: '새로워U', name: '숨은 식탁', rating: '4.9', price: '~9,500원', category: '퓨전 일식', distance: '도보 10분', reason: '최근 동네 주민 리뷰가 빠르게 늘고 있는 조용한 혼밥 맛집이에요.', color: _warning, icon: Icons.set_meal_rounded, onTap: () => onOpen(AppScreen.storeDetail)),
                const SizedBox(height: 24),
                Text('추천 결과가 마음에 드셨나요?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: _PrimaryButton(label: '다시 추천', outline: true, onPressed: () => onOpen(AppScreen.aiCondition))), const SizedBox(width: 10), Expanded(child: _PrimaryButton(label: '조건 수정', onPressed: () => onOpen(AppScreen.filters)))]),
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
  const _RecommendationCard({required this.rank, required this.tag, required this.name, required this.rating, required this.price, required this.category, required this.distance, required this.reason, required this.color, required this.icon, required this.onTap});
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
              Stack(clipBehavior: Clip.none, children: [_IconTile(icon: icon, color: color, background: color.withOpacity(0.12), size: 58), Positioned(left: -7, top: -7, child: Container(width: 24, height: 24, alignment: Alignment.center, decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle), child: Text('$rank', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white))))]),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [_SmallTag(label: tag, color: color), const Spacer(), const Icon(Icons.star_rounded, color: _warning, size: 16), const SizedBox(width: 3), Text(rating, style: theme.textTheme.labelMedium)]), const SizedBox(height: 8), Text(name, style: theme.textTheme.titleMedium), const SizedBox(height: 6), Wrap(spacing: 8, runSpacing: 4, children: [_MetaText(price), _MetaText(category), _MetaText(distance)])])),
            ],
          ),
          const SizedBox(height: 14),
          Text(reason, style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
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
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(4)), child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)));
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _secondaryText));
  }
}

class ManualSearchFiltersScreen extends StatefulWidget {
  const ManualSearchFiltersScreen({super.key, required this.onOpen, required this.myLocation});
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  @override
  State<ManualSearchFiltersScreen> createState() => _ManualSearchFiltersScreenState();
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
                  child: Row(children: [
                    _IconButton(icon: Icons.arrow_back_rounded, onPressed: () => widget.onOpen(AppScreen.home)), 
                    const SizedBox(width: 8), 
                    const Expanded(child: _TextFieldBox(label: '', hint: '맛집, 메뉴 검색', icon: Icons.search_rounded)),
                  ]),
                ),
                Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), child: Row(children: [const Icon(Icons.location_on_rounded, color: _primary, size: 18), const SizedBox(width: 6), Text(widget.myLocation, style: theme.textTheme.labelLarge), const SizedBox(width: 4), const Icon(Icons.keyboard_arrow_down_rounded, color: _secondaryText, size: 18)])),
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
                Wrap(spacing: 8, runSpacing: 8, children: ['~7천원', '~1만원', '~1.5만원', '상관없음'].asMap().entries.map((e) => _Pill(label: e.value, selected: _selectedBudget == e.key, onTap: () => setState(() => _selectedBudget = e.key))).toList()),
                const SizedBox(height: 26),
                _SectionHeader(title: '오늘의 상황'),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: ['혼밥', '데이트', '친구와', '가족모임', '빠른 식사'].asMap().entries.map((e) => _Pill(label: e.value, selected: _selectedSituation == e.key, onTap: () => setState(() => _selectedSituation = e.key))).toList()),
                const SizedBox(height: 26),
                const _SectionHeader(title: '카테고리'), const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 4, 
                  mainAxisSpacing: 10, 
                  crossAxisSpacing: 10, 
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  children: [
                    _CategoryTile(icon: Icons.rice_bowl_rounded, label: '한식', selected: _selectedCategory == '한식', onTap: () => setState(() => _selectedCategory = '한식')), 
                    _CategoryTile(icon: Icons.ramen_dining_rounded, label: '일식/면', selected: _selectedCategory == '일식/면', onTap: () => setState(() => _selectedCategory = '일식/면')), 
                    _CategoryTile(icon: Icons.local_pizza_rounded, label: '양식', selected: _selectedCategory == '양식', onTap: () => setState(() => _selectedCategory = '양식')), 
                    _CategoryTile(icon: Icons.local_cafe_rounded, label: '카페', selected: _selectedCategory == '카페', onTap: () => setState(() => _selectedCategory = '카페'))
                  ]
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '로컬 특별 조건'), const SizedBox(height: 12),
                _CheckCard(title: '착한가격업소', subtitle: '행안부 지정 물가 안정 모범 업소', checked: _isGoodPrice, onTap: () => setState(() => _isGoodPrice = !_isGoodPrice)),
                _CheckCard(title: '전통시장 근처', subtitle: '시장 상권 활성화 가게', checked: _isMarket, onTap: () => setState(() => _isMarket = !_isMarket)),
                _CheckCard(title: '새로 생긴 가게', subtitle: '최근 6개월 이내 등록', checked: _isNew, onTap: () => setState(() => _isNew = !_isNew)),
              ],
            ),
          ),
          _BottomActionBar(child: Row(children: [_IconButton(icon: Icons.refresh_rounded, onPressed: () { 
  setState(() { _selectedBudget = 1; _selectedSituation = 0; _selectedCategory = '한식'; _isGoodPrice = true; _isMarket = false; _isNew = false; }); 
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('필터가 초기화되었습니다.'), behavior: SnackBarBehavior.floating)); 
}), const SizedBox(width: 12), Expanded(child: _PrimaryButton(label: '결과 보기', onPressed: () => widget.onOpen(AppScreen.recommendations)))]))
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.icon, required this.label, this.selected = false, this.onTap});
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
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? _primaryText : _secondaryText), textAlign: TextAlign.center)
        ]
      )
    );
  }
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({required this.title, required this.subtitle, this.checked = false, required this.onTap});
  final String title;
  final String subtitle;
  final bool checked;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: _SurfaceCard(onTap: onTap, padding: const EdgeInsets.all(16), child: Row(children: [Icon(checked ? Icons.check_box_rounded : Icons.check_box_outline_blank, color: checked ? _primary : _secondaryText), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)]))])));
  }
}

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isSaved = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              Stack(
                children: [
                  Container(height: 260, decoration: const BoxDecoration(gradient: LinearGradient(colors: [_tertiary, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: const Center(child: Icon(Icons.ramen_dining_rounded, color: Colors.white, size: 92))),
                  Positioned(top: 16, left: 16, child: _CircleAction(icon: Icons.arrow_back_rounded, onTap: () => widget.onOpen(AppScreen.recommendations))),
                  Positioned(top: 16, right: 16, child: Row(children: [_CircleAction(icon: Icons.share_rounded, onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }), const SizedBox(width: 8), _CircleAction(icon: Icons.bookmark_border_rounded, onTap: () => widget.onOpen(AppScreen.saved))])),
                  Positioned(left: 24, bottom: 22, child: const _SmallTag(label: '가까워U', color: _info)),
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
                        Row(children: [Expanded(child: Text('궁동 칼국수', style: theme.textTheme.headlineSmall)), Row(children: [const Icon(Icons.star_rounded, color: _warning, size: 18), const SizedBox(width: 3), Text('4.8', style: theme.textTheme.labelLarge)])]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: const [_Pill(label: '한식/국수'), _Pill(label: '도보 3분'), _Pill(label: '~8,000원')]),
                        const SizedBox(height: 18), const Divider(color: _alternate), const SizedBox(height: 14),
                        Row(children: [const Icon(Icons.auto_awesome_rounded, color: _primary, size: 20), const SizedBox(width: 8), Text('동네U 추천 이유', style: theme.textTheme.titleSmall)]),
                        const SizedBox(height: 8), Text('현재 위치에서 가장 가깝고, 비 오는 날 따뜻한 멸치 육수가 일품이에요.', style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('대표 메뉴', style: theme.textTheme.titleMedium), Text('2개', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))]),
                    const SizedBox(height: 12),
                    const _MenuItemCard(icon: Icons.ramen_dining_rounded, name: '바지락 칼국수', desc: '시원한 바지락 육수와 직접 뽑은 면', price: '8,000원'),
                    const SizedBox(height: 10),
                    const _MenuItemCard(icon: Icons.lunch_dining_rounded, name: '김치 만두', desc: '국수와 함께 먹기 좋은 매콤한 만두', price: '5,000원'),
                    const SizedBox(height: 20),
                    _SurfaceCard(color: _surfaceVariant.withOpacity(0.50), child: const Column(children: [_StoreInfoRow(icon: Icons.schedule_rounded, text: '매일 10:30 - 21:00'), _StoreInfoRow(icon: Icons.payments_rounded, text: '1인 평균 8,000원'), _StoreInfoRow(icon: Icons.info_outlined, text: '대전 유성구 궁동 대학로 근처', bottom: false)]))
                  ],
                ),
              ),
            ],
          ),
          Align(alignment: Alignment.bottomCenter, child: _BottomActionBar(child: Row(children: [SizedBox(width: 76, child: Column(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => widget.onOpen(AppScreen.saved), icon: const Icon(Icons.bookmark_border_rounded)), Text('저장', style: theme.textTheme.labelSmall)])), const SizedBox(width: 12), Expanded(child: _PrimaryButton(label: '길찾기', icon: Icons.near_me_rounded, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }))])))
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
    return Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withOpacity(0.88), shape: BoxShape.circle), child: IconButton(padding: EdgeInsets.zero, onPressed: onTap, icon: Icon(icon, color: _primaryText, size: 22)));
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.icon, required this.name, required this.desc, required this.price});
  final IconData icon;
  final String name;
  final String desc;
  final String price;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(padding: const EdgeInsets.all(16), child: Row(children: [_IconTile(icon: icon), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text(desc, style: Theme.of(context).textTheme.bodySmall)])), Text(price, style: Theme.of(context).textTheme.labelLarge)]));
  }
}

class _StoreInfoRow extends StatelessWidget {
  const _StoreInfoRow({required this.icon, required this.text, this.bottom = true});
  final IconData icon;
  final String text;
  final bool bottom;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: bottom ? 16 : 0), child: Row(children: [Icon(icon, color: _secondaryText, size: 20), const SizedBox(width: 14), Expanded(child: Text(text))]));
  }
}

class SavedHistoryScreen extends StatefulWidget {
  const SavedHistoryScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<SavedHistoryScreen> createState() => _SavedHistoryScreenState();
}

class _SavedHistoryScreenState extends State<SavedHistoryScreen> {
  bool _showSavedStores = true;

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
                Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), child: Column(children: [Row(children: [Text('저장', style: theme.textTheme.headlineSmall), const Spacer(), IconButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }, icon: const Icon(Icons.settings_rounded))]), const SizedBox(height: 14), Row(children: [Expanded(child: _Pill(label: '저장한 가게', selected: _showSavedStores, onTap: () => setState(() => _showSavedStores = true))), const SizedBox(width: 8), Expanded(child: _Pill(label: '추천 기록', selected: !_showSavedStores, onTap: () => setState(() => _showSavedStores = false)))])])),
                const Divider(height: 1, color: _alternate),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_showSavedStores) ...[
                  Row(children: [Text('총 2곳', style: theme.textTheme.titleMedium), const Spacer(), const Icon(Icons.sort_rounded, color: _secondaryText, size: 18), const SizedBox(width: 4), Text('최신순', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))]),
                  const SizedBox(height: 14),
                  _SavedStoreCard(icon: Icons.ramen_dining_rounded, name: '궁동 칼국수', rating: '4.8', category: '한식/국수', distance: '도보 3분', price: '~8,000원', onTap: () => widget.onOpen(AppScreen.storeDetail)),
                  const SizedBox(height: 12),
                  _SavedStoreCard(icon: Icons.local_dining_rounded, name: '할머니 분식', rating: '4.5', category: '분식', distance: '도보 6분', price: '~7,000원', onTap: () => widget.onOpen(AppScreen.storeDetail)),
                ] else ...[
                  Text('최근 추천 기록', style: theme.textTheme.titleMedium), 
                  const SizedBox(height: 12),
                  const _HistoryItem(query: '가성비 혼밥 추천', date: '오늘 저녁', result: '3곳 추천'),
                  const _HistoryItem(query: '데이트하기 좋은 카페', date: '어제', result: '3곳 추천'),
                  const SizedBox(height: 20),
                  _SurfaceCard(color: _surfaceVariant.withOpacity(0.50), child: Column(children: [const Icon(Icons.auto_awesome_rounded, color: _primary, size: 30), const SizedBox(height: 10), Text('새로운 추천을 받아보세요', style: theme.textTheme.titleSmall), const SizedBox(height: 12), _PrimaryButton(label: '추천 받기', compact: true, onPressed: () => widget.onOpen(AppScreen.aiChat))])),
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
  const _SavedStoreCard({required this.icon, required this.name, required this.rating, required this.category, required this.distance, required this.price, required this.onTap});
  final IconData icon;
  final String name;
  final String rating;
  final String category;
  final String distance;
  final String price;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: _SurfaceCard(onTap: onTap, padding: const EdgeInsets.all(16), child: Row(children: [_IconTile(icon: icon), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Row(children: [const Icon(Icons.star_rounded, color: _warning, size: 14), const SizedBox(width: 3), Text(rating, style: Theme.of(context).textTheme.labelSmall), Text(' · $category · $distance')]), const SizedBox(height: 3), Text(price, style: Theme.of(context).textTheme.bodySmall)])), const Icon(Icons.chevron_right_rounded, color: _secondaryText)])));
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.query, required this.date, required this.result});
  final String query;
  final String date;
  final String result;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: _SurfaceCard(padding: const EdgeInsets.all(16), child: Row(children: [const _IconTile(icon: Icons.history_rounded), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(query, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text('$date · $result', style: Theme.of(context).textTheme.bodySmall)]))])));
  }
}

class OwnerStoreRegistrationScreen extends StatelessWidget {
  const OwnerStoreRegistrationScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(title: '우리 가게 등록하기', onBack: () => onOpen(AppScreen.userType)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SurfaceCard(child: Column(children: [Row(children: [Text('기본 정보 입력', style: theme.textTheme.titleSmall), const Spacer(), Text('1 / 2', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))]), const SizedBox(height: 12), ClipRRect(borderRadius: BorderRadius.circular(999), child: const LinearProgressIndicator(value: 0.5, minHeight: 8, backgroundColor: _surfaceVariant, color: _primary))])),
                const SizedBox(height: 24), const _SectionHeader(title: '가게 기본 정보'), const SizedBox(height: 12),
                const _TextFieldBox(label: '가게 이름', hint: '동네유 식당', icon: Icons.storefront_rounded),
                const SizedBox(height: 14), const _TextFieldBox(label: '업종 카테고리', hint: '한식, 일식, 카페 등', icon: Icons.category_rounded),
                const SizedBox(height: 14), const _TextFieldBox(label: '가게 주소', hint: '주소를 검색하세요', icon: Icons.location_on_outlined, trailing: Icons.search_rounded),
                const SizedBox(height: 10), Text('정확한 위치는 추천 품질과 길찾기에 사용됩니다.', style: theme.textTheme.bodySmall),
                const SizedBox(height: 26), const _SectionHeader(title: '대표 메뉴'), const SizedBox(height: 12),
                const _MenuInputRow(), const SizedBox(height: 12),
                _PrimaryButton(label: '메뉴 추가하기', outline: true, icon: Icons.add_rounded, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
              ],
            ),
          ),
          _BottomActionBar(child: _PrimaryButton(label: '다음 단계', onPressed: () => onOpen(AppScreen.promotion))),
        ],
      ),
    );
  }
}

class _MenuInputRow extends StatelessWidget {
  const _MenuInputRow();
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(padding: const EdgeInsets.all(14), child: Row(children: [const _IconTile(icon: Icons.restaurant_menu_rounded), const SizedBox(width: 12), Expanded(child: Text('대표 메뉴명', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _accentText))), SizedBox(width: 92, child: Text('가격', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _accentText)))]));
  }
}

class AiPromotionHelperScreen extends StatelessWidget {
  const AiPromotionHelperScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(title: 'AI 홍보 도우미', onBack: () => onOpen(AppScreen.ownerRegistration), trailing: _IconButton(icon: Icons.history_rounded, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); })),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_secondary, _primary], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(32)),
                  child: Stack(
                    children: [
                      Align(alignment: Alignment.topRight, child: _softCircle(86, Colors.white.withOpacity(0.16))),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('우리 가게 홍보,\nAI에게 맡겨보세U!', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 8),
                          Text('메뉴 설명부터 SNS 문구까지\n클릭 한 번으로 완성됩니다.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.82))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24), const _SectionHeader(title: '필요한 홍보물을 선택해U'), const SizedBox(height: 12),
                const _FeatureCard(icon: Icons.campaign_rounded, title: 'SNS 홍보 문구', subtitle: '인스타그램, 당근마켓용 감성 문구', status: '최근 생성: 2일 전', action: '작성하기'),
                const _FeatureCard(icon: Icons.description_rounded, title: '메뉴/가게 소개', subtitle: '손님들의 침샘을 자극하는 설명글', status: '미작성', action: '생성하기'),
                const _FeatureCard(icon: Icons.local_offer_rounded, title: '타임딜 쿠폰', subtitle: '조용한 시간대 손님 모시는 문구', status: '최근 생성: 1시간 전', action: '만들기'),
                const SizedBox(height: 24),
                _SurfaceCard(color: _surface, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _SectionHeader(title: '홍보 정보 입력'), const SizedBox(height: 16), const _TextFieldBox(label: '홍보할 메뉴/이벤트', hint: '예: 신메뉴 들기름 막국수 출시', icon: Icons.restaurant_menu_rounded), const SizedBox(height: 16), const _TextFieldBox(label: '강조하고 싶은 키워드', hint: '예: 고소함, 로컬 식재료, 할머니 손맛', icon: Icons.sell_rounded)])),
                const SizedBox(height: 16), const _SectionHeader(title: '문구 분위기'), const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: const [_Pill(label: '친절한', selected: true), _Pill(label: '재치있는'), _Pill(label: '감성적인'), _Pill(label: '짧고 강한')]),
                const SizedBox(height: 18), _PrimaryButton(label: '문구 생성하기', icon: Icons.auto_awesome_rounded, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
                const SizedBox(height: 16), _SurfaceCard(color: _surfaceVariant.withOpacity(0.50), child: Row(children: [const Icon(Icons.tips_and_updates_rounded, color: _primary), const SizedBox(width: 12), Expanded(child: Text('구체적인 메뉴명과 분위기를 넣으면 더 자연스러운 홍보 문구가 만들어져요.', style: theme.textTheme.bodySmall))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.status, required this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String action;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: _SurfaceCard(padding: const EdgeInsets.all(16), child: Row(children: [_IconTile(icon: icon), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleSmall), const SizedBox(height: 4), Text(subtitle, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 6), Text(status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _secondaryText))])), Text(action, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _primary))])));
  }
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(width: 64, height: 64, decoration: const BoxDecoration(color: _surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.person_rounded, color: _accentText, size: 40)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('동네 주민님', style: theme.textTheme.headlineSmall), const SizedBox(height: 4), Text('dongneu@example.com', style: theme.textTheme.bodySmall)])),
                    _PrimaryButton(label: '수정', compact: true, outline: true, onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    _ExpandedStat(label: '내 리뷰', value: '12'),
                    _ExpandedStat(label: '저장한 가게', value: '3'),
                    _ExpandedStat(label: '내 포인트', value: '1,500P'),
                  ],
                ),
                const SizedBox(height: 32),
                const _SectionHeader(title: '내 활동'),
                const SizedBox(height: 12),
                _MenuTile(icon: Icons.history_rounded, label: '추천 기록 확인', onTap: () => onOpen(AppScreen.saved)),
                _MenuTile(icon: Icons.edit_note_rounded, label: '내가 쓴 리뷰 관리', onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
                _MenuTile(icon: Icons.notifications_none_rounded, label: '알림 설정', onTap: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('백엔드 연동 후 제공될 기능입니다 🚀'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1))); }),
                const SizedBox(height: 24),
                const _SectionHeader(title: '사장님 서비스'),
                const SizedBox(height: 12),
                _SurfaceCard(
                  color: _primary.withOpacity(0.06),
                  onTap: () => onOpen(AppScreen.userType),
                  child: Row(
                    children: [
                      const _IconTile(icon: Icons.add_business_rounded),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('사장님이신가요?', style: theme.textTheme.titleSmall), const SizedBox(height: 4), Text('가게 등록하고 AI 홍보 시작하기', style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText))])),
                      const Icon(Icons.chevron_right_rounded, color: _primary),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(onPressed: () => onOpen(AppScreen.auth), child: const Text('로그아웃', style: TextStyle(color: _secondaryText))),
              ],
            ),
          ),
          _BottomNav(current: AppScreen.mypage, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _ExpandedStat extends StatelessWidget {
  const _ExpandedStat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: _primary)), const SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _secondaryText))]));
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: _primaryText, size: 24),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded, color: _accentText),
      onTap: onTap,
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 16, 24, 16), decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _alternate))), child: child);
  }
}


class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, required this.onOpen, required this.onQueryChange});
  final ValueChanged<AppScreen> onOpen;
  final ValueChanged<String> onQueryChange;
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {'isAi': true, 'text': '안녕하세요! 동네U AI입니다. 오늘 어떤 식사나 모임을 계획하고 계신가요? 상황, 예산, 취향을 편하게 말씀해주세요.'},
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final userText = _controller.text;
    widget.onQueryChange(userText);
    setState(() {
      _messages.add({'isAi': false, 'text': userText});
      _controller.clear();
    });
    
    // AI가 생각하는 척 딜레이를 줍니다
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'isAi': true, 
            'text': '알겠습니다! 말씀해주신 조건에 맞춰 우리 동네 숨은 맛집을 분석했습니다. 아래 버튼을 눌러 추천 결과를 확인해보세요!',
            'action': true
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(title: 'AI 동네 검색', onBack: () => widget.onOpen(AppScreen.home)),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['isAi'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                    children: [
                      if (isAi) ...[
                        const _IconTile(icon: Icons.auto_awesome_rounded, size: 40),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: isAi ? _surface : _primary,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(24),
                                  topRight: const Radius.circular(24),
                                  bottomLeft: Radius.circular(isAi ? 4 : 24),
                                  bottomRight: Radius.circular(isAi ? 24 : 4),
                                ),
                                border: isAi ? Border.all(color: _alternate) : null,
                              ),
                              child: Text(
                                msg['text'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(color: isAi ? _primaryText : Colors.white, height: 1.5),
                              ),
                            ),
                            if (msg['action'] == true) ...[
                              const SizedBox(height: 12),
                              _PrimaryButton(
                                label: '추천 결과 보기',
                                icon: Icons.list_alt_rounded,
                                onPressed: () => widget.onOpen(AppScreen.aiCondition),
                              ),
                            ]
                          ],
                        ),
                      ),
                      if (!isAi) const SizedBox(width: 52),
                    ],
                  ),
                );
              },
            ),
          ),
          _BottomActionBar(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: _surfaceVariant, borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '예: 비 오는 날 어울리는 파전 맛집',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 52, height: 52,
                    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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