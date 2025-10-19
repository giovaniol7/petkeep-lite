import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'pet_tasks';

  static Future<void> addTask({
    required BuildContext context,
    required String petId,
    required String familyCode,
    required String type,
    required String title,
    required String dueDate,
    String? notes,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não autenticado.');

      DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc();
      await docRef.set({
        'id': docRef.id,
        'petId': petId,
        'familyCode': familyCode,
        'type': type,
        'title': title.trim(),
        'dueDate': dueDate,
        'notes': notes ?? '',
        'createdBy': user.uid,
        'createdAt': DateTime.now().toIso8601String(),
        'done': false,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa adicionada com sucesso ($type): $title')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao adicionar tarefa: $e')));
    }
  }

  static Future<void> editTask({
    required BuildContext context,
    required String taskId,
    String? familyCode,
    String? title,
    String? type,
    String? dueDate,
    String? notes,
    bool? done,
  }) async {
    try {
      DocumentReference<Map<String, dynamic>> docRef = _firestore.collection(_collection).doc(taskId);
      Map<String, dynamic> updates = <String, dynamic>{};

      if (familyCode != null) updates['familyCode'] = familyCode;
      if (title != null) updates['title'] = title.trim();
      if (type != null) updates['type'] = type;
      if (dueDate != null) updates['dueDate'] = dueDate;
      if (notes != null) updates['notes'] = notes;
      if (done != null) updates['done'] = done;

      if (updates.isNotEmpty) {
        await docRef.update(updates);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa atualizada com sucesso ($type): $title')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao editar tarefa: $e')));
    }
  }

  static Future<void> toggleDone(String taskId, bool currentValue, {required BuildContext context}) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({'done': !currentValue});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status de conclusão alterado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao atualizar status da tarefa: $e')));
    }
  }

  static Future<void> deleteTask(String taskId, {required BuildContext context}) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tarefa excluída: $taskId')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir tarefa: $e')));
    }
  }

  static Stream<List<Map<String, dynamic>>> streamTasksByPet(String petId) {
    return _firestore
        .collection(_collection)
        .where('petId', isEqualTo: petId)
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((query) => query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  static Future<List<Map<String, dynamic>>> getTasksByPet(String petId, {required BuildContext context}) async {
    try {
      QuerySnapshot<Map<String, dynamic>> query = await _firestore.collection(_collection).where('petId', isEqualTo: petId).orderBy('dueDate').get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar tarefas: $e')));
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getTaskById(String taskId) async {
    DocumentSnapshot<Map<String, dynamic>> doc = await _firestore.collection(_collection).doc(taskId).get();
    return doc.exists ? doc.data() : null;
  }
}
