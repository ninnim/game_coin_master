import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/game/screens/main_game_screen.dart';
import 'features/village/screens/village_map_screen.dart';
import 'features/village/screens/village_detail_screen.dart';
import 'features/cards/screens/card_collection_screen.dart';
import 'features/cards/screens/chest_shop_screen.dart';
import 'features/pets/screens/pets_screen.dart';
import 'features/social/screens/friends_screen.dart';
import 'features/social/screens/leaderboard_screen.dart';
import 'features/clans/screens/clans_screen.dart';
import 'features/events/screens/events_screen.dart';
import 'features/achievements/screens/achievements_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/game/screens/attack_screen.dart';
import 'features/game/screens/raid_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const MainGameScreen(),
      ),
      GoRoute(
        path: '/village-map',
        builder: (context, state) => const VillageMapScreen(),
      ),
      GoRoute(
        path: '/village',
        builder: (context, state) => const VillageDetailScreen(),
      ),
      GoRoute(
        path: '/cards',
        builder: (context, state) => const CardCollectionScreen(),
      ),
      GoRoute(
        path: '/chests',
        builder: (context, state) => const ChestShopScreen(),
      ),
      GoRoute(
        path: '/pets',
        builder: (context, state) => const PetsScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/clans',
        builder: (context, state) => const ClansScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/attack',
        builder: (context, state) => const AttackScreen(),
      ),
      GoRoute(
        path: '/raid',
        builder: (context, state) => const RaidScreen(),
      ),
    ],
  );
});
