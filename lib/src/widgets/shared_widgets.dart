part of '../../main.dart';

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ScrollScreen extends StatelessWidget {
  const _ScrollScreen({
    required this.children,
    this.bottom,
    this.padding = const EdgeInsets.all(24),
  });
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
              padding: padding.add(
                EdgeInsets.only(bottom: bottom == null ? 24 : 8),
              ),
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
  const _TopBar({
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });
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
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
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
  const _IconButton({
    required this.icon,
    required this.onPressed,
    this.visible = true,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final bool visible;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: visible
          ? IconButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              icon: Icon(icon, color: _primaryText),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outline = false,
    this.ghost = false,
    this.compact = false,
  });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            side: BorderSide(color: border),
          ),
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
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(color: _secondaryText),
          ),
        ],
      ],
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.label,
    required this.hint,
    required this.icon,
    this.trailing,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onTrailingTap,
  });
  final String label;
  final String hint;
  final IconData icon;
  final IconData? trailing;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTrailingTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _alternate),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: _accentText,
              ),
              prefixIcon: Icon(icon, size: 20, color: _secondaryText),
              suffixIcon: trailing != null
                  ? IconButton(
                      onPressed: onTrailingTap,
                      icon: Icon(trailing, size: 20, color: _secondaryText),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color = _surface,
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _alternate),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    this.color = _primary,
    this.background = const Color(0x1AFF7E33),
    this.size = 48,
  });
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size >= 48 ? 16 : 12),
      ),
      child: Icon(icon, color: color, size: size >= 48 ? 24 : 20),
    );
  }
}

class _Pill extends StatefulWidget {
  const _Pill({
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_Pill> createState() => _PillState();
}

class _PillState extends State<_Pill> {
  late bool _isSelected;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selected;
  }

  @override
  void didUpdateWidget(covariant _Pill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _isSelected = widget.selected;
    }
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
    final isSelected = widget.onTap == null ? _isSelected : widget.selected;
    final backgroundColor = isSelected
        ? chipColor.withOpacity(_isHovered ? 0.16 : 0.10)
        : (_isHovered ? chipColor.withOpacity(0.06) : _surface);
    final borderColor = isSelected
        ? chipColor
        : (_isHovered ? chipColor.withOpacity(0.45) : _alternate);
    final foregroundColor = isSelected ? chipColor : _primaryText;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(9999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isSelected ? chipColor : _secondaryText,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: foregroundColor),
                ),
              ],
            ),
          ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: _secondaryText),
          ),
        ),
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
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _alternate)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: '홈',
            selected: current == AppScreen.home,
            onTap: () => onOpen(AppScreen.home),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: '검색',
            selected:
                current == AppScreen.filters ||
                current == AppScreen.aiChat ||
                current == AppScreen.aiCondition ||
                current == AppScreen.recommendations,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: _surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '어떤 방식으로 검색할까요?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 24),
                        _SurfaceCard(
                          onTap: () {
                            Navigator.pop(context);
                            onOpen(AppScreen.aiChat);
                          },
                          child: Row(
                            children: [
                              const _IconTile(icon: Icons.auto_awesome_rounded),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI 맞춤 검색',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '상황을 말하면 딱 맞는 곳을 추천해줘요',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                        const SizedBox(height: 12),
                        _SurfaceCard(
                          onTap: () {
                            Navigator.pop(context);
                            onOpen(AppScreen.filters);
                          },
                          child: Row(
                            children: [
                              const _IconTile(
                                icon: Icons.tune_rounded,
                                background: Color(0x1A7A6F66),
                                color: _secondaryText,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '수동 상세 검색',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '카테고리, 예산 등을 직접 설정해요',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _NavItem(
            icon: Icons.bookmark_rounded,
            label: '저장',
            selected: current == AppScreen.saved,
            onTap: () => onOpen(AppScreen.saved),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: '마이',
            selected: current == AppScreen.mypage,
            onTap: () => onOpen(AppScreen.mypage),
          ),
        ],
      ),
    );
  }
}

class _OwnerBottomNav extends StatelessWidget {
  const _OwnerBottomNav({required this.current, required this.onOpen});
  final AppScreen current;
  final ValueChanged<AppScreen> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _alternate)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: '현황',
            selected: current == AppScreen.ownerDashboard,
            onTap: () => onOpen(AppScreen.ownerDashboard),
          ),
          _NavItem(
            icon: Icons.storefront_rounded,
            label: '가게',
            selected:
                current == AppScreen.ownerStoreManage ||
                current == AppScreen.ownerRegistration,
            onTap: () => onOpen(AppScreen.ownerStoreManage),
          ),
          _NavItem(
            icon: Icons.auto_awesome_rounded,
            label: 'AI홍보',
            selected: current == AppScreen.promotion,
            onTap: () => onOpen(AppScreen.promotion),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: '마이',
            selected: current == AppScreen.ownerMyPage,
            onTap: () => onOpen(AppScreen.ownerMyPage),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
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
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: _primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: _secondaryText),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(top: BorderSide(color: _alternate)),
      ),
      child: child,
    );
  }
}
