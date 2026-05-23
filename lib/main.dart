import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NaverMapSdk.instance.initialize(clientId: 'j13ue7xko4');
  }
  runApp(const DongNeuApp());
}

// --- Design System ---
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
  ownerDashboard,
  ownerMyPage,
  ownerStoreManage,
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

  void _open(AppScreen screen) => setState(() => _screen = screen);
  void _setMyLocation(String loc) => setState(() => _myLocation = loc);
  void _setAiQuery(String query) => setState(() => _aiQuery = query);

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
    colorScheme: ColorScheme.fromSeed(seedColor: _primary, primary: _primary, secondary: _secondary, surface: _surface),
  );
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: const TextStyle(fontSize: 38, fontWeight: FontWeight.w700, color: _primaryText),
      headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _primaryText),
      titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primaryText),
      titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _primaryText),
      bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: _primaryText),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: _primaryText),
      bodySmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: _secondaryText),
      labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  );
}

class _AppRouter extends StatelessWidget {
  const _AppRouter({required this.screen, required this.onOpen, required this.myLocation, required this.onLocationChange, required this.aiQuery, required this.onAiQueryChange});
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
      AppScreen.ownerDashboard => OwnerDashboardScreen(onOpen: onOpen),
      AppScreen.ownerMyPage => OwnerMyPageScreen(onOpen: onOpen),
      AppScreen.ownerStoreManage => OwnerStoreManageScreen(onOpen: onOpen),
      AppScreen.mypage => MyPageScreen(onOpen: onOpen),
    };
  }
}

// --- Common Components ---
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: _background, body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: child))));
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onBack, this.trailing});
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(color: _surface, child: Column(children: [Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: Row(children: [if (onBack != null) IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: _primaryText)) else const SizedBox(width: 40), Expanded(child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)), trailing ?? const SizedBox(width: 40)])), const Divider(height: 1, color: _alternate)]));
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed, this.icon, this.outline = false, this.compact = false});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool outline;
  final bool compact;
  @override
  Widget build(BuildContext context) => SizedBox(height: compact ? 40 : 52, child: TextButton.icon(onPressed: onPressed, icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(), label: Text(label), style: TextButton.styleFrom(backgroundColor: outline ? Colors.transparent : _primary, foregroundColor: outline ? _primary : Colors.white, side: outline ? const BorderSide(color: _primary) : null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))));
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.padding = const EdgeInsets.all(20), this.onTap, this.color = _surface});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final card = Container(padding: padding, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24), border: Border.all(color: _alternate)), child: child);
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24), child: card);
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, this.color = _primary, this.size = 48});
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: size * 0.5));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(99), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: selected ? _primary : _surface, border: Border.all(color: selected ? _primary : _alternate), borderRadius: BorderRadius.circular(99)), child: Text(label, style: TextStyle(color: selected ? Colors.white : _primaryText, fontWeight: FontWeight.w600))));
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _alternate))), child: child);
}

// --- Screens ---
class AuthOnboardingScreen extends StatelessWidget {
  const AuthOnboardingScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: ListView(padding: const EdgeInsets.all(24), children: [const SizedBox(height: 60), const Center(child: _IconTile(icon: Icons.storefront_rounded, size: 100)), const SizedBox(height: 40), Text('반가워U, 동네유!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall), const SizedBox(height: 12), Text('우리 동네 숨은 맛집을 찾아드릴게요', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium), const SizedBox(height: 40), _PrimaryButton(label: '시작하기', onPressed: () => onOpen(AppScreen.userType))]));
}

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: ListView(padding: const EdgeInsets.all(24), children: [_TopBar(title: '회원 유형 선택'), const SizedBox(height: 32), _SurfaceCard(onTap: () => onOpen(AppScreen.location), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _IconTile(icon: Icons.person_rounded), const SizedBox(height: 16), Text('손님으로 시작하기', style: Theme.of(context).textTheme.titleLarge), const Text('우리 동네 맛집을 추천받아요')])), const SizedBox(height: 16), _SurfaceCard(onTap: () => onOpen(AppScreen.ownerRegistration), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const _IconTile(icon: Icons.add_business_rounded, color: _secondary), const SizedBox(height: 16), Text('사장님으로 시작하기', style: Theme.of(context).textTheme.titleLarge), const Text('내 가게를 등록하고 홍보해요')])), const SizedBox(height: 16), _SurfaceCard(color: _primary.withOpacity(0.05), onTap: () => onOpen(AppScreen.ownerDashboard), child: const Row(children: [Icon(Icons.dashboard_rounded, color: _primary), SizedBox(width: 12), Text('이미 등록하셨나요? 대시보드 가기')]))]));
}

