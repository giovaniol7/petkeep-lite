import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_variables.dart';
import '../../core/date_input_formatter.dart';
import '../../core/weight_input_formatter.dart';
import '../../providers/pet_provider.dart';
import '../../services/auth_service.dart';
import '../../services/pet_service.dart';
import '../../services/storage_service.dart';
import '../pet_detail/pet_detail_page.dart';

class PetsListPage extends StatefulWidget {
  const PetsListPage({super.key});

  @override
  State<PetsListPage> createState() => _PetsListPageState();
}

class _PetsListPageState extends State<PetsListPage> {
  Future<void> _addPet() async {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController speciesCtrl = TextEditingController();
    TextEditingController birthCtrl = TextEditingController();
    TextEditingController weightCtrl = TextEditingController();
    File? photo;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Novo Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: speciesCtrl,
                  decoration: const InputDecoration(labelText: 'Espécie'),
                ),
                TextField(
                  controller: birthCtrl,
                  decoration: const InputDecoration(labelText: 'Data de Nascimento'),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(10),
                    DateInputFormatter(),
                  ],
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: weightCtrl,
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(6),
                    WeightInputFormatter(),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setState(() {
                        photo = File(picked.path);
                      });
                    }
                  },
                  icon: const Icon(Icons.photo),
                  label: const Text('Selecionar Foto'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                String name = nameCtrl.text.trim();
                String species = speciesCtrl.text.trim();
                String birth = birthCtrl.text.trim();
                double weight = double.tryParse(weightCtrl.text) ?? 0.0;
                if (name.isEmpty || species.isEmpty || birth.isEmpty || weight <= 0) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos corretamente.')));
                  return;
                }
                if (photo == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma foto do pet.')));
                  return;
                }
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                try {
                  await PetService.addPet(
                    context: context,
                    name: name,
                    species: species,
                    birthDate: birth,
                    weightKg: weight,
                    familyCode: AppVariables.familyCode ?? '',
                    photoFile: photo,
                  );
                  if (mounted) Navigator.pop(context);
                  if (mounted) Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet cadastrado com sucesso!')));
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar pet: $e')));
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Pets'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Atualizar', onPressed: () => setState(() {})),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sair'),
                  content: Text('Deseja realmente sair?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sair')),
                  ],
                ),
              );
              if (confirm == true) {
                Navigator.of(context).pop();
                AuthService.signOut(context);
              }
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          AsyncValue<List<Map<String, dynamic>>> petsAsync = ref.watch(petsProvider(AppVariables.familyCode!));
          return petsAsync.when(
            data: (pets) {
              if (pets.isEmpty) {
                return const Center(child: Text('Nenhum pet cadastrado.'));
              }
              return ListView.builder(
                itemCount: pets.length,
                itemBuilder: (context, i) {
                  Map<String, dynamic> pet = pets[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage: pet['photoUrl'] != null && pet['photoUrl'].isNotEmpty
                            ? NetworkImage(pet['photoUrl'])
                            : const AssetImage('assets/images/pet_placeholder.png') as ImageProvider,
                      ),
                      title: Text(pet['name']),
                      subtitle: Text('${pet['species']} • ${pet['weightKg']} kg'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailPage(petId: pet['id'], petName: pet['name']),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPet,
        icon: const Icon(Icons.add),
        label: const Text('Novo Pet'),
      ),
    );
  }
}
