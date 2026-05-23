import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _isSupabaseConfigured =
    _supabaseUrl.length > 10 && _supabaseAnonKey.length > 10;
const _flaskAiBaseUrl = String.fromEnvironment(
  'FLASK_AI_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000',
);
const _kakaoRestApiKey = String.fromEnvironment('KAKAO_REST_API_KEY');
const _customerRole = 'customer';
const _ownerRole = 'owner';
const _storeSelectColumns =
    'id, name, category, address, description, image_url, rating, review_count, price_range, opening_hours, phone, tags, features';

class AiRecommendation {
  const AiRecommendation({
    required this.cardType,
    required this.storeName,
    required this.reason,
  });

  final String cardType;
  final String storeName;
  final String reason;

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      cardType: (json['card_type'] as String?)?.trim().isNotEmpty == true
          ? (json['card_type'] as String).trim()
          : '추천U',
      storeName: (json['store_name'] as String?)?.trim().isNotEmpty == true
          ? (json['store_name'] as String).trim()
          : '이름 없는 가게',
      reason: (json['reason'] as String?)?.trim().isNotEmpty == true
          ? (json['reason'] as String).trim()
          : '입력한 조건과 잘 맞는 가게예요.',
    );
  }

  Map<String, dynamic> toJson() {
    return {'card_type': cardType, 'store_name': storeName, 'reason': reason};
  }
}

class DongNeuStore {
  const DongNeuStore({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    this.description,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.priceRange,
    this.openingHours,
    this.phone,
    required this.tags,
    required this.features,
  });

  final String id;
  final String name;
  final String category;
  final String address;
  final String? description;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? priceRange;
  final String? openingHours;
  final String? phone;
  final List<String> tags;
  final List<String> features;

  factory DongNeuStore.fromJson(Map<String, dynamic> json) {
    return DongNeuStore(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '이름 없는 가게',
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : '카테고리 없음',
      address: (json['address'] as String?)?.trim().isNotEmpty == true
          ? (json['address'] as String).trim()
          : '주소 정보 없음',
      description: (json['description'] as String?)?.trim(),
      imageUrl: (json['image_url'] as String?)?.trim(),
      rating: double.tryParse(json['rating']?.toString() ?? '') ?? 0,
      reviewCount: int.tryParse(json['review_count']?.toString() ?? '') ?? 0,
      priceRange: (json['price_range'] as String?)?.trim(),
      openingHours: (json['opening_hours'] as String?)?.trim(),
      phone: (json['phone'] as String?)?.trim(),
      tags: _stringListFromDynamic(json['tags']),
      features: _stringListFromDynamic(json['features']),
    );
  }

  String get ratingLabel => rating == 0 ? '-' : rating.toStringAsFixed(1);
}

class StoreMenuItem {
  const StoreMenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.isRepresentative,
  });

  final String id;
  final String name;
  final String? description;
  final int price;
  final bool isRepresentative;

  factory StoreMenuItem.fromJson(Map<String, dynamic> json) {
    return StoreMenuItem(
      id: json['id']?.toString() ?? '',
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : '이름 없는 메뉴',
      description: (json['description'] as String?)?.trim(),
      price: int.tryParse(json['price']?.toString() ?? '') ?? 0,
      isRepresentative: json['is_representative'] == true,
    );
  }
}

