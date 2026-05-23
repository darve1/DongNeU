part of '../../main.dart';

class OwnerStoreRegistrationScreen extends StatefulWidget {
  const OwnerStoreRegistrationScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<OwnerStoreRegistrationScreen> createState() =>
      _OwnerStoreRegistrationScreenState();
}

class _OwnerStoreRegistrationScreenState
    extends State<OwnerStoreRegistrationScreen> {
  final _storeNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _representativeMenuController = TextEditingController();
  final _representativePriceController = TextEditingController();
  final List<_MenuDraft> _additionalMenus = [];
  AddressSearchResult? _selectedAddress;
  bool _isSearchingAddress = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _categoryController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _descriptionController.dispose();
    _representativeMenuController.dispose();
    _representativePriceController.dispose();
    for (final menu in _additionalMenus) {
      menu.dispose();
    }
    super.dispose();
  }

  int? _parsePrice(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.isEmpty) return null;
    return int.tryParse(normalized);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<List<AddressSearchResult>> _searchKakaoAddress(String query) async {
    final uri = Uri.parse(
      '${AppConfig.flaskAiBaseUrl}/api/address/search',
    ).replace(queryParameters: {'query': query});
    final response = await http
        .get(uri, headers: _jsonHeadersWithAuth())
        .timeout(const Duration(seconds: 12));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('주소 검색 API 요청에 실패했어요.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('주소 검색 응답 형식이 올바르지 않아요.');
    }
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] as String? ?? '주소 검색에 실패했어요.');
    }

    final documents = decoded['documents'];
    if (documents is! List) return const [];
    return documents
        .whereType<Map>()
        .map(
          (item) =>
              AddressSearchResult.fromKakao(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.address != '주소 정보 없음')
        .toList(growable: false);
  }

  Future<void> _openAddressSearch() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) {
      _showMessage('검색할 주소나 건물명을 입력해주세요.');
      return;
    }

    setState(() => _isSearchingAddress = true);
    try {
      final results = await _searchKakaoAddress(query);
      if (!mounted) return;
      if (results.isEmpty) {
        _showMessage('검색 결과가 없어요. 다른 주소로 다시 검색해주세요.');
        return;
      }

      final selected = await showModalBottomSheet<AddressSearchResult>(
        context: context,
        backgroundColor: _surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              itemCount: results.length + 1,
              separatorBuilder: (context, index) =>
                  const Divider(color: _alternate),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '주소 선택',
                    style: Theme.of(context).textTheme.titleLarge,
                  );
                }
                final result = results[index - 1];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(result.displayAddress),
                  subtitle: result.roadAddress != null
                      ? Text(result.address)
                      : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, result),
                );
              },
            ),
          );
        },
      );

      if (selected == null || !mounted) return;
      setState(() {
        _selectedAddress = selected;
        _addressController.text = selected.displayAddress;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  void _addAdditionalMenu() {
    setState(() => _additionalMenus.add(_MenuDraft()));
  }

  void _removeAdditionalMenu(int index) {
    final removed = _additionalMenus.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _saveStore() async {
    if (_isSaving) return;
    if (!AppConfig.isSupabaseConfigured) {
      _showMessage('Supabase 설정이 필요해요.');
      return;
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _showMessage('로그인 후 가게를 등록할 수 있어요.');
      return;
    }

    final storeName = _storeNameController.text.trim();
    final category = _categoryController.text.trim();
    final address = _addressController.text.trim();
    final representativeMenu = _representativeMenuController.text.trim();
    final representativePrice = _parsePrice(
      _representativePriceController.text,
    );

    if (storeName.isEmpty) {
      _showMessage('가게 이름을 입력해주세요.');
      return;
    }
    if (category.isEmpty) {
      _showMessage('업종 카테고리를 입력해주세요.');
      return;
    }
    if (address.isEmpty || _selectedAddress == null) {
      _showMessage('주소 찾기 API로 가게 주소를 선택해주세요.');
      return;
    }
    if (representativeMenu.isEmpty || representativePrice == null) {
      _showMessage('대표 메뉴명과 가격을 입력해주세요.');
      return;
    }

    final menuRows = <Map<String, dynamic>>[
      {
        'name': representativeMenu,
        'price': representativePrice,
        'is_representative': true,
      },
    ];

    for (final menu in _additionalMenus) {
      final name = menu.nameController.text.trim();
      final priceText = menu.priceController.text.trim();
      if (name.isEmpty && priceText.isEmpty) continue;
      final price = _parsePrice(priceText);
      if (name.isEmpty || price == null) {
        _showMessage('추가 메뉴의 메뉴명과 가격을 모두 입력해주세요.');
        return;
      }
      menuRows.add({'name': name, 'price': price, 'is_representative': false});
    }

    setState(() => _isSaving = true);
    try {
      final fullAddress = [
        address,
        _detailAddressController.text.trim(),
      ].where((value) => value.isNotEmpty).join(' ');

      final store = await Supabase.instance.client
          .from('stores')
          .insert({
            'owner_id': session.user.id,
            'name': storeName,
            'category': category,
            'address': fullAddress,
            'lat': _selectedAddress?.lat,
            'lng': _selectedAddress?.lng,
            'description': _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          })
          .select('id')
          .single();

      final storeId = store['id'] as String;
      await Supabase.instance.client
          .from('menu_items')
          .insert(
            menuRows.map((menu) => {...menu, 'store_id': storeId}).toList(),
          );

      if (!mounted) return;
      _showMessage('가게와 메뉴를 등록했어요.');
      widget.onOpen(AppScreen.promotion);
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showMessage('가게 저장에 실패했어요: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('가게 저장 중 문제가 생겼어요: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '우리 가게 등록하기',
            onBack: () => widget.onOpen(AppScreen.userType),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SurfaceCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('기본 정보 입력', style: theme.textTheme.titleSmall),
                          const Spacer(),
                          Text(
                            '1 / 2',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(
                          value: 0.5,
                          minHeight: 8,
                          backgroundColor: _surfaceVariant,
                          color: _primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '가게 기본 정보'),
                const SizedBox(height: 12),
                _TextFieldBox(
                  label: '가게 이름',
                  hint: '동네유 식당',
                  icon: Icons.storefront_rounded,
                  controller: _storeNameController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _TextFieldBox(
                  label: '업종 카테고리',
                  hint: '한식, 일식, 카페 등',
                  icon: Icons.category_rounded,
                  controller: _categoryController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _TextFieldBox(
                  label: '가게 주소',
                  hint: '주소나 건물명을 입력하고 검색',
                  icon: Icons.location_on_outlined,
                  trailing: _isSearchingAddress
                      ? Icons.hourglass_empty_rounded
                      : Icons.search_rounded,
                  controller: _addressController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _openAddressSearch(),
                  onTrailingTap: _isSearchingAddress
                      ? null
                      : _openAddressSearch,
                ),
                const SizedBox(height: 14),
                _TextFieldBox(
                  label: '상세 주소',
                  hint: '층, 호수 등 상세 주소',
                  icon: Icons.apartment_rounded,
                  controller: _detailAddressController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedAddress == null
                      ? '정확한 위치는 추천 품질과 길찾기에 사용됩니다.'
                      : '주소 선택 완료: ${_selectedAddress!.displayAddress}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '대표 메뉴'),
                const SizedBox(height: 12),
                _MenuInputRow(
                  nameController: _representativeMenuController,
                  priceController: _representativePriceController,
                  representative: true,
                ),
                ..._additionalMenus.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _MenuInputRow(
                      nameController: entry.value.nameController,
                      priceController: entry.value.priceController,
                      representative: false,
                      onRemove: () => _removeAdditionalMenu(entry.key),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _PrimaryButton(
                  label: '메뉴 추가하기',
                  outline: true,
                  icon: Icons.add_rounded,
                  onPressed: _addAdditionalMenu,
                ),
                const SizedBox(height: 26),
                const _SectionHeader(title: '가게 특징 (AI 홍보용)'),
                const SizedBox(height: 8),
                Text(
                  'AI가 멋진 홍보 문구를 만들 수 있도록 우리 가게만의 매력을 알려주세요.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _Pill(label: '혼밥 환영', selected: true),
                    _Pill(label: '가성비 최고'),
                    _Pill(label: '분위기 맛집'),
                    _Pill(label: '주차 가능'),
                    _Pill(label: '반려동물 동반'),
                    _Pill(label: '착한가격업소'),
                  ],
                ),
                const SizedBox(height: 14),
                _TextFieldBox(
                  label: '추가 설명',
                  hint: '우리 가게만의 특별함을 적어주세요',
                  icon: Icons.edit_note_rounded,
                  controller: _descriptionController,
                ),
              ],
            ),
          ),
          _BottomActionBar(
            child: _PrimaryButton(
              label: _isSaving ? '저장 중...' : '가게 등록하기',
              onPressed: _isSaving ? () {} : _saveStore,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuInputRow extends StatelessWidget {
  const _MenuInputRow({
    required this.nameController,
    required this.priceController,
    required this.representative,
    this.onRemove,
  });

  final TextEditingController nameController;
  final TextEditingController priceController;
  final bool representative;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _IconTile(
            icon: representative
                ? Icons.restaurant_menu_rounded
                : Icons.add_circle_outline_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: representative ? '대표 메뉴명' : '추가 메뉴명',
                border: InputBorder.none,
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _accentText),
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '가격',
                border: InputBorder.none,
                hintStyle: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: _accentText),
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, color: _secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}
