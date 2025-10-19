import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pet_service.dart';

final petsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, familyCode) async* {
  await for (final pets in PetService.streamPetsByFamily(familyCode)) {
    yield pets;
  }
});
