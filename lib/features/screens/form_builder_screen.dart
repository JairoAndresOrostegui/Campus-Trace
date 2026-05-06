import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../models/form_template.dart';
import '../services/form_template_service.dart';
import '../widgets/header_editor.dart';
import '../widgets/section_list_editor.dart';
import 'form_preview_screen.dart';
import 'form_teacher_dashboard_screen.dart';

class FormBuilderScreen extends StatefulWidget {
  final String? templateId;
  const FormBuilderScreen({super.key, this.templateId});

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _svc = FormTemplateService();

  // selección actual
  String? _selectedId;
  Stream<FormTemplate>? _selectedStream;

  // listado
  Stream<List<FormTemplate>>? _listStream;
  List<FormTemplate> _templates = [];

  // UI
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initList();
  }

  void _initList() {
    final uid = context.read<UserProvider>().user!.id;
    _listStream = _svc.watchTemplatesByUser(uid);

    // si vino un id inicial, precargar stream
    _selectedId = widget.templateId;
    if (_selectedId != null) {
      _selectedStream = _svc.watchTemplate(_selectedId!);
    }
    setState(() {});
  }

  void _selectTemplate(String id) {
    setState(() {
      _selectedId = id;
      _selectedStream = _svc.watchTemplate(id);
    });
  }

  // ======= PICKER ARRIBA (DIÁLOGO EN LA PARTE SUPERIOR) =======
  Future<void> _openPicker(List<FormTemplate> items) async {
    final primary = Theme.of(context).colorScheme.primary;
    final TextEditingController search = TextEditingController();
    List<FormTemplate> filtered = List.of(items);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topCenter,
          child: Dialog(
            insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (ctx, setMState) {
                void applyFilter(String q) {
                  final query = q.trim().toLowerCase();
                  setMState(() {
                    filtered = items.where((t) {
                      final title = t.header.title.toLowerCase();
                      final code = t.code.toLowerCase();
                      final group = t.groupName.toLowerCase();
                      return title.contains(query) ||
                          code.contains(query) ||
                          group.contains(query);
                    }).toList();
                  });
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                      maxHeight: 520,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: search,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Buscar por título, código o grupo...',
                            prefixIcon: Icon(Icons.search, color: primary),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onChanged: applyFilter,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(child: Text('Sin resultados'))
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => Divider(
                                    color: primary.withValues(alpha: .12),
                                  ),
                                  itemBuilder: (_, i) {
                                    final t = filtered[i];
                                    return ListTile(
                                      title: Text(t.header.title),
                                      subtitle: Text(
                                        '#${t.code}  •  ${t.groupName.isEmpty ? "—" : t.groupName}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Panel del docente',
                                            icon: const Icon(
                                              Icons.dashboard_customize,
                                            ),
                                            onPressed: () {
                                              // Cierra el picker y abre el panel
                                              Navigator.pop(ctx);
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FormTeacherDashboardScreen(
                                                        templateId: t.id,
                                                      ),
                                                ),
                                              );
                                            },
                                          ),
                                          if (_selectedId == t.id)
                                            Icon(Icons.check, color: primary),
                                        ],
                                      ),

                                      onTap: () {
                                        Navigator.pop(ctx);
                                        setState(() => _busy = true);
                                        Future.delayed(
                                          const Duration(milliseconds: 50),
                                          () {
                                            _selectTemplate(t.id);
                                            if (mounted) {
                                              setState(() => _busy = false);
                                            }
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ======= DIALOGO "CREAR NUEVO" (grupo + fechas) =======
  Future<void> _showNewTemplateDialog() async {
    final primary = Theme.of(context).colorScheme.primary;
    final groupCtl = TextEditingController();
    DateTime? dStart;
    DateTime? dEnd;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topCenter,
          child: Dialog(
            insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (ctx, setMState) {
                String _fmt(DateTime? d) {
                  if (d == null) return 'Seleccionar…';
                  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Crear nueva plantilla',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: groupCtl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del grupo',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event),
                                label: Text('Inicio: ${_fmt(dStart)}'),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dStart ?? now,
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 3),
                                    helpText: 'Fecha de inicio',
                                  );
                                  if (picked != null) {
                                    setMState(() {
                                      dStart = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        0,
                                        0,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event_available),
                                label: Text('Fin: ${_fmt(dEnd)}'),
                                onPressed: () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: dEnd ?? (dStart ?? now),
                                    firstDate: DateTime(now.year - 1),
                                    lastDate: DateTime(now.year + 3),
                                    helpText: 'Fecha de fin',
                                  );
                                  if (picked != null) {
                                    setMState(() {
                                      dEnd = DateTime(
                                        picked.year,
                                        picked.month,
                                        picked.day,
                                        23,
                                        59,
                                        59,
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
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
                              icon: const Icon(Icons.check),
                              label: const Text('Crear'),
                              onPressed: () async {
                                final group = groupCtl.text.trim();
                                if (group.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'El nombre de grupo es obligatorio',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (dStart == null || dEnd == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Selecciona fechas de inicio y fin',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (dEnd!.isBefore(dStart!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La fecha fin debe ser posterior al inicio',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(ctx); // cerrar dialogo
                                setState(() => _busy = true);
                                try {
                                  final uid = context
                                      .read<UserProvider>()
                                      .user!
                                      .id;
                                  final newId = await _svc.createTemplate(
                                    createdBy: uid,
                                    initialTitle: 'Bitácora pedagógica',
                                    groupName: group,
                                    formStart: dStart,
                                    formEnd: dEnd,
                                  );
                                  _selectTemplate(newId);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'No se pudo crear la plantilla: $e',
                                      ),
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _errorCard(String msg, {VoidCallback? onRetry}) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: .15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Error',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(msg, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Constructor de formulario'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_selectedId != null)
            IconButton(
              tooltip: 'Panel del docente',
              icon: const Icon(Icons.dashboard_customize),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        FormTeacherDashboardScreen(templateId: _selectedId!),
                  ),
                );
              },
            ),
          if (_selectedId != null)
            IconButton(
              tooltip: 'Previsualizar',
              icon: const Icon(Icons.visibility),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FormPreviewScreen(templateId: _selectedId!),
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<FormTemplate>>(
          stream: _listStream,
          builder: (context, listSnap) {
            if (listSnap.hasError) {
              return _errorCard(
                'No se pudieron cargar las plantillas.\n${listSnap.error}',
                onRetry: () => setState(_initList),
              );
            }
            if (!listSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            _templates = listSnap.data!;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _TopPickerBar(
                      templates: _templates,
                      selectedId: _selectedId,
                      onPick: () => _openPicker(_templates),
                      onCreateNew: _showNewTemplateDialog,
                    ),
                    const SizedBox(height: 16),

                    if (_selectedStream == null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primary.withValues(alpha: .12),
                          ),
                        ),
                        child: const Text(
                          'Selecciona una plantilla o crea una nueva para continuar.',
                        ),
                      )
                    else
                      StreamBuilder<FormTemplate>(
                        stream: _selectedStream,
                        builder: (context, snap) {
                          if (snap.hasError) {
                            return _errorCard(
                              'No se pudo cargar la plantilla seleccionada.\n${snap.error}',
                              onRetry: () {
                                if (_selectedId != null) {
                                  setState(() {
                                    _selectedStream = _svc.watchTemplate(
                                      _selectedId!,
                                    );
                                  });
                                }
                              },
                            );
                          }
                          if (!snap.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final t = snap.data!;
                          return Column(
                            children: [
                              HeaderEditor(templateId: t.id, template: t),
                              const SizedBox(height: 16),

                              // Fase 2: editor de secciones (placeholder)
                              SectionsEditor(
                                templateId: t.id,
                                sections: t.sections,
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),

                // Overlay de carga/bloqueo
                if (_busy)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.08),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: primary),
                              const SizedBox(height: 12),
                              const Text('Cargando...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopPickerBar extends StatelessWidget {
  const _TopPickerBar({
    required this.templates,
    required this.selectedId,
    required this.onPick,
    required this.onCreateNew,
  });

  final List<FormTemplate> templates;
  final String? selectedId;
  final VoidCallback onPick;
  final Future<void> Function() onCreateNew;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // plantilla seleccionada (si hay)
    FormTemplate? selected;
    if (selectedId != null) {
      for (final t in templates) {
        if (t.id == selectedId) {
          selected = t;
          break;
        }
      }
    }

    final hasSelection = selectedId != null && selected != null;

    return Row(
      children: [
        // "Selector con buscador": caja clickeable que abre el modal con búsqueda
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: .15)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [primary.withValues(alpha: .06), Colors.white],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSelection
                              ? selected.header.title
                              : 'Selecciona una plantilla…',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasSelection)
                          Text(
                            '#${selected.code}  •  ${selected.groupName.isEmpty ? "—" : selected.groupName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: .6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.search, color: primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        FilledButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.add),
          label: const Text('Crear nuevo'),
        ),
      ],
    );
  }
}
