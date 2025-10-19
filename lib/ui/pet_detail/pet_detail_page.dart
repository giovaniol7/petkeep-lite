import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_variables.dart';
import '../../core/date_input_formatter.dart';
import '../../core/weight_input_formatter.dart';
import '../../providers/task_provider.dart';
import '../../services/pet_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_service.dart';

class PetDetailPage extends StatefulWidget {
  final String petId;
  final String petName;

  const PetDetailPage({super.key, required this.petId, required this.petName});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  Map<String, dynamic>? petData;
  bool loadingPet = true;

  Future<void> _editPet() async {
    TextEditingController nameCtrl = TextEditingController(text: petData!['name']);
    TextEditingController speciesCtrl = TextEditingController(text: petData!['species']);
    TextEditingController birthCtrl = TextEditingController(text: petData!['birthDate']);
    TextEditingController weightCtrl = TextEditingController(text: petData!['weightKg'].toString());
    File? photo;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Editar Pet'),
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
                  String? photoUrl = await StorageService.uploadPetPhoto(photo!, widget.petId);
                  if (photoUrl != null) {
                    await PetService.editPet(
                      context: context,
                      petId: widget.petId,
                      name: name,
                      species: species,
                      birthDate: birth,
                      weightKg: weight,
                      newPhoto: photoUrl,
                    );
                    if (mounted) Navigator.pop(context);
                    if (mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pet editado com sucesso!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao editar pet.')));
                  }
                } catch (e) {
                  if (mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao editar pet: $e')));
                }
              },
              child: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPetData();
  }

  Future<void> _loadPetData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore.instance.collection('pets').doc(widget.petId).get();
      if (doc.exists) {
        setState(() {
          petData = doc.data();
          loadingPet = false;
        });
      } else {
        setState(() {
          loadingPet = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar pet: $e');
      setState(() => loadingPet = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), tooltip: 'Avisar família', onPressed: _notifyFamily),
          IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar pet', onPressed: _editPet),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir pet',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Excluir pet'),
                  content: Text('Deseja realmente excluir "${petData!['name']}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                  ],
                ),
              );
              if (confirm == true) {
                PetService.deletePet(widget.petId, context: context);
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: loadingPet
          ? const Center(child: CircularProgressIndicator())
          : petData == null
          ? const Center(child: Text('Pet não encontrado.'))
          : Column(
              children: [
                _buildPetHeader(),
                const Divider(height: 1),
                Expanded(child: _buildTaskList()),
              ],
            ),
      floatingActionButton: FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add_task)),
    );
  }

  Widget _buildPetHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: petData?['photoUrl'] != null
                ? NetworkImage(petData!['photoUrl'])
                : const AssetImage('assets/images/pet_placeholder.png') as ImageProvider,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petData?['name'] ?? widget.petName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text('${petData?['species'] ?? 'Espécie desconhecida'}', style: Theme.of(context).textTheme.bodyMedium),
                if (petData?['birthDate'] != null)
                  Text(
                    'Nascimento: ${petData!['birthDate']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Consumer(
      builder: (context, ref, _) {
        final AsyncValue<List<Map<String, dynamic>>> tasksAsync = ref.watch(tasksByPetProvider(widget.petId));

        return tasksAsync.when(
          data: (tasks) => tasks.isEmpty
              ? const Center(child: Text('Nenhuma tarefa cadastrada.'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> t = tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: t['done'],
                          onChanged: (v) => TaskService.toggleDone(t['id'], t['done'], context: context),
                        ),
                        title: Text(t['title']),
                        subtitle: Text('${t['type']} • ${t['dueDate']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Excluir tarefa',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir tarefa'),
                                content: Text('Deseja realmente excluir "${t['title']}"?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await TaskService.deleteTask(t['id'], context: context);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erro ao carregar tarefas: $e')),
        );
      },
    );
  }

  Future<void> _addTask() async {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController notesCtrl = TextEditingController();
    String type = 'other';
    String date = DateTime.now().toIso8601String().split('T').first;
    await showDialog(
      context: context,
      builder: (ctx) {
        String type = 'other';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Tarefa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Título'),
                  ),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: type,
                    items: const [
                      DropdownMenuItem(value: 'vaccine', child: Text('Vacina')),
                      DropdownMenuItem(value: 'grooming', child: Text('Banho/Tosa')),
                      DropdownMenuItem(value: 'other', child: Text('Outros')),
                    ],
                    onChanged: (v) => setState(() => type = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () async {
                    await TaskService.addTask(
                      context: context,
                      petId: widget.petId,
                      familyCode: AppVariables.familyCode ?? '',
                      type: type,
                      title: titleCtrl.text,
                      dueDate: date,
                      notes: notesCtrl.text,
                    );
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _notifyFamily() async {
    try {
      FirebaseFunctions functions = FirebaseFunctions.instanceFor(region: 'southamerica-east1');
      HttpsCallable callable = functions.httpsCallable('notifyFamily');
      await callable.call({'petId': widget.petId, 'message': 'Nova tarefa/vacina adicionada para ${widget.petName}'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificação enviada à família!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar notificação: $e')));
    }
  }
}
