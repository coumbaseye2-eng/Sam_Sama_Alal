import '../../profile/domain/app_user.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.errorMessage,
    this.pendingRegistration,
  });

  final AppUser? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? errorMessage;
  final PendingRegistration? pendingRegistration;

  bool get hasUser => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? isLoggedIn,
    bool? isLoading,
    String? errorMessage,
    PendingRegistration? pendingRegistration,
    bool clearPendingRegistration = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pendingRegistration: clearPendingRegistration
          ? null
          : pendingRegistration ?? this.pendingRegistration,
    );
  }
}

class PendingRegistration {
  const PendingRegistration({
    required this.fullName,
    required this.email,
    required this.password,
    required this.activityType,
    required this.dailyGoal,
  });

  final String fullName;
  final String email;
  final String password;
  final String activityType;
  final int dailyGoal;
}
