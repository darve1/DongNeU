part of '../../main.dart';

class AuthOnboardingScreen extends StatefulWidget {
  const AuthOnboardingScreen({
    super.key,
    required this.onOpen,
    required this.onAuthenticated,
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<void> Function() onAuthenticated;

  @override
  State<AuthOnboardingScreen> createState() => _AuthOnboardingScreenState();
}

class _AuthOnboardingScreenState extends State<AuthOnboardingScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!AppConfig.isSupabaseConfigured) {
      _showMessage('Supabase URL과 anon key를 --dart-define으로 넣어야 해요.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('올바른 이메일을 입력해주세요.');
      return;
    }
    if (password.length < 6) {
      _showMessage('비밀번호는 6자 이상이어야 해요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Supabase.instance.client.auth;
      final response = _isSignUp
          ? await auth.signUp(email: email, password: password)
          : await auth.signInWithPassword(email: email, password: password);

      if (!mounted) return;
      if (response.session == null && _isSignUp) {
        _showMessage('가입 확인 메일을 보냈어요. 확인 후 로그인해주세요.');
        setState(() => _isSignUp = false);
        return;
      }
      await widget.onAuthenticated();
    } on AuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authMessage(error.message));
    } catch (_) {
      if (!mounted) return;
      _showMessage('로그인 처리 중 문제가 생겼어요.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _authMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login')) return '이메일 또는 비밀번호가 맞지 않아요.';
    if (lower.contains('email not confirmed')) return '이메일 확인을 먼저 완료해주세요.';
    if (lower.contains('already registered') ||
        lower.contains('already been registered')) {
      return '이미 가입된 이메일이에요. 로그인으로 진행해주세요.';
    }
    return message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSocialPending() {
    _showMessage('소셜 로그인은 Supabase provider 설정 후 연결할 수 있어요.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperText = _isSignUp
        ? '이메일과 비밀번호로 동네유 계정을 만들어요'
        : '이메일과 비밀번호로 로그인해주세요';
    return _ScrollScreen(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 28,
                top: 20,
                child: _softCircle(120, _primary.withOpacity(0.10)),
              ),
              Positioned(
                right: 54,
                bottom: 22,
                child: _softCircle(82, _success.withOpacity(0.10)),
              ),
              Container(
                width: 188,
                height: 138,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: _alternate),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: _primary,
                  size: 72,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '반가워U, 동네유!',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          helperText,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText),
        ),
        const SizedBox(height: 28),
        _TextFieldBox(
          label: '이메일',
          hint: 'example@email.com',
          icon: Icons.mail_outline_rounded,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        _TextFieldBox(
          label: '비밀번호',
          hint: '비밀번호를 입력하세요',
          icon: Icons.lock_outline_rounded,
          trailing: _obscurePassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          obscureText: _obscurePassword,
          controller: _passwordController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          onTrailingTap: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '비밀번호 재설정은 다음 단계에서 연결 예정이에요',
            style: theme.textTheme.labelMedium?.copyWith(color: _secondaryText),
          ),
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: _isLoading ? '처리 중...' : (_isSignUp ? '회원가입' : '로그인'),
          onPressed: _isLoading ? () {} : _submit,
        ),
        const SizedBox(height: 20),
        const _DividerLabel('또는'),
        const SizedBox(height: 16),
        _SocialButton(
          label: '구글로 계속하기',
          icon: Icons.g_mobiledata_rounded,
          onTap: _showSocialPending,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Apple로 계속하기',
          icon: Icons.apple_rounded,
          onTap: _showSocialPending,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isSignUp ? '이미 계정이 있나요?' : '처음 오셨나요?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _secondaryText,
              ),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? '로그인' : '회원가입'),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _softCircle(double size, Color color) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      radius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 24),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({
    super.key,
    required this.onOpen,
    required this.onRoleSelected,
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<void> Function(String role) onRoleSelected;

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  bool _isSaving = false;

  Future<void> _saveRole(String role) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onRoleSelected(role);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('권한 저장에 실패했어요: ${error.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('권한 저장 중 문제가 생겼어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        _ScrollScreen(
          children: [
            const SizedBox(height: 24),
            Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_primary, _tertiary]),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '반가워U, 동네유!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '계정 유형을 선택하면 권한이 저장되고 화면 흐름이 달라져요',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _secondaryText,
              ),
            ),
            const SizedBox(height: 32),
            _ModeSelectionCard(
              icon: Icons.restaurant_rounded,
              title: '손님으로 시작하기',
              subtitle: '맛집 추천, 저장, 추천 기록을 이용하는 일반 손님 계정',
              button: '손님 계정 선택',
              onTap: () => _saveRole(AppRoles.customer),
            ),
            const SizedBox(height: 16),
            _ModeSelectionCard(
              icon: Icons.add_business_rounded,
              title: '사장님으로 시작하기',
              subtitle: '가게 등록과 AI 홍보 기능을 쓰는 사장님 계정',
              button: '사장님 계정 선택',
              outline: true,
              onTap: () => _saveRole(AppRoles.owner),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _isSaving
                    ? null
                    : () => widget.onOpen(AppScreen.ownerDashboard),
                child: const Text('이미 가게를 등록했다면 대시보드로 이동'),
              ),
            ),
          ],
        ),
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black12,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _alternate),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _primary),
                      SizedBox(height: 12),
                      Text('계정 권한을 저장하는 중...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModeSelectionCard extends StatelessWidget {
  const _ModeSelectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onTap,
    this.outline = false,
  });
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
          _IconTile(
            icon: icon,
            color: outline ? _secondary : _primary,
            background: outline
                ? _secondary.withOpacity(0.10)
                : _primary.withOpacity(0.10),
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _secondaryText),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(label: button, outline: outline, onPressed: onTap),
        ],
      ),
    );
  }
}

