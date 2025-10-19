import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String?> uploadPetPhoto(File file, String petId) async {
    try {
      Reference ref = _storage.ref().child('pet_photos/$petId.jpg');
      await ref.putFile(file);
      String url = await ref.getDownloadURL();
      debugPrint('📸 Foto enviada com sucesso: $url');
      return url;
    } catch (e) {
      debugPrint('Erro ao enviar foto: $e');
      return null;
    }
  }

  static Future<void> deletePetPhoto(String petId) async {
    try {
      Reference ref = _storage.ref().child('pet_photos/$petId.jpg');
      await ref.delete();
      debugPrint('🗑️ Foto do pet $petId removida.');
    } catch (e) {
      debugPrint('Erro ao remover foto: $e');
    }
  }
}