class LocationSetupScreen extends StatelessWidget {
  const LocationSetupScreen({super.key, required this.onOpen, required this.onLocationChange});
  final ValueChanged<AppScreen> onOpen;
  final ValueChanged<String> onLocationChange;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '위치 설정', onBack: () => onOpen(AppScreen.userType)), Expanded(child: Center(child: Text('네이버 지도는 앱에서 지원됩니다\n(현재 위치: 궁동)', textAlign: TextAlign.center))), _BottomActionBar(child: _PrimaryButton(label: '이 위치로 설정', onPressed: () => onOpen(AppScreen.home)))]));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpen, required this.myLocation});
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('안녕하세요,'), Text(myLocation, style: Theme.of(context).textTheme.titleLarge)]), IconButton(onPressed: () => onOpen(AppScreen.mypage), icon: const Icon(Icons.person_outline))]), const SizedBox(height: 24), _SurfaceCard(color: _primary, onTap: () => onOpen(AppScreen.aiChat), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome, color: Colors.white), SizedBox(height: 12), Text('AI 맛집 추천 받기', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text('상황만 말하면 딱 맞는 곳을 찾아드려요', style: TextStyle(color: Colors.white70))]))])), _BottomNav(current: AppScreen.home, onOpen: onOpen)]));
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, required this.onOpen, required this.onQueryChange});
  final ValueChanged<AppScreen> onOpen;
  final ValueChanged<String> onQueryChange;
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}
class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _c = TextEditingController();
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: 'AI 추천', onBack: () => widget.onOpen(AppScreen.home)), const Expanded(child: Center(child: Text('무엇을 도와드릴까요?'))), _BottomActionBar(child: Row(children: [Expanded(child: TextField(controller: _c, decoration: const InputDecoration(hintText: '질문을 입력하세요'))), IconButton(onPressed: () { widget.onQueryChange(_c.text); widget.onOpen(AppScreen.aiCondition); }, icon: const Icon(Icons.send, color: _primary))]))]));
}

class AiConditionConfirmationScreen extends StatelessWidget {
  const AiConditionConfirmationScreen({super.key, required this.onOpen, required this.query});
  final ValueChanged<AppScreen> onOpen;
  final String query;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '조건 확인', onBack: () => onOpen(AppScreen.aiChat)), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [Text('분석된 조건', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 20), _SurfaceCard(child: Text('"$query"'))])), _BottomActionBar(child: _PrimaryButton(label: '이대로 추천 받기', onPressed: () => onOpen(AppScreen.recommendations)))]));
}

class Top3RecommendationsScreen extends StatelessWidget {
  const Top3RecommendationsScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '추천 결과', onBack: () => onOpen(AppScreen.home)), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [for (var i = 1; i <= 3; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: _SurfaceCard(onTap: () => onOpen(AppScreen.storeDetail), child: Text('추천 맛집 $i')))])), _BottomNav(current: AppScreen.home, onOpen: onOpen)]));
}

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}
class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _saved = false;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '가게 상세', onBack: () => widget.onOpen(AppScreen.home), trailing: IconButton(onPressed: () => setState(() => _saved = !_saved), icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border, color: _primary))), const Expanded(child: Center(child: Text('가게 정보 준비중'))), _BottomActionBar(child: _PrimaryButton(label: '길찾기', onPressed: () {}))]));
}

class SavedHistoryScreen extends StatefulWidget {
  const SavedHistoryScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  State<SavedHistoryScreen> createState() => _SavedHistoryScreenState();
}
class _SavedHistoryScreenState extends State<SavedHistoryScreen> {
  bool _tab1 = true;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '저장/기록'), Padding(padding: const EdgeInsets.all(16), child: Row(children: [Expanded(child: _Pill(label: '저장한 가게', selected: _tab1, onTap: () => setState(() => _tab1 = true))), const SizedBox(width: 8), Expanded(child: _Pill(label: '추천 기록', selected: !_tab1, onTap: () => setState(() => _tab1 = false)))]).paddingSymmetric(horizontal: 8)), const Expanded(child: Center(child: Text('목록이 비어있습니다'))), _BottomNav(current: AppScreen.saved, onOpen: widget.onOpen)]));
}

