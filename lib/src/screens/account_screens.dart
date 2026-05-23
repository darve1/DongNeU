part of '../../main.dart';

class OwnerMyPageScreen extends StatelessWidget {
  const OwnerMyPageScreen({
    super.key,
    required this.onOpen,
    required this.onOpenCustomerService,
    required this.onSignOut,
    required this.userEmail,
  });
  final ValueChanged<AppScreen> onOpen;
  final VoidCallback onOpenCustomerService;
  final Future<void> Function() onSignOut;
  final String? userEmail;

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
                const Center(
                  child: _IconTile(
                    icon: Icons.storefront_rounded,
                    color: _secondary,
                    size: 88,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '사장님 계정',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  userEmail ?? '로그인 정보 없음',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                _MenuTile(
                  icon: Icons.dashboard_rounded,
                  label: '대시보드 보기',
                  onTap: () => onOpen(AppScreen.ownerDashboard),
                ),
                _MenuTile(
                  icon: Icons.edit_rounded,
                  label: '가게 정보 관리',
                  onTap: () => onOpen(AppScreen.ownerStoreManage),
                ),
                _MenuTile(
                  icon: Icons.home_rounded,
                  label: '고객 서비스로 이동',
                  onTap: onOpenCustomerService,
                ),
                _MenuTile(
                  icon: Icons.settings_rounded,
                  label: '설정',
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
                const SizedBox(height: 28),
                _PrimaryButton(
                  label: '로그아웃',
                  outline: true,
                  onPressed: onSignOut,
                ),
              ],
            ),
          ),
          _OwnerBottomNav(current: AppScreen.ownerMyPage, onOpen: onOpen),
        ],
      ),
    );
  }
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({
    super.key,
    required this.onOpen,
    required this.onSignOut,
    required this.userEmail,
    required this.accountRole,
    required this.onOpenOwnerService,
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<void> Function() onSignOut;
  final String? userEmail;
  final String? accountRole;
  final VoidCallback onOpenOwnerService;

  String get _roleLabel {
    return switch (accountRole) {
      AppRoles.owner => '사장님 계정',
      AppRoles.customer => '손님 계정',
      _ => '권한 미설정',
    };
  }

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
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: _surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: _accentText,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('동네 주민님', style: theme.textTheme.headlineSmall),
                          const SizedBox(height: 4),
                          Text(
                            userEmail ?? '로그인 정보 없음',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _surfaceVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _roleLabel,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PrimaryButton(
                      label: '수정',
                      compact: true,
                      outline: true,
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
                _MenuTile(
                  icon: Icons.history_rounded,
                  label: '추천 기록 확인',
                  onTap: () => onOpen(AppScreen.saved),
                ),
                _MenuTile(
                  icon: Icons.edit_note_rounded,
                  label: '내가 쓴 리뷰 관리',
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
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  label: '알림 설정',
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
                const SizedBox(height: 24),
                const _SectionHeader(title: '사장님 서비스'),
                const SizedBox(height: 12),
                _SurfaceCard(
                  color: _primary.withOpacity(0.06),
                  onTap: onOpenOwnerService,
                  child: Row(
                    children: [
                      const _IconTile(icon: Icons.add_business_rounded),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('사장님이신가요?', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              '가게 등록하고 AI 홍보 시작하기',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: _secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _primary),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: onSignOut,
                  child: const Text(
                    '로그아웃',
                    style: TextStyle(color: _secondaryText),
                  ),
                ),
              ],
            ),
          ),
          _BottomNav(current: AppScreen.mypage, onOpen: onOpen),
        ],
      ),
    );
  }
}
