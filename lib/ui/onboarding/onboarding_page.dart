import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:petkeeper_lite/services/family_service.dart';

import '../../core/app_variables.dart';
import '../../core/uppercase_text_formatter.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final TextEditingController _code = TextEditingController();
  bool _isCreating = false;

  Future<void> _saveFamilyCode() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || _code.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha o código da família.')));
      return;
    }
    String code = _code.text.trim().toUpperCase();
    DocumentReference<Map<String, dynamic>> familyRef = FirebaseFirestore.instance.collection('families').doc(code);
    if (_isCreating) {
      await UserService.familyEnter(context: context, user: user, familyCode: code);
      await FamilyService.createFamily(familyCode: code);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Família "$code" criada e vinculada com sucesso!')));
    } else {
      DocumentSnapshot<Map<String, dynamic>> familyDoc = await familyRef.get();
      if (!familyDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('A família "$code" não existe.')));
        return;
      }
      await UserService.familyEnter(context: context, user: user, familyCode: code);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Família "$code" vinculada com sucesso!')));
    }
    if (mounted) {
      AppVariables.familyCode = code;
      Navigator.pushNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Família'),
        actions: [
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Código da família'),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [UpperCaseTextFormatter()],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(value: _isCreating, onChanged: (v) => setState(() => _isCreating = v!)),
                const Text('Criar nova família'),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _saveFamilyCode, child: const Text('Continuar')),
          ],
        ),
      ),
    );
  }
}
