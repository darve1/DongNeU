import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

part 'src/core/app_config.dart';
part 'src/core/models.dart';
part 'src/core/theme.dart';
part 'src/app/app_shell.dart';
part 'src/app/app_router.dart';
part 'src/widgets/shared_widgets.dart';
part 'src/screens/auth_flow.dart';
part 'src/screens/customer_home.dart';
part 'src/screens/manual_search.dart';
part 'src/screens/store_detail.dart';
part 'src/screens/saved_history.dart';
part 'src/screens/owner_registration.dart';
part 'src/screens/owner_promotion.dart';
part 'src/screens/owner_dashboard.dart';
part 'src/screens/owner_store_manage.dart';
part 'src/screens/account_screens.dart';
part 'src/screens/ai_chat.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await NaverMapSdk.instance.initialize(clientId: AppConfig.naverMapClientId);
  }
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const DongNeuApp());
}
