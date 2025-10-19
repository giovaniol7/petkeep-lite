import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FamilyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'families';

  static Future<void> createFamily({required String familyCode}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc(familyCode);
    await docRef.set({'createdAt': DateTime.now().toIso8601String(), 'ownerUid': user.uid});
  }

  static Future<void> updateOwner({required String familyCode, required String ownerUid}) async {
    DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc(familyCode);
    await docRef.update({'ownerUid': ownerUid});
  }

  static Future<void> deleteFamily(String familyCode) async {
    await _firestore.collection(_collection).doc(familyCode).delete();
  }

  static Future<Map<String, dynamic>?> getFamily(String familyCode) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection(_collection).doc(familyCode).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<List<Map<String, dynamic>>> getAllFamilies() async {
    QuerySnapshot<Map<String, dynamic>> query = await _firestore.collection(_collection).get();
    return query.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
