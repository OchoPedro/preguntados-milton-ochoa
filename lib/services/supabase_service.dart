import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/env.dart';

class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await Supabase.initialize(
      url:          Env.supabaseUrl,
      anonKey:      Env.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  // Auth helpers
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) => client.auth.signInWithPassword(email: email, password: password);

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
  }) => client.auth.signUp(
    email: email,
    password: password,
    data: {'full_name': displayName, 'username': username},
  );

  static Future<void> signOut() => client.auth.signOut();

  static Future<bool> signInWithGoogle() =>
    client.auth.signInWithOAuth(OAuthProvider.google);
}
