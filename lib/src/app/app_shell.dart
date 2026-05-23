part of '../../main.dart';

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
  final List<AppScreen> _history = [];
  String _myLocation = AppDefaults.location;
  String _aiQuery = AppDefaults.aiQuery;
  List<AiRecommendation> _aiRecommendations = const [];
  AiConditions? _aiConditions;
  List<DongNeuStore> _stores = const [];
  Set<String> _savedStoreIds = const {};
  DongNeuStore? _selectedStore;
  bool _isLoadingStores = false;
  String? _storesError;
  Session? _session;
  String? _accountRole;

  void _open(AppScreen screen) {
    setState(() {
      _history.add(_screen);
      _screen = screen;
    });
  }

  void _goBack() {
    if (_history.isEmpty) return;
    setState(() => _screen = _history.removeLast());
  }

  void _openCustomerService() {
    setState(() {
      _accountRole = AppRoles.customer;
      _screen = AppScreen.home;
    });
    unawaited(_updateRoleInDb(AppRoles.customer));
    unawaited(_refreshCustomerData());
  }

  void _openOwnerService() {
    setState(() {
      _accountRole = AppRoles.owner;
      _screen = AppScreen.ownerDashboard;
    });
    unawaited(_updateRoleInDb(AppRoles.owner));
  }

  void _setMyLocation(String loc) {
    setState(() => _myLocation = loc);
  }

  void _setAiQuery(String query) {
    setState(() => _aiQuery = query);
  }

  List<String> _keywordsFromQuery(String query) {
    return RecommendationKeywords.candidates
        .where((keyword) => query.contains(keyword))
        .toList();
  }

  Future<void> _saveRecommendationHistory({
    required String query,
    required Map<String, dynamic> response,
    required List<AiRecommendation> recommendations,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return;
    final session = Supabase.instance.client.auth.currentSession ?? _session;
    if (session == null) return;

    try {
      final resultStoreIds = recommendations
          .map((recommendation) {
            final normalizedName = recommendation.storeName.replaceAll(
              RegExp(r'\s+'),
              '',
            );
            for (final store in _stores) {
              if (store.name.replaceAll(RegExp(r'\s+'), '') == normalizedName) {
                return store.id;
              }
            }
            return null;
          })
          .whereType<String>()
          .toSet()
          .toList(growable: false);
      await Supabase.instance.client.from('recommendation_history').insert({
        'user_id': session.user.id,
        'query': query,
        'location_text': _myLocation,
        'keywords': _keywordsFromQuery(query),
        'candidate_store_ids': _stores
            .map((store) => store.id)
            .take(12)
            .toList(growable: false),
        'result_store_ids': resultStoreIds,
        'ai_response': {
          'flask_response': response,
          'recommendations': recommendations
              .map((item) => item.toJson())
              .toList(),
        },
      });
    } catch (error) {
      debugPrint('Failed to save recommendation history: $error');
    }
  }

  List<DongNeuStore> _parseStoreRows(dynamic response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)))
        .where((store) => store.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _refreshCustomerData() async {
    if (!AppConfig.isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      if (!mounted) return;
      setState(() {
        _stores = const [];
        _savedStoreIds = const {};
        _isLoadingStores = false;
        _storesError = null;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingStores = true;
        _storesError = null;
      });
    }

    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('stores')
            .select(StoreQueries.storeSelectColumns)
            .eq('is_active', true)
            .order('rating', ascending: false)
            .limit(50),
        Supabase.instance.client.from('saved_stores').select('store_id'),
      ]);

      if (!mounted) return;
      final shuffled = List<DongNeuStore>.from(_parseStoreRows(responses[0]))
        ..shuffle();
      setState(() {
        _stores = shuffled;
        _savedStoreIds = (responses[1] as List)
            .whereType<Map>()
            .map((item) => item['store_id']?.toString())
            .whereType<String>()
            .toSet();
        _isLoadingStores = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingStores = false;
        _storesError = error.toString();
      });
    }
  }

  Future<DongNeuStore?> _fetchStoreById(String storeId) async {
    if (!AppConfig.isSupabaseConfigured) return null;
    final response = await Supabase.instance.client
        .from('stores')
        .select(StoreQueries.storeSelectColumns)
        .eq('id', storeId)
        .maybeSingle();
    if (response == null) return null;
    return DongNeuStore.fromJson(response);
  }

  Future<DongNeuStore?> _fetchStoreByName(String storeName) async {
    if (!AppConfig.isSupabaseConfigured) return null;
    final response = await Supabase.instance.client
        .from('stores')
        .select(StoreQueries.storeSelectColumns)
        .eq('name', storeName)
        .maybeSingle();
    if (response == null) return null;
    return DongNeuStore.fromJson(response);
  }

  void _openStoreDetail(DongNeuStore store) {
    setState(() {
      _selectedStore = store;
      _screen = AppScreen.storeDetail;
    });
  }

  Future<bool> _openStoreById(String storeId) async {
    DongNeuStore? cached;
    for (final store in _stores) {
      if (store.id == storeId) {
        cached = store;
        break;
      }
    }
    if (cached != null) {
      _openStoreDetail(cached);
      return true;
    }

    final store = await _fetchStoreById(storeId);
    if (store == null || !mounted) return false;
    _openStoreDetail(store);
    return true;
  }

  Future<bool> _openStoreByName(String storeName) async {
    final normalizedName = storeName.replaceAll(RegExp(r'\s+'), '');
    DongNeuStore? cached;
    for (final store in _stores) {
      if (store.name.replaceAll(RegExp(r'\s+'), '') == normalizedName) {
        cached = store;
        break;
      }
    }
    if (cached != null) {
      _openStoreDetail(cached);
      return true;
    }

    final store = await _fetchStoreByName(storeName);
    if (store == null || !mounted) return false;
    _openStoreDetail(store);
    return true;
  }

  Future<void> _toggleSavedStore(String storeId) async {
    if (!AppConfig.isSupabaseConfigured) {
      throw Exception('Supabase 설정이 필요해요.');
    }
    final session = Supabase.instance.client.auth.currentSession ?? _session;
    if (session == null) {
      throw Exception('로그인 후 저장할 수 있어요.');
    }

    final wasSaved = _savedStoreIds.contains(storeId);
    if (wasSaved) {
      await Supabase.instance.client
          .from('saved_stores')
          .delete()
          .eq('user_id', session.user.id)
          .eq('store_id', storeId);
    } else {
      await Supabase.instance.client.from('saved_stores').insert({
        'user_id': session.user.id,
        'store_id': storeId,
      });
    }

    if (!mounted) return;
    setState(() {
      final next = Set<String>.from(_savedStoreIds);
      if (wasSaved) {
        next.remove(storeId);
      } else {
        next.add(storeId);
      }
      _savedStoreIds = next;
    });
  }

  Future<List<AiRecommendation>> _requestAiRecommendations(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw Exception('검색 조건을 입력해주세요.');
    }

    final uri = Uri.parse('${AppConfig.flaskAiBaseUrl}/api/ai');
    final response = await http
        .post(
          uri,
          headers: _jsonHeadersWithAuth(),
          body: jsonEncode({'input': trimmedQuery, 'role': 'user'}),
        )
        .timeout(const Duration(seconds: 35));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('AI 서버 응답 형식이 올바르지 않습니다.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message'] as String? ?? 'AI 서버 요청에 실패했습니다.');
    }
    if (decoded['status'] != 'success') {
      throw Exception(decoded['message'] as String? ?? 'AI 추천에 실패했습니다.');
    }

    final data = decoded['data'];
    final rawRecommendations = data is Map<String, dynamic>
        ? data['recommendations']
        : null;
    if (rawRecommendations is! List || rawRecommendations.isEmpty) {
      throw Exception('추천 결과가 비어 있습니다.');
    }

    final recommendations = rawRecommendations
        .whereType<Map>()
        .map(
          (item) => AiRecommendation.fromJson(Map<String, dynamic>.from(item)),
        )
        .take(3)
        .toList(growable: false);

    if (recommendations.isEmpty) {
      throw Exception('추천 결과를 해석하지 못했습니다.');
    }

    await _saveRecommendationHistory(
      query: trimmedQuery,
      response: decoded,
      recommendations: recommendations,
    );

    final conditionsRaw = data is Map<String, dynamic> ? data['conditions'] : null;
    final conditions = conditionsRaw is Map<String, dynamic>
        ? AiConditions.fromJson(conditionsRaw)
        : null;

    if (mounted) {
      setState(() {
        _aiQuery = trimmedQuery;
        _aiRecommendations = recommendations;
        if (conditions != null) _aiConditions = conditions;
      });
    }
    return recommendations;
  }

  AppScreen _screenForRole(String role) {
    return role == AppRoles.owner
        ? AppScreen.ownerDashboard
        : AppScreen.location;
  }

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  Future<void> _handleAuthenticated() async {
    final session = AppConfig.isSupabaseConfigured
        ? Supabase.instance.client.auth.currentSession
        : null;
    if (session == null || !AppConfig.isSupabaseConfigured) {
      setState(() {
        _session = null;
        _accountRole = null;
        _screen = AppScreen.userType;
      });
      return;
    }

    try {
      final profile = await _loadProfile(session.user.id);
      if (!mounted) return;
      final role = profile?['role'] as String?;
      setState(() {
        _session = session;
        _accountRole = role;
        _screen = role == null ? AppScreen.userType : _screenForRole(role);
      });
      if (role == AppRoles.customer) {
        await _refreshCustomerData();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _session = session;
        _accountRole = null;
        _screen = AppScreen.userType;
      });
    }
  }

  Future<void> _updateRoleInDb(String role) async {
    final session = _session;
    if (!AppConfig.isSupabaseConfigured || session == null) return;
    final user = session.user;
    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.userMetadata?['display_name'],
      'role': role,
    });
  }

  Future<void> _selectAccountRole(String role) async {
    await _updateRoleInDb(role);

    if (!mounted) return;
    setState(() {
      _accountRole = role;
      _screen = _screenForRole(role);
    });
    if (role == AppRoles.customer) {
      await _refreshCustomerData();
    }
  }

  Future<void> _signOut() async {
    if (AppConfig.isSupabaseConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
    if (!mounted) return;
    setState(() {
      _session = null;
      _accountRole = null;
      _stores = const [];
      _savedStoreIds = const {};
      _selectedStore = null;
      _screen = AppScreen.auth;
    });
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
        onGoBack: _goBack,
        onOpenCustomerService: _openCustomerService,
        onOpenOwnerService: _openOwnerService,
        onAuthenticated: _handleAuthenticated,
        onRoleSelected: _selectAccountRole,
        onSignOut: _signOut,
        userEmail: _session?.user.email,
        accountRole: _accountRole,
        myLocation: _myLocation,
        onLocationChange: _setMyLocation,
        aiQuery: _aiQuery,
        onAiQueryChange: _setAiQuery,
        aiConditions: _aiConditions,
        aiRecommendations: _aiRecommendations,
        onAiRecommend: _requestAiRecommendations,
        stores: _stores,
        selectedStore: _selectedStore,
        savedStoreIds: _savedStoreIds,
        isLoadingStores: _isLoadingStores,
        storesError: _storesError,
        onRefreshStores: _refreshCustomerData,
        onStoreOpen: _openStoreDetail,
        onStoreIdOpen: _openStoreById,
        onStoreNameOpen: _openStoreByName,
        onToggleSavedStore: _toggleSavedStore,
      ),
    );
  }
}
