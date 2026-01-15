import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;

  // ========== PHONE AUTHENTICATION ==========

  /// Étape 1 : Envoyer le code SMS
  Future<bool> sendPhoneVerification(
      String phoneNumber,
      Function(String) onCodeSent,
      Function(String) onError,
      ) async {
    try {
      // Vérifier si le numéro existe déjà
      final exists = await checkPhoneNumberExists(phoneNumber);
      if (exists) {
        onError('Ce numéro est déjà utilisé');
        return false;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber, // Format: +212612345678
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError('Erreur: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent('Code envoyé avec succès au $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return true;
    } catch (e) {
      onError('Erreur: $e');
      return false;
    }
  }

  /// Étape 2 : Vérifier le code OTP
  Future<User?> verifyPhoneCode(String smsCode) async {
    try {
      if (_verificationId == null) {
        print('Erreur: Aucun ID de vérification');
        return null;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Code invalide: $e');
      return null;
    }
  }

  /// Vérifier si un numéro existe déjà
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Erreur vérification numéro: $e');
      return false;
    }
  }

  // ========== USER MANAGEMENT ==========

  /// Créer un profil utilisateur dans Firestore
  Future<bool> createUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      print('✅ Profil créé pour ${user.fullName} (${user.uid})');
      return true;
    } catch (e) {
      print('❌ Erreur création profil: $e');
      return false;
    }
  }

  /// Récupérer le profil utilisateur
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }

  /// Mettre à jour le rôle d'un utilisateur
  Future<void> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
      });
    } catch (e) {
      print('Erreur mise à jour rôle: $e');
    }
  }

  /// Marquer un utilisateur comme vérifié
  Future<void> markUserAsVerified(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
        'reputationPoints': FieldValue.increment(10),
      });
    } catch (e) {
      print('Erreur vérification: $e');
    }
  }

  // ========== EMAIL/PASSWORD AUTH (garder pour compatibilité) ==========

  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur inscription: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  // ========== COMMANDS (Realtime Database) ==========

  void sendCommand(String command, {String? section}) {
    final data = {
      'command': command,
      'timestamp': DateTime.now().toIso8601String(),
      'section': section ?? 'Tous',
    };

    _database.ref('commands').set(data);
    print('✅ Commande envoyée: $command → ${section ?? "Tous"}');
  }

  Stream<Map<dynamic, dynamic>> listenForCommands() {
    return _database.ref('commands').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      return data ?? {};
    });
  }

  // ========== MAESTRO CODES ==========

  /// Vérifier si un code maestro est valide
  Future<bool> verifyMaestroCode(String code) async {
    try {
      final doc = await _firestore.collection('maestro_codes').doc(code).get();

      if (!doc.exists) {
        print('❌ Code maestro inexistant');
        return false;
      }

      final data = doc.data()!;
      final isUsed = data['used'] ?? true;

      // Parser la date d'expiration avec gestion d'erreurs
      DateTime expiresAt;
      try {
        final expiresAtStr = (data['expiresAt'] as String?)?.trim(); // Enlever espaces
        if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
          expiresAt = DateTime.parse(expiresAtStr);
        } else {
          expiresAt = DateTime.now().subtract(Duration(days: 1)); // Expiré par défaut
        }
      } catch (e) {
        print('⚠️ Format de date invalide, code considéré comme expiré');
        expiresAt = DateTime.now().subtract(Duration(days: 1));
      }

      if (isUsed) {
        print('❌ Code maestro déjà utilisé');
        return false;
      }

      if (expiresAt.isBefore(DateTime.now())) {
        print('❌ Code maestro expiré');
        return false;
      }

      print('✅ Code maestro valide');
      return true;
    } catch (e) {
      print('❌ Erreur vérification code: $e');
      return false;
    }
  }

  /// Marquer un code maestro comme utilisé
  Future<void> useMaestroCode(String code, String usedByUid) async {
    try {
      await _firestore.collection('maestro_codes').doc(code).update({
        'used': true,
        'usedBy': usedByUid,
        'usedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Code maestro marqué comme utilisé');
    } catch (e) {
      print('❌ Erreur usage code: $e');
    }
  }

  // ========== SPONSORSHIP (PARRAINAGE) ==========

  /// Vérifier un code de parrainage
  Future<String?> verifySponsorshipCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('maestros')
          .where('sponsorshipCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('❌ Code de parrainage invalide');
        return null;
      }

      final maestroUid = snapshot.docs.first.id;

      // Vérifier si le maestro n'a pas déjà parrainé 2 personnes
      final sponsoredCount = await _firestore
          .collection('users')
          .where('sponsoredBy', isEqualTo: maestroUid)
          .get();

      if (sponsoredCount.docs.length >= 2) {
        print('❌ Ce maestro a atteint sa limite de parrainages');
        return null;
      }

      print('✅ Code de parrainage valide');
      return maestroUid;
    } catch (e) {
      print('❌ Erreur vérification parrainage: $e');
      return null;
    }
  }

  // ========== LOGOUT ==========

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ========== GET CURRENT USER ==========

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}