List<String> _stringListFromDynamic(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

String _formatWon(int price) {
  final text = price.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '$buffer원';
}

class AddressSearchResult {
  const AddressSearchResult({
    required this.address,
    this.roadAddress,
    this.lat,
    this.lng,
  });

  final String address;
  final String? roadAddress;
  final double? lat;
  final double? lng;

  String get displayAddress =>
      roadAddress?.isNotEmpty == true ? roadAddress! : address;

  factory AddressSearchResult.fromKakao(Map<String, dynamic> json) {
    final addressData = json['address'];
    final roadAddressData = json['road_address'];
    final addressName = addressData is Map
        ? addressData['address_name'] as String?
        : null;
    final roadAddressName = roadAddressData is Map
        ? roadAddressData['address_name'] as String?
        : null;
    return AddressSearchResult(
      address: addressName ?? roadAddressName ?? '주소 정보 없음',
      roadAddress: roadAddressName,
      lat: double.tryParse(json['y']?.toString() ?? ''),
      lng: double.tryParse(json['x']?.toString() ?? ''),
    );
  }
}

class _MenuDraft {
  _MenuDraft();

  final nameController = TextEditingController();
  final priceController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NaverMapSdk.instance.initialize(clientId: 'j13ue7xko4');
  }
  if (_isSupabaseConfigured) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
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
  List<AiRecommendation> _aiRecommendations = const [];
  List<DongNeuStore> _stores = const [];
  Set<String> _savedStoreIds = const {};
  DongNeuStore? _selectedStore;
  bool _isLoadingStores = false;
  String? _storesError;
  Session? _session;
  String? _accountRole;

  void _open(AppScreen screen) {
    setState(() => _screen = screen);
  }

  void _setMyLocation(String loc) {
    setState(() => _myLocation = loc);
  }

  void _setAiQuery(String query) {
    setState(() => _aiQuery = query);
  }

  List<String> _keywordsFromQuery(String query) {
    const candidates = [
      '혼밥',
      '데이트',
      '가성비',
      '비 오는 날',
      '비오는날',
      '모임',
      '조용한',
      '든든한',
      '카페',
      '한식',
      '분식',
      '국수',
    ];
    return candidates.where((keyword) => query.contains(keyword)).toList();
  }

  Future<void> _saveRecommendationHistory({
    required String query,
    required Map<String, dynamic> response,
    required List<AiRecommendation> recommendations,
  }) async {
    if (!_isSupabaseConfigured) return;
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
    if (!_isSupabaseConfigured ||
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
            .select(_storeSelectColumns)
            .eq('is_active', true)
            .order('rating', ascending: false)
            .limit(12),
        Supabase.instance.client.from('saved_stores').select('store_id'),
      ]);

      if (!mounted) return;
      setState(() {
        _stores = _parseStoreRows(responses[0]);
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
    if (!_isSupabaseConfigured) return null;
    final response = await Supabase.instance.client
        .from('stores')
        .select(_storeSelectColumns)
        .eq('id', storeId)
        .maybeSingle();
    if (response == null) return null;
    return DongNeuStore.fromJson(response);
  }

  Future<DongNeuStore?> _fetchStoreByName(String storeName) async {
    if (!_isSupabaseConfigured) return null;
    final response = await Supabase.instance.client
        .from('stores')
        .select(_storeSelectColumns)
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
    if (!_isSupabaseConfigured) {
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

    final uri = Uri.parse('$_flaskAiBaseUrl/api/ai');
    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
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

    if (mounted) {
      setState(() {
        _aiQuery = trimmedQuery;
        _aiRecommendations = recommendations;
      });
    }
    return recommendations;
  }

  AppScreen _screenForRole(String role) {
    return role == _ownerRole ? AppScreen.ownerDashboard : AppScreen.location;
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
    final session = _isSupabaseConfigured
        ? Supabase.instance.client.auth.currentSession
        : null;
    if (session == null || !_isSupabaseConfigured) {
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
      if (role == _customerRole) {
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

  Future<void> _selectAccountRole(String role) async {
    final session = _session;
    if (!_isSupabaseConfigured || session == null) return;

    final user = session.user;
    await Supabase.instance.client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': user.userMetadata?['display_name'],
      'role': role,
    });

    if (!mounted) return;
    setState(() {
      _accountRole = role;
      _screen = _screenForRole(role);
    });
    if (role == _customerRole) {
      await _refreshCustomerData();
    }
  }

  Future<void> _signOut() async {
    if (_isSupabaseConfigured) {
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
        onAuthenticated: _handleAuthenticated,
        onRoleSelected: _selectAccountRole,
        onSignOut: _signOut,
        userEmail: _session?.user.email,
        accountRole: _accountRole,
        myLocation: _myLocation,
        onLocationChange: _setMyLocation,
        aiQuery: _aiQuery,
        onAiQueryChange: _setAiQuery,
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
      displaySmall: const TextStyle(
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: _primaryText,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: _primaryText,
      ),
      headlineSmall: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: _primaryText,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: _primaryText,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: _primaryText,
      ),
      titleSmall: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: _primaryText,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: _primaryText,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: _primaryText,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _secondaryText,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      labelSmall: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    ),
  );
}

class _AppRouter extends StatelessWidget {
  const _AppRouter({
    required this.screen,
    required this.onOpen,
    required this.onAuthenticated,
    required this.onRoleSelected,
    required this.onSignOut,
    required this.userEmail,
    required this.accountRole,
    required this.myLocation,
    required this.onLocationChange,
    required this.aiQuery,
    required this.onAiQueryChange,
    required this.aiRecommendations,
    required this.onAiRecommend,
    required this.stores,
    required this.selectedStore,
    required this.savedStoreIds,
    required this.isLoadingStores,
    required this.storesError,
    required this.onRefreshStores,
    required this.onStoreOpen,
    required this.onStoreIdOpen,
    required this.onStoreNameOpen,
    required this.onToggleSavedStore,
  });

  final AppScreen screen;
  final ValueChanged<AppScreen> onOpen;
  final Future<void> Function() onAuthenticated;
  final Future<void> Function(String role) onRoleSelected;
  final Future<void> Function() onSignOut;
  final String? userEmail;
  final String? accountRole;
  final String myLocation;
  final ValueChanged<String> onLocationChange;
  final String aiQuery;
  final ValueChanged<String> onAiQueryChange;
  final List<AiRecommendation> aiRecommendations;
  final Future<List<AiRecommendation>> Function(String query) onAiRecommend;
  final List<DongNeuStore> stores;
  final DongNeuStore? selectedStore;
  final Set<String> savedStoreIds;
  final bool isLoadingStores;
  final String? storesError;
  final Future<void> Function() onRefreshStores;
  final ValueChanged<DongNeuStore> onStoreOpen;
  final Future<bool> Function(String storeId) onStoreIdOpen;
  final Future<bool> Function(String storeName) onStoreNameOpen;
  final Future<void> Function(String storeId) onToggleSavedStore;

  @override
  Widget build(BuildContext context) {
    return switch (screen) {
      AppScreen.auth => AuthOnboardingScreen(
        onOpen: onOpen,
        onAuthenticated: onAuthenticated,
      ),
      AppScreen.userType => UserTypeSelectionScreen(
        onOpen: onOpen,
        onRoleSelected: onRoleSelected,
      ),
      AppScreen.location => LocationSetupScreen(
        onOpen: onOpen,
        onLocationChange: onLocationChange,
      ),
      AppScreen.home => HomeScreen(
        onOpen: onOpen,
        myLocation: myLocation,
        stores: stores,
        isLoadingStores: isLoadingStores,
        storesError: storesError,
        onRefreshStores: onRefreshStores,
        onStoreOpen: onStoreOpen,
      ),
      AppScreen.aiCondition => AiConditionConfirmationScreen(
        onOpen: onOpen,
        query: aiQuery,
      ),
      AppScreen.aiChat => AiChatScreen(
        onOpen: onOpen,
        onQueryChange: onAiQueryChange,
        onRecommend: onAiRecommend,
      ),
      AppScreen.recommendations => Top3RecommendationsScreen(
        onOpen: onOpen,
        query: aiQuery,
        recommendations: aiRecommendations,
        stores: stores,
        onStoreNameOpen: onStoreNameOpen,
      ),
      AppScreen.filters => ManualSearchFiltersScreen(
        onOpen: onOpen,
        myLocation: myLocation,
      ),
      AppScreen.storeDetail => StoreDetailScreen(
        onOpen: onOpen,
        store: selectedStore,
        isSaved:
            selectedStore != null && savedStoreIds.contains(selectedStore!.id),
        onToggleSaved: onToggleSavedStore,
      ),
      AppScreen.saved => SavedHistoryScreen(
        onOpen: onOpen,
        onStoreIdOpen: onStoreIdOpen,
      ),
      AppScreen.ownerRegistration => OwnerStoreRegistrationScreen(
        onOpen: onOpen,
      ),
      AppScreen.promotion => AiPromotionHelperScreen(onOpen: onOpen),
      AppScreen.ownerDashboard => OwnerDashboardScreen(onOpen: onOpen),
      AppScreen.ownerStoreManage => OwnerStoreManageScreen(onOpen: onOpen),
      AppScreen.ownerMyPage => OwnerMyPageScreen(
        onOpen: onOpen,
        onSignOut: onSignOut,
        userEmail: userEmail,
      ),
      AppScreen.mypage => MyPageScreen(
        onOpen: onOpen,
        onSignOut: onSignOut,
        userEmail: userEmail,
        accountRole: accountRole,
      ),
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
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 16,
                color: _isSelected ? chipColor : _secondaryText,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _isSelected ? chipColor : _primaryText,
              ),
            ),
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
                current == AppScreen.filters || current == AppScreen.aiChat,
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

    if (!_isSupabaseConfigured) {
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
              onTap: () => _saveRole(_customerRole),
            ),
            const SizedBox(height: 16),
            _ModeSelectionCard(
              icon: Icons.add_business_rounded,
              title: '사장님으로 시작하기',
              subtitle: '가게 등록과 AI 홍보 기능을 쓰는 사장님 계정',
              button: '사장님 계정 선택',
              outline: true,
              onTap: () => _saveRole(_ownerRole),
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
                  children:
                      ['대전 유성구 궁동', '대전 유성구 어은동', '대전 유성구 봉명동', '대전 유성구 죽동']
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
                        content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpen,
    required this.myLocation,
    required this.stores,
    required this.isLoadingStores,
    required this.storesError,
    required this.onRefreshStores,
    required this.onStoreOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final String myLocation;
  final List<DongNeuStore> stores;
  final bool isLoadingStores;
  final String? storesError;
  final Future<void> Function() onRefreshStores;
  final ValueChanged<DongNeuStore> onStoreOpen;
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
                          Text.rich(
                            TextSpan(
                              text: '안녕하세요, ',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: _secondaryText,
                              ),
                              children: [
                                TextSpan(
                                  text: '동네 주민님!',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: _primaryText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => onOpen(AppScreen.location),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: _primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  myLocation,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _secondaryText,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => onOpen(AppScreen.mypage),
                        icon: const Icon(Icons.person_outline_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _AiHeroCard(onTap: () => onOpen(AppScreen.aiChat)),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '이런 상황인가U?',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _SituationChip(
                              icon: Icons.rice_bowl_rounded,
                              label: '혼밥',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.favorite_rounded,
                              label: '데이트',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.savings_rounded,
                              label: '가성비',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.umbrella_rounded,
                              label: '비 오는 날',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                            _SituationChip(
                              icon: Icons.groups_rounded,
                              label: '모임',
                              onTap: () => onOpen(AppScreen.aiChat),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _SurfaceCard(
                    onTap: () => onOpen(AppScreen.filters),
                    child: Row(
                      children: [
                        const _IconTile(
                          icon: Icons.tune_rounded,
                          background: Color(0x1AFF7E33),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '직접 찾아보기',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '필터를 설정해서 취향대로 검색해요',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: _secondaryText,
                                ),
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
                ),
                _LocalPicksSection(
                  onOpen: onOpen,
                  stores: stores,
                  isLoading: isLoadingStores,
                  error: storesError,
                  onRefresh: onRefreshStores,
                  onStoreOpen: onStoreOpen,
                ),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _secondary],
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'AI 맞춤 추천',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 5),
                    Text(
                      '상황, 예산, 취향만 말해주세요',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.80),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: _primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '예: 충남대 근처 가성비 혼밥 추천해줘',
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _accentText,
                              ),
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
      ),
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9999),
        child: _Pill(icon: icon, label: label),
      ),
    );
  }
}

class _LocalPicksSection extends StatelessWidget {
  const _LocalPicksSection({
    required this.onOpen,
    required this.stores,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.onStoreOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final List<DongNeuStore> stores;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<DongNeuStore> onStoreOpen;

  Color _colorForIndex(int index) {
    return switch (index % 3) {
      0 => _info,
      1 => _success,
      _ => _warning,
    };
  }

  String _tagForStore(DongNeuStore store, int index) {
    if (store.features.contains('착한가격업소') || store.tags.contains('가성비')) {
      return '아껴U';
    }
    if (store.features.contains('새로생긴가게') || store.tags.contains('새로운')) {
      return '새로워U';
    }
    if (index == 0) return '가까워U';
    return '동네픽';
  }

  IconData _iconForCategory(String category) {
    if (category.contains('카페')) return Icons.local_cafe_rounded;
    if (category.contains('분식')) return Icons.local_dining_rounded;
    if (category.contains('국수') || category.contains('면')) {
      return Icons.ramen_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('오늘의 동네픽', style: theme.textTheme.titleMedium),
                _PrimaryButton(
                  label: isLoading ? '불러오는 중' : '새로고침',
                  compact: true,
                  ghost: true,
                  onPressed: onRefresh,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator(color: _primary)),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _EmptyStateCard(
                icon: Icons.cloud_off_rounded,
                title: '가게 목록을 불러오지 못했어요',
                message: error!,
                actionLabel: '다시 불러오기',
                onAction: onRefresh,
              ),
            )
          else if (stores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _EmptyStateCard(
                icon: Icons.storefront_rounded,
                title: '등록된 가게가 없어요',
                message: 'Supabase stores에 active 가게가 있으면 여기에 표시돼요.',
                actionLabel: '새로고침',
                onAction: onRefresh,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: stores.take(8).toList().asMap().entries.map((entry) {
                  final store = entry.value;
                  final tagColor = _colorForIndex(entry.key);
                  return _LocalPickCard(
                    tag: _tagForStore(store, entry.key),
                    tagColor: tagColor,
                    tagBg: tagColor.withOpacity(0.10),
                    name: store.name,
                    rating: store.ratingLabel,
                    icon: _iconForCategory(store.category),
                    onTap: () => onStoreOpen(store),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalPickCard extends StatelessWidget {
  const _LocalPickCard({
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.name,
    required this.rating,
    required this.icon,
    required this.onTap,
  });
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
      width: 148,
      margin: const EdgeInsets.only(right: 16),
      child: _SurfaceCard(
        padding: EdgeInsets.zero,
        radius: 24,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 104,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tagColor.withOpacity(0.22), _surfaceVariant],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Icon(icon, color: tagColor, size: 42),
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
                      color: tagBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tagColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: _secondaryText,
                        ),
                      ),
                    ],
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

class AiConditionConfirmationScreen extends StatelessWidget {
  const AiConditionConfirmationScreen({
    super.key,
    required this.onOpen,
    this.query = "충남대 근처에서 혼자 먹기 좋고 만 원 이하로 든든한 저녁 추천해줘",
  });
  final ValueChanged<AppScreen> onOpen;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScrollScreen(
      padding: EdgeInsets.zero,
      bottom: _BottomActionBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrimaryButton(
              label: '이대로 추천 받기',
              onPressed: () => onOpen(AppScreen.recommendations),
            ),
            const SizedBox(height: 10),
            _PrimaryButton(
              label: '조건 수정하기',
              ghost: true,
              onPressed: () => onOpen(AppScreen.filters),
            ),
          ],
        ),
      ),
      children: [
        _TopBar(
          title: '',
          onBack: () => onOpen(AppScreen.home),
          trailing: _IconButton(
            icon: Icons.close_rounded,
            onPressed: () => onOpen(AppScreen.home),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '맞춤 추천을 위해\n조건을 확인해볼까U?',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'AI가 분석한 오늘의 방문 조건이에요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: _secondaryText,
                ),
              ),
              const SizedBox(height: 20),
              _SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            '“$query”',
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: _alternate),
                    const SizedBox(height: 14),
                    const _ConditionRow(
                      icon: Icons.location_on_rounded,
                      label: '위치',
                      value: '충남대 근처',
                    ),
                    const _ConditionRow(
                      icon: Icons.payments_rounded,
                      label: '예산',
                      value: '만 원 이하',
                    ),
                    const _ConditionRow(
                      icon: Icons.schedule_rounded,
                      label: '시간대',
                      value: '저녁',
                    ),
                    const _ConditionRow(
                      icon: Icons.person_rounded,
                      label: '상황',
                      value: '혼밥',
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('추출된 키워드', style: theme.textTheme.titleSmall),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Pill(label: '가성비', selected: true),
                        _Pill(label: '조용한', selected: false),
                        _Pill(label: '로컬맛집', selected: false),
                        _Pill(label: '든든한', selected: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SurfaceCard(
                color: _primary.withOpacity(0.08),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: _primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '이 조건으로 맛집 3곳을 찾아드릴게요!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  const _ConditionRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: _secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class Top3RecommendationsScreen extends StatelessWidget {
  const Top3RecommendationsScreen({
    super.key,
    required this.onOpen,
    required this.query,
    required this.recommendations,
    required this.stores,
    required this.onStoreNameOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final String query;
  final List<AiRecommendation> recommendations;
  final List<DongNeuStore> stores;
  final Future<bool> Function(String storeName) onStoreNameOpen;

  DongNeuStore? _matchedStore(String storeName) {
    final normalizedName = storeName.replaceAll(RegExp(r'\s+'), '');
    for (final store in stores) {
      if (store.name.replaceAll(RegExp(r'\s+'), '') == normalizedName) {
        return store;
      }
    }
    return null;
  }

  Color _colorForTag(String tag) {
    if (tag.contains('가까')) return _info;
    if (tag.contains('아껴') || tag.contains('가격')) return _success;
    if (tag.contains('새로')) return _warning;
    return _primary;
  }

  IconData _iconForTag(String tag) {
    if (tag.contains('가까')) return Icons.near_me_rounded;
    if (tag.contains('아껴') || tag.contains('가격')) return Icons.savings_rounded;
    if (tag.contains('새로')) return Icons.auto_awesome_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '동네U의 추천',
            subtitle: '오늘의 완벽한 3곳을 찾았어요!',
            onBack: () => onOpen(AppScreen.aiCondition),
            trailing: _IconButton(
              icon: Icons.refresh_rounded,
              onPressed: () => onOpen(AppScreen.aiChat),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                if (recommendations.isEmpty) ...[
                  _SurfaceCard(
                    color: _surfaceVariant.withOpacity(0.55),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: _primary,
                          size: 34,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '아직 추천 결과가 없어요',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AI 동네 검색에서 원하는 조건을 먼저 입력해주세요.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        _PrimaryButton(
                          label: 'AI 검색하러 가기',
                          compact: true,
                          onPressed: () => onOpen(AppScreen.aiChat),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _SurfaceCard(
                    color: _primary.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: _primary),
                        const SizedBox(width: 12),
                        Expanded(child: Text('“$query” 조건에 맞춰 찾은 추천입니다.')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...recommendations.asMap().entries.expand((entry) {
                    final item = entry.value;
                    final color = _colorForTag(item.cardType);
                    final matchedStore = _matchedStore(item.storeName);
                    return [
                      _RecommendationCard(
                        rank: entry.key + 1,
                        tag: item.cardType,
                        name: item.storeName,
                        rating: matchedStore?.ratingLabel ?? '-',
                        price: matchedStore?.priceRange ?? 'AI 추천',
                        category: matchedStore?.category ?? '동네 맛집',
                        distance: matchedStore == null ? '매칭 대기' : '상세 가능',
                        reason: item.reason,
                        color: color,
                        icon: _iconForTag(item.cardType),
                        onTap: () async {
                          final opened = await onStoreNameOpen(item.storeName);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '"${item.storeName}"을 stores에서 찾지 못했어요.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                    ];
                  }),
                ],
                const SizedBox(height: 24),
                Text(
                  '추천 결과가 마음에 드셨나요?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryButton(
                        label: '다시 추천',
                        outline: true,
                        onPressed: () => onOpen(AppScreen.aiCondition),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PrimaryButton(
                        label: '조건 수정',
                        onPressed: () => onOpen(AppScreen.filters),
                      ),
                    ),
                  ],
                ),
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
  const _RecommendationCard({
    required this.rank,
    required this.tag,
    required this.name,
    required this.rating,
    required this.price,
    required this.category,
    required this.distance,
    required this.reason,
    required this.color,
    required this.icon,
    required this.onTap,
  });
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _IconTile(
                    icon: icon,
                    color: color,
                    background: color.withOpacity(0.12),
                    size: 58,
                  ),
                  Positioned(
                    left: -7,
                    top: -7,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _SmallTag(label: tag, color: color),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          color: _warning,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(rating, style: theme.textTheme.labelMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MetaText(price),
                        _MetaText(category),
                        _MetaText(distance),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            reason,
            style: theme.textTheme.bodyMedium?.copyWith(color: _secondaryText),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: _secondaryText),
    );
  }
}

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

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({
    super.key,
    required this.onOpen,
    required this.store,
    required this.isSaved,
    required this.onToggleSaved,
  });
  final ValueChanged<AppScreen> onOpen;
  final DongNeuStore? store;
  final bool isSaved;
  final Future<void> Function(String storeId) onToggleSaved;

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isLoadingMenus = false;
  bool _isTogglingSaved = false;
  List<StoreMenuItem> _menus = const [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  @override
  void didUpdateWidget(covariant StoreDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store?.id != widget.store?.id) {
      _loadMenus();
    }
  }

  IconData _iconForCategory(String category) {
    if (category.contains('카페')) return Icons.local_cafe_rounded;
    if (category.contains('분식')) return Icons.local_dining_rounded;
    if (category.contains('국수') || category.contains('면')) {
      return Icons.ramen_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  Future<void> _loadMenus() async {
    final store = widget.store;
    if (store == null || !_isSupabaseConfigured) {
      setState(() {
        _menus = const [];
        _isLoadingMenus = false;
      });
      return;
    }

    setState(() => _isLoadingMenus = true);
    try {
      final response = await Supabase.instance.client
          .from('menu_items')
          .select('id, name, description, price, is_representative')
          .eq('store_id', store.id)
          .order('is_representative', ascending: false)
          .order('price');
      if (!mounted) return;
      setState(() {
        _menus = (response as List)
            .whereType<Map>()
            .map(
              (item) => StoreMenuItem.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false);
        _isLoadingMenus = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoadingMenus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('메뉴를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _toggleSaved() async {
    final store = widget.store;
    if (store == null || _isTogglingSaved) return;

    setState(() => _isTogglingSaved = true);
    try {
      await widget.onToggleSaved(store.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isSaved ? '저장을 해제했어요.' : '가게를 저장했어요.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isTogglingSaved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = widget.store;
    if (store == null) {
      return _PhoneFrame(
        child: Column(
          children: [
            _TopBar(
              title: '가게 상세',
              onBack: () => widget.onOpen(AppScreen.home),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _EmptyStateCard(
                    icon: Icons.storefront_rounded,
                    title: '선택된 가게가 없어요',
                    message: '홈이나 저장 목록에서 가게를 선택하면 상세 정보를 볼 수 있어요.',
                    actionLabel: '홈으로 가기',
                    onAction: () => widget.onOpen(AppScreen.home),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final visibleTags = [
      store.category,
      if (store.priceRange?.isNotEmpty == true) store.priceRange!,
      ...store.tags.take(2),
    ];

    return _PhoneFrame(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 116),
            children: [
              Stack(
                children: [
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _tertiary.withOpacity(0.95),
                          _primary.withOpacity(0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _iconForCategory(store.category),
                        color: Colors.white,
                        size: 92,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _CircleAction(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => widget.onOpen(AppScreen.home),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _CircleAction(
                          icon: Icons.share_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _CircleAction(
                          icon: widget.isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          onTap: _toggleSaved,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 22,
                    child: _SmallTag(
                      label: store.features.contains('착한가격업소') ? '아껴U' : '동네U',
                      color: store.features.contains('착한가격업소')
                          ? _success
                          : _info,
                    ),
                  ),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                store.name,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: _warning,
                                  size: 18,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  store.ratingLabel,
                                  style: theme.textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: visibleTags
                              .map((tag) => _Pill(label: tag))
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 18),
                        const Divider(color: _alternate),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: _primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '동네U 추천 이유',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.description?.isNotEmpty == true
                              ? store.description!
                              : 'Supabase stores에 등록된 가게 정보입니다.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('대표 메뉴', style: theme.textTheme.titleMedium),
                        Text(
                          '${_menus.length}개',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingMenus)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (_menus.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.restaurant_menu_rounded,
                        title: '등록된 메뉴가 없어요',
                        message: 'menu_items에 메뉴가 추가되면 여기에 표시돼요.',
                        actionLabel: '다시 불러오기',
                        onAction: _loadMenus,
                      )
                    else
                      ..._menus.expand((menu) {
                        return [
                          _MenuItemCard(
                            icon: menu.isRepresentative
                                ? Icons.restaurant_menu_rounded
                                : Icons.local_dining_rounded,
                            name: menu.name,
                            desc: menu.description?.isNotEmpty == true
                                ? menu.description!
                                : menu.isRepresentative
                                ? '대표 메뉴'
                                : '일반 메뉴',
                            price: _formatWon(menu.price),
                          ),
                          const SizedBox(height: 10),
                        ];
                      }),
                    const SizedBox(height: 20),
                    _SurfaceCard(
                      color: _surfaceVariant.withOpacity(0.50),
                      child: Column(
                        children: [
                          _StoreInfoRow(
                            icon: Icons.schedule_rounded,
                            text: store.openingHours?.isNotEmpty == true
                                ? store.openingHours!
                                : '운영시간 정보 없음',
                          ),
                          _StoreInfoRow(
                            icon: Icons.payments_rounded,
                            text: store.priceRange?.isNotEmpty == true
                                ? store.priceRange!
                                : '가격 정보 없음',
                          ),
                          _StoreInfoRow(
                            icon: Icons.info_outlined,
                            text: store.address,
                            bottom: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _BottomActionBar(
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _isTogglingSaved ? null : _toggleSaved,
                          icon: Icon(
                            widget.isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                          ),
                        ),
                        Text(
                          widget.isSaved ? '저장됨' : '저장',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrimaryButton(
                      label: '길찾기',
                      icon: Icons.near_me_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: _primaryText, size: 22),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.icon,
    required this.name,
    required this.desc,
    required this.price,
  });
  final IconData icon;
  final String name;
  final String desc;
  final String price;
  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(desc, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(price, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _StoreInfoRow extends StatelessWidget {
  const _StoreInfoRow({
    required this.icon,
    required this.text,
    this.bottom = true,
  });
  final IconData icon;
  final String text;
  final bool bottom;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom ? 16 : 0),
      child: Row(
        children: [
          Icon(icon, color: _secondaryText, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class SavedHistoryScreen extends StatefulWidget {
  const SavedHistoryScreen({
    super.key,
    required this.onOpen,
    required this.onStoreIdOpen,
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<bool> Function(String storeId) onStoreIdOpen;

  @override
  State<SavedHistoryScreen> createState() => _SavedHistoryScreenState();
}

class _SavedHistoryScreenState extends State<SavedHistoryScreen> {
  bool _showSavedStores = true;
  bool _isLoading = true;
  List<Map<String, dynamic>> _savedStores = const [];
  List<Map<String, dynamic>> _recommendationHistory = const [];

  @override
  void initState() {
    super.initState();
    _loadSavedAndHistory();
  }

  String _formatDate(String? value) {
    if (value == null) return '날짜 없음';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  int _recommendationCount(Map<String, dynamic> item) {
    final aiResponse = item['ai_response'];
    if (aiResponse is Map) {
      final recommendations = aiResponse['recommendations'];
      if (recommendations is List) return recommendations.length;
      final flaskResponse = aiResponse['flask_response'];
      if (flaskResponse is Map) {
        final data = flaskResponse['data'];
        if (data is Map && data['recommendations'] is List) {
          return (data['recommendations'] as List).length;
        }
      }
    }
    return 0;
  }

  Future<void> _loadSavedAndHistory() async {
    if (!_isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('saved_stores')
            .select(
              'id, created_at, stores(id, name, category, rating, price_range)',
            )
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('recommendation_history')
            .select('id, query, created_at, ai_response')
            .order('created_at', ascending: false)
            .limit(100),
      ]);

      if (!mounted) return;
      setState(() {
        _savedStores = (responses[0] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _recommendationHistory = (responses[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장/추천 기록을 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('저장', style: theme.textTheme.headlineSmall),
                          const Spacer(),
                          IconButton(
                            onPressed: _loadSavedAndHistory,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _Pill(
                              label: '저장한 가게',
                              selected: _showSavedStores,
                              onTap: () =>
                                  setState(() => _showSavedStores = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Pill(
                              label: '추천 기록',
                              selected: !_showSavedStores,
                              onTap: () =>
                                  setState(() => _showSavedStores = false),
                            ),
                          ),
                        ],
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
                if (_isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  ),
                ] else if (_showSavedStores) ...[
                  Row(
                    children: [
                      Text(
                        '총 ${_savedStores.length}곳',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.sort_rounded,
                        color: _secondaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '최신순',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_savedStores.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.bookmark_border_rounded,
                      title: '저장한 가게가 없어요',
                      message: '마음에 드는 가게를 저장하면 여기에 모아볼 수 있어요.',
                      actionLabel: '추천 받기',
                      onAction: () => widget.onOpen(AppScreen.aiChat),
                    )
                  else
                    ..._savedStores.map((item) {
                      final store = item['stores'];
                      final storeMap = store is Map
                          ? Map<String, dynamic>.from(store)
                          : <String, dynamic>{};
                      return _SavedStoreCard(
                        icon: Icons.restaurant_rounded,
                        name: storeMap['name'] as String? ?? '이름 없는 가게',
                        rating: (storeMap['rating'] ?? '-').toString(),
                        category: storeMap['category'] as String? ?? '카테고리 없음',
                        distance: _formatDate(item['created_at'] as String?),
                        price: storeMap['price_range'] as String? ?? '가격 정보 없음',
                        onTap: () async {
                          final storeId = storeMap['id']?.toString();
                          if (storeId == null || storeId.isEmpty) return;
                          final opened = await widget.onStoreIdOpen(storeId);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('가게 상세를 불러오지 못했어요.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    }),
                ] else ...[
                  Text('최근 추천 기록', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_recommendationHistory.isEmpty)
                    _EmptyStateCard(
                      icon: Icons.history_rounded,
                      title: '추천 기록이 없어요',
                      message: 'AI 맞춤 검색을 사용하면 추천 기록이 저장돼요.',
                      actionLabel: '추천 받기',
                      onAction: () => widget.onOpen(AppScreen.aiChat),
                    )
                  else
                    ..._recommendationHistory.map((item) {
                      final count = _recommendationCount(item);
                      return _HistoryItem(
                        query: item['query'] as String? ?? '추천 요청',
                        date: _formatDate(item['created_at'] as String?),
                        result: count == 0 ? '추천 결과 저장됨' : '$count곳 추천',
                      );
                    }),
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
  const _SavedStoreCard({
    required this.icon,
    required this.name,
    required this.rating,
    required this.category,
    required this.distance,
    required this.price,
    required this.onTap,
  });
  final IconData icon;
  final String name;
  final String rating;
  final String category;
  final String distance;
  final String price;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: _warning, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        rating,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(' · $category · $distance'),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(price, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _secondaryText),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SurfaceCard(
      color: _surfaceVariant.withOpacity(0.50),
      child: Column(
        children: [
          Icon(icon, color: _primary, size: 30),
          const SizedBox(height: 10),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: actionLabel,
            compact: true,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.query,
    required this.date,
    required this.result,
  });
  final String query;
  final String date;
  final String result;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(icon: Icons.history_rounded),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(query, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '$date · $result',
                    style: Theme.of(context).textTheme.bodySmall,
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
    if (_kakaoRestApiKey.isEmpty) {
      throw Exception('KAKAO_REST_API_KEY가 설정되지 않았어요.');
    }

    final uri = Uri.https('dapi.kakao.com', '/v2/local/search/address.json', {
      'query': query,
      'size': '10',
    });
    final response = await http
        .get(uri, headers: {'Authorization': 'KakaoAK $_kakaoRestApiKey'})
        .timeout(const Duration(seconds: 12));

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('주소 검색 API 요청에 실패했어요.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('주소 검색 응답 형식이 올바르지 않아요.');
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
    if (!_isSupabaseConfigured) {
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

class AiPromotionHelperScreen extends StatefulWidget {
  const AiPromotionHelperScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<AiPromotionHelperScreen> createState() =>
      _AiPromotionHelperScreenState();
}

class _AiPromotionHelperScreenState extends State<AiPromotionHelperScreen> {
  final _eventController = TextEditingController();
  final _keywordsController = TextEditingController();
  List<DongNeuStore> _ownerStores = const [];
  List<Map<String, dynamic>> _promotionHistory = const [];
  String? _selectedStoreId;
  String _selectedTone = '친절한';
  String? _generatedCopy;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadOwnerData();
  }

  @override
  void dispose() {
    _eventController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  String _formatDate(String? value) {
    if (value == null) return '날짜 없음';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.month}/${parsed.day} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  List<String> _keywordList() {
    return _keywordsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  DongNeuStore? get _selectedStore {
    for (final store in _ownerStores) {
      if (store.id == _selectedStoreId) return store;
    }
    return _ownerStores.isEmpty ? null : _ownerStores.first;
  }

  Future<void> _loadOwnerData() async {
    if (!_isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('stores')
            .select(_storeSelectColumns)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('promotion_history')
            .select(
              'id, store_id, promotion_type, event_text, tone, generated_copy, created_at',
            )
            .order('created_at', ascending: false)
            .limit(10),
      ]);
      if (!mounted) return;
      final stores = (responses[0] as List)
          .whereType<Map>()
          .map((item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)))
          .where((store) => store.id.isNotEmpty)
          .toList(growable: false);
      setState(() {
        _ownerStores = stores;
        _selectedStoreId =
            _selectedStoreId ?? (stores.isEmpty ? null : stores.first.id);
        _promotionHistory = (responses[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('홍보 데이터를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _generatePromotionCopy() async {
    if (_isGenerating) return;
    final session = Supabase.instance.client.auth.currentSession;
    final store = _selectedStore;
    final eventText = _eventController.text.trim();
    final keywords = _keywordList();

    if (!_isSupabaseConfigured || session == null) {
      _showMessage('로그인 후 사용할 수 있어요.');
      return;
    }
    if (store == null) {
      _showMessage('먼저 사장님 계정으로 가게를 등록해주세요.');
      return;
    }
    if (eventText.isEmpty) {
      _showMessage('홍보할 메뉴나 이벤트를 입력해주세요.');
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final input = [
        '가게명: ${store.name}',
        '업종: ${store.category}',
        '홍보 내용: $eventText',
        if (keywords.isNotEmpty) '키워드: ${keywords.join(', ')}',
        '문구 분위기: $_selectedTone',
      ].join('\n');

      final response = await http
          .post(
            Uri.parse('$_flaskAiBaseUrl/api/ai'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'input': input, 'role': 'owner'}),
          )
          .timeout(const Duration(seconds: 35));
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw Exception('AI 서버 응답 형식이 올바르지 않아요.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(decoded['message'] as String? ?? 'AI 요청에 실패했어요.');
      }
      if (decoded['status'] != 'success') {
        throw Exception(decoded['message'] as String? ?? '홍보 문구 생성에 실패했어요.');
      }

      final data = decoded['data'];
      final marketing = data is Map<String, dynamic> ? data['marketing'] : null;
      if (marketing is! Map) {
        throw Exception('홍보 문구 응답을 해석하지 못했어요.');
      }
      final postText = (marketing['post_text'] as String?)?.trim();
      final hashtags = marketing['hashtags'] is List
          ? (marketing['hashtags'] as List)
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[];
      if (postText == null || postText.isEmpty) {
        throw Exception('생성된 홍보 문구가 비어 있어요.');
      }

      final generatedCopy = [
        postText,
        if (hashtags.isNotEmpty) '',
        if (hashtags.isNotEmpty) hashtags.join(' '),
      ].join('\n');

      await Supabase.instance.client.from('promotion_history').insert({
        'owner_id': session.user.id,
        'store_id': store.id,
        'promotion_type': 'sns',
        'event_text': eventText,
        'keywords': keywords,
        'tone': _selectedTone,
        'generated_copy': generatedCopy,
      });

      if (!mounted) return;
      setState(() => _generatedCopy = generatedCopy);
      _showMessage('홍보 문구를 생성하고 기록에 저장했어요.');
      await _loadOwnerData();
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: 'AI 홍보 도우미',
            onBack: () => widget.onOpen(AppScreen.ownerRegistration),
            trailing: _IconButton(
              icon: Icons.history_rounded,
              onPressed: _loadOwnerData,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_secondary, _primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: _softCircle(86, Colors.white.withOpacity(0.16)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '우리 가게 홍보,\nAI에게 맡겨보세U!',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '메뉴 설명부터 SNS 문구까지\n클릭 한 번으로 완성됩니다.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.82),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const _SectionHeader(title: '필요한 홍보물을 선택해U'),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.campaign_rounded,
                  title: 'SNS 홍보 문구',
                  subtitle: '인스타그램, 당근마켓용 감성 문구',
                  status: _promotionHistory.isEmpty
                      ? '생성 기록 없음'
                      : '최근 생성: ${_formatDate(_promotionHistory.first['created_at'] as String?)}',
                  action: '작성하기',
                ),
                const _FeatureCard(
                  icon: Icons.description_rounded,
                  title: '메뉴/가게 소개',
                  subtitle: '손님들의 침샘을 자극하는 설명글',
                  status: '미작성',
                  action: '생성하기',
                ),
                const _FeatureCard(
                  icon: Icons.local_offer_rounded,
                  title: '타임딜 쿠폰',
                  subtitle: '조용한 시간대 손님 모시는 문구',
                  status: '최근 생성: 1시간 전',
                  action: '만들기',
                ),
                const SizedBox(height: 24),
                _SurfaceCard(
                  color: _surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(title: '홍보 정보 입력'),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        )
                      else if (_ownerStores.isEmpty)
                        _EmptyStateCard(
                          icon: Icons.storefront_rounded,
                          title: '등록된 내 가게가 없어요',
                          message: '우리 가게 등록하기에서 가게를 먼저 등록해주세요.',
                          actionLabel: '가게 등록하기',
                          onAction: () =>
                              widget.onOpen(AppScreen.ownerRegistration),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedStoreId,
                          decoration: const InputDecoration(
                            labelText: '홍보할 가게',
                            border: OutlineInputBorder(),
                          ),
                          items: _ownerStores
                              .map(
                                (store) => DropdownMenuItem(
                                  value: store.id,
                                  child: Text(store.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedStoreId = value);
                          },
                        ),
                      const SizedBox(height: 16),
                      _TextFieldBox(
                        label: '홍보할 메뉴/이벤트',
                        hint: '예: 신메뉴 들기름 막국수 출시',
                        icon: Icons.restaurant_menu_rounded,
                        controller: _eventController,
                      ),
                      const SizedBox(height: 16),
                      _TextFieldBox(
                        label: '강조하고 싶은 키워드',
                        hint: '쉼표로 구분: 고소함, 로컬 식재료, 할머니 손맛',
                        icon: Icons.sell_rounded,
                        controller: _keywordsController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SectionHeader(title: '문구 분위기'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['친절한', '재치있는', '감성적인', '짧고 강한']
                      .map(
                        (tone) => _Pill(
                          label: tone,
                          selected: _selectedTone == tone,
                          onTap: () => setState(() => _selectedTone = tone),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                _PrimaryButton(
                  label: _isGenerating ? '생성 중...' : '문구 생성하기',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _isGenerating ? () {} : _generatePromotionCopy,
                ),
                const SizedBox(height: 16),
                if (_generatedCopy?.isNotEmpty == true) ...[
                  _SurfaceCard(
                    color: _primary.withOpacity(0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('생성된 홍보 문구', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 10),
                        Text(
                          _generatedCopy!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_promotionHistory.isNotEmpty) ...[
                  const _SectionHeader(title: '최근 생성 기록'),
                  const SizedBox(height: 12),
                  ..._promotionHistory.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['event_text'] as String? ?? '홍보 문구',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatDate(item['created_at'] as String?),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['generated_copy'] as String? ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
                _SurfaceCard(
                  color: _surfaceVariant.withOpacity(0.50),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: _primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '구체적인 메뉴명과 분위기를 넣으면 더 자연스러운 홍보 문구가 만들어져요.',
                          style: theme.textTheme.bodySmall,
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
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.action,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final String action;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    status,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: _secondaryText),
                  ),
                ],
              ),
            ),
            Text(
              action,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: _primary),
            ),
          ],
        ),
      ),
    );
  }
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<DongNeuStore> _stores = const [];
  List<Map<String, dynamic>> _promotionHistory = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!_isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() {
        _isLoading = false;
        _error = '로그인 후 사장님 대시보드를 확인할 수 있어요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        Supabase.instance.client
            .from('stores')
            .select(_storeSelectColumns)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('promotion_history')
            .select('id, generated_copy, created_at')
            .order('created_at', ascending: false)
            .limit(5),
      ]);
      if (!mounted) return;
      setState(() {
        _stores = (responses[0] as List)
            .whereType<Map>()
            .map(
              (item) =>
                  DongNeuStore.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((store) => store.id.isNotEmpty)
            .toList(growable: false);
        _promotionHistory = (responses[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '대시보드 데이터를 불러오지 못했어요: $error';
      });
    }
  }

  int get _reviewCount {
    return _stores.fold<int>(0, (total, store) => total + store.reviewCount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '사장님 대시보드',
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      _IconButton(
                        icon: Icons.refresh_rounded,
                        onPressed: _loadDashboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else if (_error != null)
                    _EmptyStateCard(
                      icon: Icons.lock_outline_rounded,
                      title: '대시보드를 열 수 없어요',
                      message: _error!,
                      actionLabel: '계정 유형 선택',
                      onAction: () => widget.onOpen(AppScreen.userType),
                    )
                  else ...[
                    _SurfaceCard(
                      color: _primary.withOpacity(0.08),
                      child: Row(
                        children: [
                          _ExpandedStat(label: '등록 가게', value: '${_stores.length}'),
                          _ExpandedStat(label: '리뷰', value: '$_reviewCount'),
                          _ExpandedStat(
                            label: 'AI 홍보',
                            value: '${_promotionHistory.length}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: '빠른 메뉴'),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.add_business_rounded,
                      label: '새 가게 등록',
                      onTap: () => widget.onOpen(AppScreen.ownerRegistration),
                    ),
                    _MenuTile(
                      icon: Icons.edit_rounded,
                      label: '가게 정보 및 메뉴 관리',
                      onTap: () => widget.onOpen(AppScreen.ownerStoreManage),
                    ),
                    _MenuTile(
                      icon: Icons.campaign_rounded,
                      label: 'AI 홍보 문구 만들기',
                      onTap: () => widget.onOpen(AppScreen.promotion),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(title: '내 가게'),
                    const SizedBox(height: 12),
                    if (_stores.isEmpty)
                      _EmptyStateCard(
                        icon: Icons.storefront_rounded,
                        title: '등록된 가게가 없어요',
                        message: '가게를 등록하면 AI 추천과 홍보 도우미에 연결됩니다.',
                        actionLabel: '가게 등록하기',
                        onAction: () =>
                            widget.onOpen(AppScreen.ownerRegistration),
                      )
                    else
                      ..._stores.take(3).map((store) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SurfaceCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () =>
                                widget.onOpen(AppScreen.ownerStoreManage),
                            child: Row(
                              children: [
                                const _IconTile(
                                  icon: Icons.restaurant_rounded,
                                  color: _secondary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        store.name,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${store.category} · ${store.address}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: _accentText,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ],
              ),
            ),
          ),
          _OwnerBottomNav(current: AppScreen.ownerDashboard, onOpen: widget.onOpen),
        ],
      ),
    );
  }
}

class OwnerStoreManageScreen extends StatefulWidget {
  const OwnerStoreManageScreen({super.key, required this.onOpen});
  final ValueChanged<AppScreen> onOpen;

  @override
  State<OwnerStoreManageScreen> createState() => _OwnerStoreManageScreenState();
}

class _OwnerStoreManageScreenState extends State<OwnerStoreManageScreen> {
  List<DongNeuStore> _stores = const [];
  List<StoreMenuItem> _menus = const [];
  String? _selectedStoreId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  DongNeuStore? get _selectedStore {
    for (final store in _stores) {
      if (store.id == _selectedStoreId) return store;
    }
    return _stores.isEmpty ? null : _stores.first;
  }

  Future<void> _loadStores() async {
    if (!_isSupabaseConfigured ||
        Supabase.instance.client.auth.currentSession == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('stores')
          .select(_storeSelectColumns)
          .order('created_at', ascending: false);
      if (!mounted) return;
      final stores = (response as List)
          .whereType<Map>()
          .map((item) => DongNeuStore.fromJson(Map<String, dynamic>.from(item)))
          .where((store) => store.id.isNotEmpty)
          .toList(growable: false);
      setState(() {
        _stores = stores;
        _selectedStoreId = _selectedStoreId ?? stores.firstOrNull?.id;
        _isLoading = false;
      });
      await _loadMenus();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('가게 정보를 불러오지 못했어요: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadMenus() async {
    final store = _selectedStore;
    if (store == null || !_isSupabaseConfigured) {
      if (mounted) setState(() => _menus = const []);
      return;
    }

    final response = await Supabase.instance.client
        .from('menu_items')
        .select('id, name, description, price, is_representative')
        .eq('store_id', store.id)
        .order('is_representative', ascending: false)
        .order('created_at', ascending: true);
    if (!mounted) return;
    setState(() {
      _menus = (response as List)
          .whereType<Map>()
          .map(
            (item) => StoreMenuItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    });
  }

  void _showPendingMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('수정 저장은 다음 단계에서 연결할 예정입니다.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = _selectedStore;
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: '가게 관리',
            onBack: () => widget.onOpen(AppScreen.ownerDashboard),
            trailing: _IconButton(
              icon: Icons.refresh_rounded,
              onPressed: _loadStores,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                else if (_stores.isEmpty)
                  _EmptyStateCard(
                    icon: Icons.storefront_rounded,
                    title: '관리할 가게가 없어요',
                    message: '가게를 먼저 등록하면 메뉴와 상태를 확인할 수 있어요.',
                    actionLabel: '가게 등록하기',
                    onAction: () =>
                        widget.onOpen(AppScreen.ownerRegistration),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    value: store?.id,
                    decoration: const InputDecoration(
                      labelText: '관리할 가게',
                      border: OutlineInputBorder(),
                    ),
                    items: _stores
                        .map(
                          (store) => DropdownMenuItem(
                            value: store.id,
                            child: Text(store.name),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => _selectedStoreId = value);
                      await _loadMenus();
                    },
                  ),
                  const SizedBox(height: 18),
                  if (store != null)
                    _SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(store.name, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 6),
                          Text(store.category, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 12),
                          Text(store.address, style: theme.textTheme.bodyMedium),
                          if (store.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            Text(
                              store.description!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    value: true,
                    onChanged: (_) => _showPendingMessage(),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('영업 중'),
                    subtitle: const Text('영업 상태 변경 저장은 추후 연결 예정'),
                  ),
                  const SizedBox(height: 18),
                  const _SectionHeader(title: '메뉴'),
                  const SizedBox(height: 12),
                  if (_menus.isEmpty)
                    _SurfaceCard(
                      color: _surfaceVariant.withOpacity(0.50),
                      child: Text(
                        '등록된 메뉴가 없어요.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  else
                    ..._menus.map((menu) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SurfaceCard(
                          padding: const EdgeInsets.all(16),
                          onTap: _showPendingMessage,
                          child: Row(
                            children: [
                              _IconTile(
                                icon: menu.isRepresentative
                                    ? Icons.star_rounded
                                    : Icons.restaurant_menu_rounded,
                                color: menu.isRepresentative
                                    ? _tertiary
                                    : _primary,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.name,
                                      style: theme.textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatWon(menu.price),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.edit_rounded,
                                color: _accentText,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
          _OwnerBottomNav(
            current: AppScreen.ownerStoreManage,
            onOpen: widget.onOpen,
          ),
        ],
      ),
    );
  }
}

class OwnerMyPageScreen extends StatelessWidget {
  const OwnerMyPageScreen({
    super.key,
    required this.onOpen,
    required this.onSignOut,
    required this.userEmail,
  });
  final ValueChanged<AppScreen> onOpen;
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
                  icon: Icons.settings_rounded,
                  label: '설정',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('설정 화면은 다음 단계에서 연결할 예정입니다.'),
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
  });
  final ValueChanged<AppScreen> onOpen;
  final Future<void> Function() onSignOut;
  final String? userEmail;
  final String? accountRole;

  String get _roleLabel {
    return switch (accountRole) {
      _ownerRole => '사장님 계정',
      _customerRole => '손님 계정',
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
                            content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
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
                        content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
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
                        content: Text('백엔드 연동 후 제공될 기능입니다 🚀'),
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
                  onTap: () => onOpen(AppScreen.userType),
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

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    required this.onOpen,
    required this.onQueryChange,
    required this.onRecommend,
  });
  final ValueChanged<AppScreen> onOpen;
  final ValueChanged<String> onQueryChange;
  final Future<List<AiRecommendation>> Function(String query) onRecommend;
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'isAi': true,
      'text':
          '안녕하세요! 동네U AI입니다. 오늘 어떤 식사나 모임을 계획하고 계신가요? 상황, 예산, 취향을 편하게 말씀해주세요.',
    },
  ];
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    if (_controller.text.trim().isEmpty) return;
    final userText = _controller.text.trim();
    widget.onQueryChange(userText);
    setState(() {
      _messages.add({'isAi': false, 'text': userText});
      _messages.add({'isAi': true, 'text': '조건을 분석하고 동네 맛집을 찾는 중이에요.'});
      _controller.clear();
      _isSending = true;
    });

    try {
      final recommendations = await widget.onRecommend(userText);
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add({
          'isAi': true,
          'text': '${recommendations.length}곳을 찾았어요. 아래 버튼을 눌러 추천 결과를 확인해보세요.',
          'action': true,
        });
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add({
          'isAi': true,
          'text': 'AI 추천 요청에 실패했어요. Flask 서버가 켜져 있는지 확인한 뒤 다시 시도해주세요.\n$error',
        });
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _PhoneFrame(
      child: Column(
        children: [
          _TopBar(
            title: 'AI 동네 검색',
            onBack: () => widget.onOpen(AppScreen.home),
          ),
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
                    mainAxisAlignment: isAi
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      if (isAi) ...[
                        const _IconTile(
                          icon: Icons.auto_awesome_rounded,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isAi
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isAi ? _surface : _primary,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(24),
                                  topRight: const Radius.circular(24),
                                  bottomLeft: Radius.circular(isAi ? 4 : 24),
                                  bottomRight: Radius.circular(isAi ? 24 : 4),
                                ),
                                border: isAi
                                    ? Border.all(color: _alternate)
                                    : null,
                              ),
                              child: Text(
                                msg['text'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isAi ? _primaryText : Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            if (msg['action'] == true) ...[
                              const SizedBox(height: 12),
                              _PrimaryButton(
                                label: '추천 결과 보기',
                                icon: Icons.list_alt_rounded,
                                onPressed: () =>
                                    widget.onOpen(AppScreen.aiCondition),
                              ),
                            ],
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
                    decoration: BoxDecoration(
                      color: _surfaceVariant,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '예: 비 오는 날 어울리는 파전 맛집',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      enabled: !_isSending,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _isSending ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
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