class LocationSetupScreen extends StatefulWidget {
  const LocationSetupScreen({
    super.key,
    required this.onOpen,
    required this.onLocationChange,
  });
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
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '내 동네 설정',
            onBack: () => widget.onOpen(AppScreen.userType),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: _surfaceVariant,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _alternate),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: _primary,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            const Text('네이버 지도가 준비 중입니다'),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: FloatingActionButton.small(
                          onPressed: () => _select('현재 위치 (궁동)'),
                          backgroundColor: _surface,
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: _primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _TextFieldBox(
                  label: '동네 검색',
                  hint: '동네 이름이나 도로명으로 검색',
                  icon: Icons.search_rounded,
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '주변 동네'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppDefaults.nearbyNeighborhoods
                      .map(
                        (loc) => _Pill(
                          label: loc,
                          selected: loc.contains(_selectedNeighborhood),
                          onTap: () => _select(loc),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '현재 설정된 위치'),
                const SizedBox(height: 12),
                _LocationItem(
                  title: _selectedNeighborhood,
                  subtitle: '현재 선택된 동네입니다',
                  selected: true,
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
                const SizedBox(height: 20),
                const _SectionHeader(title: '최근 검색한 위치'),
                const SizedBox(height: 12),
                _LocationItem(
                  title: '어은동 (카이스트)',
                  subtitle: '대전광역시 유성구 어은동',
                  onTap: () => _select('어은동'),
                ),
                const SizedBox(height: 10),
                _LocationItem(
                  title: '봉명동 (유성온천역)',
                  subtitle: '대전광역시 유성구 봉명동',
                  onTap: () => _select('봉명동'),
                ),
              ],
            ),
          ),
          _BottomActionBar(
            child: _PrimaryButton(
              label: '이 위치로 설정',
              onPressed: () {
                widget.onLocationChange(_selectedNeighborhood);
                widget.onOpen(AppScreen.home);
              },
            ),
          ),
          _OwnerBottomNav(current: AppScreen.promotion, onOpen: widget.onOpen),
        ],
      ),
    );
  }
}

class _LocationItem extends StatelessWidget {
  const _LocationItem({
    required this.title,
    required this.subtitle,
    this.selected = false,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(
            icon: Icons.place_rounded,
            color: selected ? _primary : _secondaryText,
            background: selected ? _primary.withOpacity(0.10) : _surfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle_rounded, color: _primary, size: 20),
        ],
      ),
    );
  }
}
