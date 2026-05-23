part of '../../main.dart';

class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const isSupabaseConfigured =
      supabaseUrl.length > 10 && supabaseAnonKey.length > 10;
  static const flaskAiBaseUrl = String.fromEnvironment(
    'FLASK_AI_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
  static const naverMapClientId = String.fromEnvironment(
    'NAVER_MAP_CLIENT_ID',
    defaultValue: 'j13ue7xko4',
  );
}

class AppRoles {
  const AppRoles._();

  static const customer = 'customer';
  static const owner = 'owner';
}

class StoreQueries {
  const StoreQueries._();

  static const storeSelectColumns =
      'id, name, category, address, description, image_url, rating, review_count, price_range, opening_hours, phone, tags, features';
}

class AppDefaults {
  const AppDefaults._();

  static const location = '충남대 궁동';
  static const aiQuery = '충남대 근처 가성비 혼밥 추천해줘';
  static const aiConditionQuery = '충남대 근처에서 혼자 먹기 좋고 만 원 이하로 든든한 저녁 추천해줘';
  static const aiSearchExample = '예: 충남대 근처 가성비 혼밥 추천해줘';
  static const nearbyNeighborhoods = [
    '대전 유성구 궁동',
    '대전 유성구 어은동',
    '대전 유성구 봉명동',
    '대전 유성구 죽동',
  ];
}

class RecommendationKeywords {
  const RecommendationKeywords._();

  static const candidates = [
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
}

class AppMessages {
  const AppMessages._();

  static const backendPending = '백엔드 연동 후 제공될 기능입니다 🚀';
}

Map<String, String> _jsonHeadersWithAuth() {
  final headers = {'Content-Type': 'application/json'};
  if (!AppConfig.isSupabaseConfigured) return headers;

  final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
  if (accessToken != null && accessToken.isNotEmpty) {
    headers['Authorization'] = 'Bearer $accessToken';
  }
  return headers;
}
