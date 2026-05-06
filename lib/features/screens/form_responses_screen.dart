import 'package:flutter/material.dart';

import '../services/form_entry_service.dart';

class FormResponsesScreen extends StatelessWidget {
  final String templateId;
  final String userId;

  const FormResponsesScreen({
    super.key,
    required this.templateId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final svc = FormEntryService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mis envíos'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: svc.watchMyEntries(userId: userId, templateId: templateId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = snap.data!;
            if (entries.isEmpty) {
              return const Center(child: Text('Aún no tienes envíos.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, __) =>
                  Divider(color: primary.withValues(alpha: .12)),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  title: Text('Envío ${i + 1}'),
                  subtitle: Text('Fecha: ${e.createdAt.toLocal()}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Respuestas (vista rápida)'),
                        content: SingleChildScrollView(
                          child: Text(
                            e.answers.entries
                                .map((kv) => '${kv.key}: ${kv.value}')
                                .join('\n'),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
