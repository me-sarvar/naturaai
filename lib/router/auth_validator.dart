import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../shared/providers/auth_provider.dart';

GoRouterRedirect getAuthRedirect(WidgetRef ref) {
  return (BuildContext context, GoRouterState state) {
    final loggedIn = ref.read(authProvider);
    final loggingIn = state.uri.path == '/login' || state.uri.path == '/signup';

    if (!loggedIn && !loggingIn) return '/login';
    if (loggedIn && loggingIn) return '/home';

    return null;
  };
}