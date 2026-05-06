import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user.dart';
import '../../providers/user_provider.dart';
import '../../user/services/user_service.dart';
import '../models/form_template.dart';
import '../services/form_template_service.dart';
import 'form_builder_screen.dart';

class AdminBitacoraScreen extends StatefulWidget {
  const AdminBitacoraScreen({super.key});

  @override
  State<AdminBitacoraScreen> createState() => _AdminBitacoraScreenState();
}

class _AdminBitacoraScreenState extends State<AdminBitacoraScreen> {
  final _userSvc = UserService();
  final _templateSvc = FormTemplateService();

  late Future<List<UserModel>> _teachersFuture;
  UserModel? _selectedTeacher;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<UserProvider>().user;
    _teachersFuture = _userSvc.obtenerDocentes(
      institutionId: current?.institution,
      campusId: current?.campus,
    );
  }

  String _teacherName(UserModel teacher) {
    final name = '${teacher.firstName} ${teacher.lastName}'.trim();
    return name.isEmpty ? teacher.institutionalEmail : name;
  }

  void _openBuilder({String? templateId}) {
    final teacher = _selectedTeacher;
    if (teacher == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormBuilderScreen(
          templateId: templateId,
          ownerUserId: teacher.id,
          ownerLabel: _teacherName(teacher),
          canDelete: true,
          canDuplicate: true,
        ),
      ),
    );
  }

  Future<void> _duplicate(FormTemplate template) async {
    final teacher = _selectedTeacher;
    if (teacher == null) return;

    setState(() => _busy = true);
    try {
      await _templateSvc.duplicateTemplate(
        sourceTemplateId: template.id,
        createdBy: teacher.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla duplicada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo duplicar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(FormTemplate template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text(
          'Se eliminara "${template.header.title}". Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _templateSvc.deleteTemplate(template.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plantilla eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bitacoras por docente'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_selectedTeacher != null)
            IconButton(
              tooltip: 'Crear plantilla',
              icon: const Icon(Icons.add),
              onPressed: () => _openBuilder(),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            FutureBuilder<List<UserModel>>(
              future: _teachersFuture,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('No se pudieron cargar docentes: ${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final teachers = snap.data!;
                if (teachers.isEmpty) {
                  return const Center(child: Text('No hay docentes activos.'));
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: DropdownButtonFormField<UserModel>(
                        initialValue: _selectedTeacher,
                        decoration: const InputDecoration(
                          labelText: 'Docente',
                          border: OutlineInputBorder(),
                        ),
                        items: teachers
                            .map(
                              (teacher) => DropdownMenuItem(
                                value: teacher,
                                child: Text(_teacherName(teacher)),
                              ),
                            )
                            .toList(),
                        onChanged: (teacher) {
                          setState(() => _selectedTeacher = teacher);
                        },
                      ),
                    ),
                    Expanded(child: _templatesList()),
                  ],
                );
              },
            ),
            if (_busy)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: .08),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _selectedTeacher == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openBuilder(),
              icon: const Icon(Icons.add),
              label: const Text('Crear'),
            ),
    );
  }

  Widget _templatesList() {
    final teacher = _selectedTeacher;
    if (teacher == null) {
      return const Center(child: Text('Selecciona un docente.'));
    }

    return StreamBuilder<List<FormTemplate>>(
      stream: _templateSvc.watchTemplatesByUser(teacher.id),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final templates = snap.data!;
        if (templates.isEmpty) {
          return const Center(child: Text('Este docente no tiene plantillas.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final template = templates[index];
            return _TemplateAdminTile(
              template: template,
              onEdit: () => _openBuilder(templateId: template.id),
              onDuplicate: () => _duplicate(template),
              onDelete: () => _delete(template),
            );
          },
        );
      },
    );
  }
}

class _TemplateAdminTile extends StatelessWidget {
  const _TemplateAdminTile({
    required this.template,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final FormTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: .14)),
        color: Colors.white,
      ),
      child: ListTile(
        title: Text(
          template.header.title.isEmpty ? 'Sin titulo' : template.header.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '#${template.code}  -  ${template.groupName.isEmpty ? "Sin grupo" : template.groupName}',
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Duplicar',
              icon: const Icon(Icons.copy),
              onPressed: onDuplicate,
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
