class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;
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
    setState(() {
      _messages.add({'isAi': false, 'text': _controller.text});
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
                                onPressed: () => widget.onOpen(AppScreen.recommendations),
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