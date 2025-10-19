import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/app_variables.dart';
import '../core/local_storage.dart';
import 'fcm_service.dart';
import 'user_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String collection = 'users';
  static const String googleWebClientId = '117457996829-04cioo0h8slvstfq6ep0ncjceakbuk11.apps.googleusercontent.com';

  static String? validatePassword(String password) {
    if (password.length < 6) return "A senha deve ter no mínimo 6 caracteres.";
    if (password.length > 20) return "A senha deve ter no máximo 20 caracteres.";
    if (!RegExp(r'[a-z]').hasMatch(password)) return "A senha deve conter pelo menos uma letra minúscula.";
    if (!RegExp(r'[A-Z]').hasMatch(password)) return "A senha deve conter pelo menos uma letra maiúscula.";
    if (!RegExp(r'\d').hasMatch(password)) return "A senha deve conter pelo menos um número.";
    if (!RegExp(r'[!@#$&*~\\]').hasMatch(password)) return "A senha deve conter pelo menos um caractere especial.";
    return null;
  }

  static bool isLoggedIn() => _auth.currentUser != null;

  static String? currentUid() => _auth.currentUser?.uid;

  static Future<UserCredential> createUserAccount({
    required BuildContext context,
    required String displayName,
    required String email,
    required String password,
    String familyCode = '',
    List<String> fcmTokens = const [],
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await UserService.addUser(
        uidAuth: res.user!.uid,
        displayName: displayName,
        email: email,
        familyCode: familyCode,
        fcmTokens: fcmTokens,
      );
      await sendEmailVerification(context, res.user!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conta criada com sucesso!")));
      return res;
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'email-already-in-use' => 'Este e-mail já está em uso.',
        'invalid-email' => 'E-mail inválido.',
        _ => 'Erro ao criar conta. Tente novamente.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    throw Exception('Erro ao criar conta.');
  }

  static Future<void> authenticateAccount({
    required BuildContext context,
    required String email,
    required String password,
    required bool saveLogin,
    required String routeAfterLogin,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user == null) throw FirebaseAuthException(code: 'user-not-found');

      await user.reload();
      User? refreshedUser = _auth.currentUser;

      if (refreshedUser!.emailVerified) {
        if (saveLogin) await LocalStorage.saveToken();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Autenticado com sucesso!")));
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FCMService.initializeFCM(user.uid);
        }
        Navigator.of(context).pushReplacementNamed(routeAfterLogin);
      } else {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("E-mail de verificação enviado. Verifique sua caixa de entrada.")));
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      Map<String, String> messages = {
        'invalid-email': 'E-mail inválido.',
        'user-disabled': 'Esta conta foi desativada.',
        'user-not-found': 'Usuário não encontrado.',
        'wrong-password': 'Senha incorreta.',
        'invalid-credential': 'Credencial inválida.',
        'operation-not-allowed': 'Operação não permitida.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(messages[e.code] ?? 'Erro ao autenticar o usuário.')));
    }
  }

  static Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;
      await signIn.initialize(clientId: googleWebClientId);
      signIn.authenticationEvents.listen((event) async {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn(:final user):
            GoogleSignInServerAuthorization? serverAuth = await user.authorizationClient.authorizeServer(['email', 'profile']);
            if (serverAuth == null) throw Exception('Falha ao obter serverAuthCode.');

            OAuthCredential credential = GoogleAuthProvider.credential(idToken: serverAuth.serverAuthCode);
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            User? firebaseUser = userCredential.user;
            if (firebaseUser == null) throw Exception('Falha ao autenticar no Firebase.');
            DocumentReference<Map<String, dynamic>> userRef = _firestore.collection('users').doc(firebaseUser.uid);
            DocumentSnapshot<Map<String, dynamic>> doc = await userRef.get();
            if (!doc.exists) {
              await userRef.set({
                'displayName': firebaseUser.displayName,
                'email': firebaseUser.email,
                'createdAt': DateTime.now(),
                'fcmTokens': [],
                'familyCode': null,
              });
            }
            await FCMService.initializeFCM(firebaseUser.uid);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Login realizado com sucesso!')));
              Navigator.pushReplacementNamed(context, '/onboarding');
            }
            break;
          case GoogleSignInAuthenticationEventSignOut():
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login cancelado pelo usuário.')));
            }
            break;
        }
      });
      await signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro GoogleSignInException: ${e.code} - ${e.description}')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro no login Google: $e')));
      }
    }
  }

  static Future<void> signOut(BuildContext context) async {
    await FCMService.deleteToken();
    await LocalStorage.deleteToken();
    AppVariables.familyCode = null;
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.disconnect();
    await _auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deslogado com sucesso!")));
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static Future<void> sendEmailVerification(BuildContext context, User user) async {
    if (!user.emailVerified) {
      await user.sendEmailVerification();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("E-mail de verificação enviado. Verifique sua caixa de entrada.")));
    }
  }

  static Future<void> resetPassword(BuildContext context, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-mail de redefinição de senha enviado.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao enviar e-mail de redefinição de senha.")));
    }
  }
}
