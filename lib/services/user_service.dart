import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'users';

  static Future<String?> findUserDocId() async {
    QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection(_collection)
        .where('uidAuth', isEqualTo: AuthService.currentUid())
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first.id;
    return null;
  }

  static Future<void> addUser({
    required String uidAuth,
    required String displayName,
    required String email,
    required String familyCode,
    required List<String> fcmTokens,
  }) async {
    DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc();

    await docRef.set({
      'uidAuth': uidAuth,
      'id': docRef.id,
      'displayName': displayName.trim().toUpperCase(),
      'email': email,
      'familyCode': familyCode,
      'fcmTokens': fcmTokens,
    });
  }

  static Future<void> editUser(
    BuildContext context, {
    required String displayName,
    required String email,
    required String familyCode,
    required List<String> fcmTokens,
  }) async {
    Map<String, dynamic> data = {
      'displayName': displayName.trim().toUpperCase(),
      'email': email,
      'familyCode': familyCode,
      'fcmTokens': fcmTokens,
    };
    String? id = await findUserDocId();
    if (id != null) {
      await _firestore.collection(_collection).doc(id).update(data);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuário editado com sucesso!")));
    }
  }

  static Future<bool> editPassword(BuildContext context, String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null || user.email == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao encontrar usuário.")));
        return false;
      }
      AuthCredential cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Usuário editado com sucesso!")));
      return true;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao editar usuário.")));
      return false;
    }
  }

  static Future<void> disableUser(
    BuildContext context, {
    required String uid,
    required String displayName,
    required String email,
    required String familyCode,
    required List<String> fcmTokens,
  }) async {
    String? id = await findUserDocId();
    if (id == null) return;

    await _firestore.collection(_collection).doc(id).update({
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'familyCode': familyCode,
      'fcmTokens': fcmTokens,
    });
  }

  static Future<Map<String, dynamic>> getUser() async {
    QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection(_collection)
        .where('uidAuth', isEqualTo: AuthService.currentUid())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return {};
    DocumentSnapshot<Map<String, dynamic>> doc = query.docs.first;
    return {'id': doc.id, ...?doc.data()};
  }

  static Future<void> familyEnter({required BuildContext context, required User user, required String familyCode}) async {
    await _firestore.collection(_collection).doc(user.uid).set({
      'displayName': user.displayName,
      'email': user.email,
      'familyCode': familyCode,
    }, SetOptions(merge: true));
  }
}
