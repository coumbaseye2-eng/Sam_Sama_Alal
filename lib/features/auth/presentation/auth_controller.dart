import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../profile/domain/app_user.dart';
import 'auth_state.dart';

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(localStorageServiceProvider);
    return AuthState(
      user: storage.readUser(),
      isLoggedIn: storage.readIsLoggedIn(),
    );
  }

  void startRegistration(PendingRegistration registration) {
    state = state.copyWith(pendingRegistration: registration);
  }

  Future<bool> registerWithEmailAndPassword(
      PendingRegistration registration) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: registration.email.trim(),
        password: registration.password,
      );
      await credential.user?.updateDisplayName(registration.fullName);

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Compte créé, mais utilisateur Firebase introuvable.',
        );
        return false;
      }

      final user = AppUser(
        uid: firebaseUser.uid,
        fullName: registration.fullName,
        email: registration.email.toLowerCase().trim(),
        activityType: registration.activityType,
        dailyGoal: registration.dailyGoal,
        passwordHash: '',
        photoUrl: null,
      );

      await _saveUserProfile(user);
      state = AuthState(user: user, isLoggedIn: true);
      await ref
          .read(localStorageServiceProvider)
          .saveUser(user, isLoggedIn: true);
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _firebaseAuthMessage(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Une erreur est survenue. Réessaie.',
      );
      return false;
    }
  }

  void completeRegistration(String pin) {
    final registration = state.pendingRegistration;
    if (registration == null) {
      return;
    }

    final user = AppUser(
      uid: FirebaseAuth.instance.currentUser?.uid ?? 'local-user',
      fullName: registration.fullName,
      email: registration.email.toLowerCase(),
      activityType: registration.activityType,
      dailyGoal: registration.dailyGoal,
      passwordHash: _hashSecret(registration.password),
      pinHash: _hashPin(pin),
      photoUrl: null,
    );

    state = AuthState(user: user, isLoggedIn: true);
    ref.read(localStorageServiceProvider).saveUser(user, isLoggedIn: true);
  }

  void updatePin(String pin) {
    final user = state.user;
    if (user == null) {
      return;
    }

    final updatedUser = user.copyWith(pinHash: _hashPin(pin));
    state = state.copyWith(user: updatedUser);
    ref
        .read(localStorageServiceProvider)
        .saveUser(updatedUser, isLoggedIn: state.isLoggedIn);
  }

  Future<bool> updateProfile({
    required String fullName,
    required String activityType,
    required int dailyGoal,
    String? photoUrl,
  }) async {
    final user = state.user;
    if (user == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final updatedUser = user.copyWith(
      fullName: fullName.trim().isEmpty ? user.fullName : fullName.trim(),
      activityType:
          activityType.trim().isEmpty ? user.activityType : activityType.trim(),
      dailyGoal: dailyGoal,
      photoUrl: photoUrl ?? user.photoUrl,
    );

    state = state.copyWith(user: updatedUser, isLoading: false);
    await ref
        .read(localStorageServiceProvider)
        .saveUser(updatedUser, isLoggedIn: state.isLoggedIn);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(updatedUser.fullName);
        await FirebaseFirestore.instance.collection('users').doc(updatedUser.uid).set(
          {
            'uid': updatedUser.uid,
            'fullName': updatedUser.fullName,
            'email': updatedUser.email,
            'activityType': updatedUser.activityType,
            'dailyGoal': updatedUser.dailyGoal,
            'photoUrl': updatedUser.photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Mise à jour locale prioritaire; la sync cloud reste best-effort.
    }

    return true;
  }

  Future<bool> deleteAccount() async {
    final user = state.user;
    if (user == null) {
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await firebaseUser.delete();
      }

      await ref.read(localStorageServiceProvider).clearAccountData();
      state = const AuthState();
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.code == 'requires-recent-login'
            ? 'Reconnecte-toi pour supprimer ton compte.'
            : _firebaseAuthMessage(error),
      );
      return false;
    } catch (_) {
      await ref.read(localStorageServiceProvider).clearAccountData();
      state = const AuthState();
      return true;
    }
  }

  bool loginWithPin(String pin) {
    final user = state.user;
    if (user == null) {
      return false;
    }

    final isValid = user.pinHash == _hashPin(pin);
    if (isValid) {
      state = state.copyWith(isLoggedIn: true);
      ref.read(localStorageServiceProvider).saveLoginState(true);
    }
    return isValid;
  }

  Future<bool> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Utilisateur Firebase introuvable.',
        );
        return false;
      }

      final cachedUser = ref.read(localStorageServiceProvider).readUser();
      final cloudUser = await _readUserProfile(firebaseUser.uid);
      final user = AppUser(
        uid: firebaseUser.uid,
        fullName: cloudUser?.fullName ??
            firebaseUser.displayName ??
            cachedUser?.fullName ??
            'Commerçant',
        email: firebaseUser.email ?? email.trim().toLowerCase(),
        activityType:
            cloudUser?.activityType ?? cachedUser?.activityType ?? 'Boutiquier',
        dailyGoal: cloudUser?.dailyGoal ?? cachedUser?.dailyGoal ?? 0,
        passwordHash: '',
        pinHash: cloudUser?.pinHash ?? cachedUser?.pinHash ?? '',
        photoUrl: cloudUser?.photoUrl ?? cachedUser?.photoUrl,
      );

      state = AuthState(user: user, isLoggedIn: true);
      await ref
          .read(localStorageServiceProvider)
          .saveUser(user, isLoggedIn: true);
      return true;
    } on FirebaseAuthException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _firebaseAuthMessage(error),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Une erreur est survenue. Réessaie.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = state.copyWith(isLoggedIn: false);
    await ref.read(localStorageServiceProvider).saveLoginState(false);
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  String _hashSecret(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  Future<void> _saveUserProfile(AppUser user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': user.fullName,
        'email': user.email,
        'activityType': user.activityType,
        'dailyGoal': user.dailyGoal,
        'photoUrl': user.photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Le profil local Hive reste la source de secours si Firestore n'est pas prêt.
    }
  }

  Future<AppUser?> _readUserProfile(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return AppUser(
        uid: uid,
        fullName: data['fullName'] as String? ?? 'Commerçant',
        email: data['email'] as String? ?? '',
        activityType: data['activityType'] as String? ?? 'Boutiquier',
        dailyGoal: data['dailyGoal'] as int? ?? 0,
        passwordHash: '',
        pinHash: data['pinHash'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => 'Cette adresse mail est déjà utilisée.',
      'invalid-email' => 'Adresse mail invalide.',
      'operation-not-allowed' => 'Connexion email/mot de passe non activée.',
      'weak-password' => 'Mot de passe trop faible.',
      'user-disabled' => 'Ce compte est désactivé.',
      'user-not-found' => 'Aucun compte trouvé avec cette adresse mail.',
      'wrong-password' ||
      'invalid-credential' =>
        'Adresse mail ou mot de passe incorrect.',
      'network-request-failed' => 'Connexion internet indisponible.',
      _ => 'Erreur Firebase: ${error.message ?? error.code}',
    };
  }
}
