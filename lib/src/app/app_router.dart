part of '../../main.dart';

class _AppRouter extends StatelessWidget {
  const _AppRouter({
    required this.screen,
    required this.onOpen,
    required this.onGoBack,
    required this.onOpenCustomerService,
    required this.onOpenOwnerService,
    required this.onAuthenticated,
    required this.onRoleSelected,
    required this.onSignOut,
    required this.userEmail,
    required this.accountRole,
    required this.myLocation,
    required this.onLocationChange,
    required this.aiQuery,
    required this.onAiQueryChange,
    required this.aiConditions,
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
  final VoidCallback onGoBack;
  final VoidCallback onOpenCustomerService;
  final VoidCallback onOpenOwnerService;
  final Future<void> Function() onAuthenticated;
  final Future<void> Function(String role) onRoleSelected;
  final Future<void> Function() onSignOut;
  final String? userEmail;
  final String? accountRole;
  final String myLocation;
  final ValueChanged<String> onLocationChange;
  final String aiQuery;
  final ValueChanged<String> onAiQueryChange;
  final AiConditions? aiConditions;
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
        onGoBack: onGoBack,
        query: aiQuery,
        aiConditions: aiConditions,
      ),
      AppScreen.aiChat => AiChatScreen(
        onOpen: onOpen,
        onGoBack: onGoBack,
        onQueryChange: onAiQueryChange,
        onRecommend: onAiRecommend,
      ),
      AppScreen.recommendations => Top3RecommendationsScreen(
        onOpen: onOpen,
        onGoBack: onGoBack,
        query: aiQuery,
        recommendations: aiRecommendations,
        stores: stores,
        onStoreNameOpen: onStoreNameOpen,
      ),
      AppScreen.filters => ManualSearchFiltersScreen(
        onOpen: onOpen,
        myLocation: myLocation,
        onAiQueryChange: onAiQueryChange,
        onAiRecommend: onAiRecommend,
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
        onOpenCustomerService: onOpenCustomerService,
        onSignOut: onSignOut,
        userEmail: userEmail,
      ),
      AppScreen.mypage => MyPageScreen(
        onOpen: onOpen,
        onSignOut: onSignOut,
        userEmail: userEmail,
        accountRole: accountRole,
        onOpenOwnerService: onOpenOwnerService,
      ),
    };
  }
}
