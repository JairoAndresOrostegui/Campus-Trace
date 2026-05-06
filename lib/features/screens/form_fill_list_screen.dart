import 'package:flutter/material.dart';

import '../models/form_template.dart';
import '../services/form_entry_service.dart';
import '../widgets/form_template_card.dart';

class FormFillListScreen extends StatefulWidget {
  final String uid;

  const FormFillListScreen({
    super.key,
    required this.uid,
  });

  @override
  State<FormFillListScreen> createState() => _FormFillListScreenState();
}

class _FormFillListScreenState extends State<FormFillListScreen> {
  final _entrySvc = FormEntryService();

  Future<void> _enrollDialog(BuildContext context) async {
    final primary = Theme.of(context).colorScheme.primary;
    final codeCtl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Dialog(
          insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Inscribirme con código',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtl,
                    decoration: const InputDecoration(
                      labelText: 'Código del formulario',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () async {
                          final code = codeCtl.text.trim();
                          final messenger = ScaffoldMessenger.of(context);

                          if (code.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Ingresa un código'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);

                          try {
                            await _entrySvc.enrollWithCode(
                              userId: widget.uid,
                              formCode: code,
                            );

                            if (!mounted) return;

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Inscripción exitosa'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('No se pudo inscribir: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Inscribirme'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Formularios disponibles'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Inscribirme con código',
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => _enrollDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<FormTemplate>>(
          stream: _entrySvc.watchTemplatesForStudent(widget.uid),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data!;
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No tienes formularios inscritos.'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _enrollDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Inscribirme con código'),
                    ),
                  ],
                ),
              );
            }

            // Tarjetas degradé (mismo estilo que usuarios/perfil)
            return ListView(
              padding: const EdgeInsets.all(16),
              children:
                  list.map((t) => FormTemplateCard(template: t)).toList(),
            );
          },
        ),
      ),
    );
  }
}