class ManualSearchFiltersScreen extends StatelessWidget {
  const ManualSearchFiltersScreen({super.key, required this.onOpen, required this.myLocation});
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '상세 검색', onBack: () => onOpen(AppScreen.home)), const Expanded(child: Center(child: Text('필터 설정 준비중'))), _BottomActionBar(child: _PrimaryButton(label: '결과 보기', onPressed: () => onOpen(AppScreen.recommendations)))]));
}

// --- Owner Screens ---
class OwnerStoreRegistrationScreen extends StatefulWidget {
  const OwnerStoreRegistrationScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  State<OwnerStoreRegistrationScreen> createState() => _OwnerStoreRegistrationScreenState();
}
class _OwnerStoreRegistrationScreenState extends State<OwnerStoreRegistrationScreen> {
  String _cat = '한식';
  int _budget = 1;
  final cats = {'한식': Icons.rice_bowl, '일식': Icons.ramen_dining, '양식': Icons.local_pizza, '중식': Icons.kebab_dining, '카페': Icons.local_cafe, '술집': Icons.local_bar, '기타': Icons.more_horiz};
  
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '내 가게 등록 (1/2)', onBack: () => widget.onOpen(AppScreen.userType)), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [const Text('가게 이름'), const TextField(decoration: InputDecoration(hintText: '가게 이름을 입력하세요')), const SizedBox(height: 24), const Text('업종 카테고리'), const SizedBox(height: 12), GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, children: cats.entries.map((e) => _SurfaceCard(color: _cat == e.key ? _primary : _surface, padding: EdgeInsets.zero, onTap: () => setState(() => _cat = e.key), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(e.value, color: _cat == e.key ? Colors.white : _primary), Text(e.key, style: TextStyle(fontSize: 12, color: _cat == e.key ? Colors.white : _primaryText))]))).toList()), const SizedBox(height: 24), const Text('희망 예산대'), Wrap(spacing: 8, children: ['~1만원', '~2만원', '그 이상'].asMap().entries.map((e) => _Pill(label: e.value, selected: _budget == e.key, onTap: () => setState(() => _budget = e.key))).toList()), const SizedBox(height: 24), const Text('가게 위치'), const TextField(decoration: InputDecoration(hintText: '주소를 입력하세요'))])), _BottomActionBar(child: _PrimaryButton(label: '다음 단계', onPressed: () => widget.onOpen(AppScreen.promotion)))]));
}

class AiPromotionHelperScreen extends StatefulWidget {
  const AiPromotionHelperScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  State<AiPromotionHelperScreen> createState() => _AiPromotionHelperScreenState();
}
class _AiPromotionHelperScreenState extends State<AiPromotionHelperScreen> {
  final prompts = ['우리 가게는 신선한 재료만 써요!', '분위기 좋은 데이트 코스로 딱!', '혼밥족을 위한 1인 세트 출시!'];
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: 'AI 홍보 도우미 (2/2)', onBack: () => widget.onOpen(AppScreen.ownerRegistration)), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [const Text('우리 가게 특징'), const TextField(maxLines: 3, decoration: InputDecoration(hintText: 'AI가 홍보 문구를 잘 만들 수 있게 설명해주세요')), const SizedBox(height: 24), _PrimaryButton(label: 'AI 홍보 문구 생성하기', icon: Icons.auto_awesome, outline: true, onPressed: () {}), const SizedBox(height: 24), const Text('생성된 홍보 문구 목록'), for (var p in prompts) Padding(padding: const EdgeInsets.only(top: 12), child: _SurfaceCard(child: Row(children: [Expanded(child: Text(p)), IconButton(icon: const Icon(Icons.copy, size: 18), onPressed: () {})])))])), _BottomActionBar(child: _PrimaryButton(label: '등록 완료 및 대시보드', onPressed: () => widget.onOpen(AppScreen.ownerDashboard)))]));
}

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [Text('사장님 대시보드', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 20), _SurfaceCard(color: _primary.withOpacity(0.1), child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_Stat(l: '조회수', v: '1.2k'), _Stat(l: '단골', v: '42'), _Stat(l: 'AI추천', v: '15')])), const SizedBox(height: 24), Text('빠른 메뉴', style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 12), _OwnerMenuTile(i: Icons.edit, l: '가게 정보 수정', onTap: () => onOpen(AppScreen.ownerStoreManage)), _OwnerMenuTile(i: Icons.campaign, l: '새 홍보물 만들기', onTap: () => onOpen(AppScreen.promotion)), _OwnerMenuTile(i: Icons.star, l: '리뷰 관리', onTap: () {})])), _OwnerBottomNav(current: AppScreen.ownerDashboard, onOpen: onOpen)]));
}

