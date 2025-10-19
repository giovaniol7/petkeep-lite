import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_service.dart';

final tasksByPetProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, petId) {
  return TaskService.streamTasksByPet(petId);
});