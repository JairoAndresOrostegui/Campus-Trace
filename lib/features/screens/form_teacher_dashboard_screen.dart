import 'package:flutter/material.dart';

import '../models/form_entry.dart';
import '../models/form_template.dart';
import '../services/form_template_service.dart';
import '../services/form_entry_service.dart';
import 'form_fill_screen.dart'; // 👈 Reutilizamos la pantalla del estudiante en modo revisión

class FormTeacherDashboardScreen extends StatefulWidget {
  final String templateId;
  const FormTeacherDashboardScreen({super.key, required this.templateId});

  @override
  State<FormTeacherDashboardScreen> createState() =>
      _FormTeacherDashboardScreenState();
}

class _FormTeacherDashboardScreenState extends State<FormTeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _tmplSvc = FormTemplateService();

  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Panel del formulario'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tab,
          labelColor: primary,
          tabs: const [Tab(text: 'Inscritos')],
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<FormTemplate>(
          stream: _tmplSvc.watchTemplate(widget.templateId),
          builder: (context, tsnap) {
            if (!tsnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final template = tsnap.data!;

            return Column(
              children: [
                _headerCard(template),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _InscritosTab(
                        templateId: widget.templateId,
                        template: template,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard(FormTemplate t) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    String fmt(DateTime? d) {
      if (d == null) return '—';
      return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: .15)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary.withValues(alpha: .06), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            t.header.title.isEmpty ? 'Sin título' : t.header.title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _softChip(context, 'Código: ${t.code.isEmpty ? "—" : t.code}'),
                _softChip(
                  context,
                  'Grupo: ${t.groupName.isEmpty ? "—" : t.groupName}',
                ),
                _softChip(context, 'Inicio: ${fmt(t.header.formStart)}'),
                _softChip(context, 'Fin: ${fmt(t.header.formEnd)}'),
                _softChip(context, 'Estado: ${t.status.toUpperCase()}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _softChip(BuildContext context, String text) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .20)),
        color: c.withValues(alpha: .06),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.black.withValues(alpha: .75)),
      ),
    );
  }
}

class _InscritosTab extends StatefulWidget {
  final String templateId;
  final FormTemplate template;
  const _InscritosTab({required this.templateId, required this.template});

  @override
  State<_InscritosTab> createState() => _InscritosTabState();
}

class _InscritosTabState extends State<_InscritosTab> {
  final _svc = FormEntryService();

  // 🔹 Filtro por modalidad (presencial | virtual). Default: presencial
  String _modalityFilter = 'presencial';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    // 1) stream de inscritos
    return StreamBuilder<List<EnrollmentInfo>>(
      stream: _svc.streamEnrollmentsForTemplate(widget.templateId),
      builder: (context, esnap) {
        if (esnap.hasError) {
          return Center(child: Text('Error: ${esnap.error}'));
        }
        if (!esnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final enrolls = esnap.data!;
        if (enrolls.isEmpty) {
          return const Center(child: Text('Aún no hay estudiantes inscritos.'));
        }

        final userIds = enrolls.map((e) => e.userId).toList();

        // 2) en paralelo, stream de entregas (para marcar “Entregado”)
        return StreamBuilder<List<FormEntry>>(
          stream: _svc.streamEntriesForTemplate(widget.templateId),
          builder: (context, xsnap) {
            final deliveredSet = <String>{};
            if (xsnap.hasData) {
              for (final e in xsnap.data!) {
                deliveredSet.add(e.userId);
              }
            }

            // 3) traemos nombres/correos + modalidad (una sola vez por build)
            return FutureBuilder<Map<String, UserBasic>>(
              future: _svc.fetchUsersBasicByIds(userIds),
              builder: (context, usnap) {
                final users = usnap.data ?? const <String, UserBasic>{};

                // Conteos por modalidad para mostrar en los chips
                int presencialCount = 0;
                int virtualCount = 0;
                for (final e in enrolls) {
                  final mod = (users[e.userId]?.modality ?? 'presencial')
                      .toLowerCase();
                  if (mod == 'virtual') {
                    virtualCount++;
                  } else {
                    presencialCount++;
                  }
                }

                // Filtrar según modalidad seleccionada
                final filtered = enrolls.where((e) {
                  final mod = (users[e.userId]?.modality ?? 'presencial')
                      .toLowerCase();
                  return mod == _modalityFilter.toLowerCase();
                }).toList();

                return Column(
                  children: [
                    // ===== Barra de filtro por modalidad =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              selected: _modalityFilter == 'presencial',
                              label: Text('Presencial ($presencialCount)'),
                              onSelected: (v) {
                                if (v) {
                                  setState(
                                    () => _modalityFilter = 'presencial',
                                  );
                                }
                              },
                            ),
                            ChoiceChip(
                              selected: _modalityFilter == 'virtual',
                              label: Text('Virtual ($virtualCount)'),
                              onSelected: (v) {
                                if (v) {
                                  setState(() => _modalityFilter = 'virtual');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== Lista filtrada =====
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final enr = filtered[i];
                          final ub = users[enr.userId];
                          final delivered = deliveredSet.contains(enr.userId);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primary.withValues(alpha: .15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    primary.withValues(alpha: .06),
                                    Colors.white,
                                  ],
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  (ub == null)
                                      ? enr.userId
                                      : '${ub.firstName} ${ub.lastName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (ub?.email.isNotEmpty == true)
                                      Text(ub!.email),
                                    Text(
                                      'Modalidad: ${(ub?.modality ?? 'presencial').toUpperCase()}',
                                      style: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: .65,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: _statusChip(context, delivered),
                                onTap: () =>
                                    _openStudentReview(context, enr.userId),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, bool delivered) {
    final c = delivered ? Colors.green : Colors.orange;
    final txt = delivered ? 'Entregado' : 'Sin entregar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .30)),
        color: c.withValues(alpha: .08),
      ),
      child: Text(
        txt,
        style: TextStyle(color: Colors.black.withValues(alpha: .75)),
      ),
    );
  }

  // 🚀 Navegación directa al form en modo revisión
  void _openStudentReview(BuildContext context, String studentId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormFillScreen(
          templateId: widget.templateId,
          reviewMode: true,
          reviewStudentId: studentId,
        ),
      ),
    );
  }
}