class OwnerStoreManageScreen extends StatelessWidget {
  const OwnerStoreManageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '가게 관리', onBack: () => onOpen(AppScreen.ownerDashboard)), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [const Text('영업 상태'), SwitchListTile(value: true, onChanged: (v) {}, title: const Text('영업 중')), const SizedBox(height: 24), const Text('메뉴 관리'), for (var m in ['칼국수', '만두']) ListTile(title: Text(m), trailing: const Icon(Icons.edit))])), _OwnerBottomNav(current: AppScreen.ownerDashboard, onOpen: onOpen)]));
}

class OwnerMyPageScreen extends StatelessWidget {
  const OwnerMyPageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '사장님 마이페이지'), Expanded(child: ListView(padding: const EdgeInsets.all(24), children: [const Center(child: _IconTile(icon: Icons.store, size: 80)), const SizedBox(height: 16), const Text('동네유 식당 사장님', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 32), _OwnerMenuTile(i: Icons.account_balance_wallet, l: '정산 내역', onTap: () {}), _OwnerMenuTile(i: Icons.settings, l: '설정', onTap: () {}), const SizedBox(height: 32), _PrimaryButton(label: '로그아웃', outline: true, onPressed: () => onOpen(AppScreen.auth))])), _OwnerBottomNav(current: AppScreen.ownerMyPage, onOpen: onOpen)]));
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => _PhoneFrame(child: Column(children: [_TopBar(title: '마이페이지'), const Expanded(child: Center(child: Text('손님 프로필'))), _BottomNav(current: AppScreen.mypage, onOpen: onOpen)]));
}

// --- Utils & Navs ---
class _Stat extends StatelessWidget {
  const _Stat({required this.l, required this.v});
  final String l, v;
  @override
  Widget build(BuildContext context) => Column(children: [Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primary)), Text(l, style: const TextStyle(fontSize: 12, color: _secondaryText))]);
}
class _OwnerMenuTile extends StatelessWidget {
  const _OwnerMenuTile({required this.i, required this.l, required this.onTap});
  final IconData i; final String l; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(leading: Icon(i, color: _primary), title: Text(l), trailing: const Icon(Icons.chevron_right), onTap: onTap);
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onOpen});
  final AppScreen current; final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => Container(height: 80, decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _alternate))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_NavItem(icon: Icons.home, label: '홈', selected: current == AppScreen.home, onTap: () => onOpen(AppScreen.home)), _NavItem(icon: Icons.search, label: '검색', selected: false, onTap: () => onOpen(AppScreen.filters)), _NavItem(icon: Icons.bookmark, label: '저장', selected: current == AppScreen.saved, onTap: () => onOpen(AppScreen.saved)), _NavItem(icon: Icons.person, label: '마이', selected: current == AppScreen.mypage, onTap: () => onOpen(AppScreen.mypage))]));
}
class _OwnerBottomNav extends StatelessWidget {
  const _OwnerBottomNav({required this.current, required this.onOpen});
  final AppScreen current; final ValueChanged<AppScreen> onOpen;
  @override
  Widget build(BuildContext context) => Container(height: 80, decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _alternate))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_NavItem(icon: Icons.dashboard, label: '현황', selected: current == AppScreen.ownerDashboard, onTap: () => onOpen(AppScreen.ownerDashboard)), _NavItem(icon: Icons.auto_awesome, label: 'AI홍보', selected: current == AppScreen.promotion, onTap: () => onOpen(AppScreen.promotion)), _NavItem(icon: Icons.person, label: '마이', selected: current == AppScreen.ownerMyPage, onTap: () => onOpen(AppScreen.ownerMyPage))]));
}
class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: selected ? _primary : _secondaryText), Text(label, style: TextStyle(color: selected ? _primary : _secondaryText, fontSize: 11))]));
}

extension PaddingExtension on Widget {
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) => Padding(padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical), child: this);
}
