import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'storage_service.dart';

class PetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collection = 'pets';

  static Future<void> addPet({
    required BuildContext context,
    required String familyCode,
    required String name,
    required String species,
    required String birthDate,
    required double weightKg,
    File? photoFile,
  }) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc();
      String? photoUrl = await StorageService.uploadPetPhoto(photoFile!, docRef.id);

      await docRef.set({
        'id': docRef.id,
        'familyCode': familyCode,
        'name': name.trim(),
        'species': species,
        'birthDate': birthDate,
        'weightKg': weightKg,
        'photoUrl': photoUrl ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pet adicionado com sucesso: $name')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar pet: $e')));
    }
  }

  static Future<void> editPet({
    required BuildContext context,
    required String petId,
    String? name,
    String? species,
    String? birthDate,
    double? weightKg,
    String? newPhoto,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(petId);
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name.trim();
      if (species != null) updates['species'] = species;
      if (birthDate != null) updates['birthDate'] = birthDate;
      if (weightKg != null) updates['weightKg'] = weightKg;
      if (newPhoto != null) updates['photoUrl'] = newPhoto;
      if (updates.isNotEmpty) await docRef.update(updates);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pet atualizado com sucesso: $petId')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar pet: $e')));
    }
  }

  static Future<void> deletePet(String petId, {required BuildContext context}) async {
    try {
      await _firestore.collection(_collection).doc(petId).delete();
      await _storage.ref('pet_photos/$petId.jpg').delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pet excluído com sucesso: $petId')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir pet: $e')));
    }
  }

  static Stream<List<Map<String, dynamic>>> streamPetsByFamily(String familyCode) {
    return _firestore
        .collection(_collection)
        .where('familyCode', isEqualTo: familyCode)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  static Future<Map<String, dynamic>?> getPetById(String petId) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection(_collection).doc(petId).get();
    return doc.exists ? doc.data() : null;
  }


}
