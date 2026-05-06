import 'package:flutter/material.dart';

import '../../../utils/parameters_service.dart';
import '../../../utils/validators.dart';
import '../../auth/models/user.dart';
import 'admin_photo_widget.dart';

class _ShrinkOneLine extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Alignment alignment;

  const _ShrinkOneLine(
    this.text, {
    this.style,
    required this.textAlign,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: textAlign,
            style: style,
          ),
        ),
      ),
    );
  }
}

class AdminUserFormBody extends StatelessWidget {
  final UserModel? usuario;
  final bool soloLectura;
  final bool esSuperadminActual;

  final String? fotoUrl;
  final VoidCallback onPickPhoto;

  // Requeridos
  final TextEditingController nombres;
  final TextEditingController apellidos;
  final TextEditingController correoInstitucional;

  // Documento
  final TextEditingController documento;
  final List<Parameter> documentTypes;
  final String? selectedDocumentType;
  final void Function(String?) onDocumentTypeChanged;

  // Rol y semestre
  final String rol;
  final List<Parameter> roles;
  final void Function(String?) onRolChanged;

  final int? semester;
  final void Function(int?) onSemesterChanged;

  // Opcionales (controllers)
  final TextEditingController institucion; // institution
  final TextEditingController sede; // campus (texto se sincroniza con dropdown)
  final TextEditingController
  carrera; // career (texto se sincroniza con dropdown)
  final TextEditingController telefonos; // lista separada por coma

  // Campus / Careers desde parameters (dropdowns)
  final List<Parameter> campusOptions;
  final String? selectedCampus;
  final void Function(String?) onCampusChanged;

  final List<Parameter> careerOptions;
  final String? selectedCareer;
  final void Function(String?) onCareerChanged;

  // Estado
  final String status; // 'activo' | 'inactivo'
  final void Function(String?) onStatusChanged;

  // Permisos
  final List<String> funcionalidades;
  final List<Parameter> allPermissions;
  final void Function(String permiso, bool? isChecked) onFuncionalidadChanged;

  // Aux
  final bool esNuevo;

  // Modalidad
  final String modality;
  final void Function(String?) onModalityChanged;

  const AdminUserFormBody({
    super.key,
    this.usuario,
    required this.soloLectura,
    required this.esSuperadminActual,
    this.fotoUrl,
    required this.onPickPhoto,
    required this.nombres,
    required this.apellidos,
    required this.correoInstitucional,
    required this.documento,
    required this.documentTypes,
    required this.selectedDocumentType,
    required this.onDocumentTypeChanged,
    required this.rol,
    required this.roles,
    required this.onRolChanged,
    required this.semester,
    required this.onSemesterChanged,
    required this.institucion,
    required this.sede,
    required this.carrera,
    required this.telefonos,
    required this.status,
    required this.onStatusChanged,
    required this.funcionalidades,
    required this.allPermissions,
    required this.onFuncionalidadChanged,
    required this.esNuevo,
    required this.campusOptions,
    required this.selectedCampus,
    required this.onCampusChanged,
    required this.careerOptions,
    required this.selectedCareer,
    required this.onCareerChanged,
    required this.modality,
    required this.onModalityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Parameter>> groupedPermissions = {};
    for (var perm in allPermissions) {
      final group = perm.etiqueta.split('.').first;
      groupedPermissions.putIfAbsent(group, () => []).add(perm);
    }

    final String? safeDocType =
        documentTypes.any((d) => d.valor == selectedDocumentType)
        ? selectedDocumentType
        : null;

    final String? safeRole = roles.any((r) => r.valor == rol) ? rol : null;

    final String? safeCampus =
        campusOptions.any((c) => c.valor == selectedCampus)
        ? selectedCampus
        : null;

    final String? safeCareer =
        careerOptions.any((c) => c.valor == selectedCareer)
        ? selectedCareer
        : null;

    final bool isStudent = (rol == 'Estudiante');

    return Column(
      children: [
        if (!esNuevo)
          ProfilePhotoWidget(
            imageUrl: fotoUrl,
            onTap: onPickPhoto,
            enableHoverEdit: !soloLectura,
          ),
        if (!esNuevo) const SizedBox(height: 16),

        // Nombres
        TextFormField(
          controller: nombres,
          decoration: const InputDecoration(labelText: 'Nombres'),
          readOnly: soloLectura,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Este campo es obligatorio'
              : null,
        ),
        const SizedBox(height: 8),

        // Apellidos
        TextFormField(
          controller: apellidos,
          decoration: const InputDecoration(labelText: 'Apellidos'),
          readOnly: soloLectura,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Este campo es obligatorio'
              : null,
        ),
        const SizedBox(height: 8),

        // Correo institucional
        TextFormField(
          controller: correoInstitucional,
          decoration: const InputDecoration(labelText: 'Correo Institucional'),
          readOnly: soloLectura,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            if (!Validators.isValidEmail(value)) {
              return 'El correo institucional no es válido';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),

        // Documento
        TextFormField(
          controller: documento,
          decoration: const InputDecoration(labelText: 'Nro. de documento'),
          readOnly: soloLectura,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            if (value.trim().length < 6) {
              return 'El documento debe tener mínimo 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),

        // Tipo de documento
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            label: _ShrinkOneLine(
              'Tipo de Documento',
              textAlign: TextAlign.left,
              alignment: Alignment.centerLeft,
            ),
          ),
          initialValue: safeDocType,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Seleccione un tipo de documento'),
            ),
            ...documentTypes.map(
              (type) => DropdownMenuItem<String>(
                value: type.valor,
                child: Text('${type.etiqueta} - ${type.valor}'),
              ),
            ),
          ],
          onChanged: soloLectura ? null : onDocumentTypeChanged,
          validator: (value) =>
              value == null ? 'El tipo de documento es obligatorio' : null,
        ),
        const SizedBox(height: 8),

        // Teléfonos (separados por coma)
        TextFormField(
          controller: telefonos,
          decoration: const InputDecoration(
            label: _ShrinkOneLine(
              'Teléfonos: si son varios se separan con ","',
              textAlign: TextAlign.left,
              alignment: Alignment.centerLeft,
            ),
          ),
          readOnly: soloLectura,
        ),
        const SizedBox(height: 8),

        // Rol
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Rol'),
          initialValue: safeRole,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Seleccione un rol'),
            ),
            ...roles.map(
              (r) => DropdownMenuItem<String>(
                value: r.valor,
                child: Text('${r.etiqueta} - ${r.valor}'),
              ),
            ),
          ],
          onChanged: soloLectura ? null : onRolChanged,
          validator: (value) => value == null ? 'El rol es obligatorio' : null,
        ),
        const SizedBox(height: 8),

        // Semestre (solo Estudiante). Para otros roles, no se muestra (se guarda 0).
        if (isStudent)
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Semestre'),
            initialValue: semester,
            items: List.generate(
              8,
              (i) => DropdownMenuItem<int>(
                value: i + 1,
                child: Text('Semestre ${i + 1}'),
              ),
            ),
            onChanged: soloLectura ? null : onSemesterChanged,
            validator: (value) =>
                value == null ? 'El semestre es obligatorio' : null,
          ),
        if (isStudent) const SizedBox(height: 8),

        // Estado
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Estado'),
          initialValue: status,
          items: const [
            DropdownMenuItem(value: 'activo', child: Text('Activo')),
            DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
          ],
          onChanged: soloLectura ? null : onStatusChanged,
          validator: (value) =>
              value == null ? 'El estado es obligatorio' : null,
        ),
        const SizedBox(height: 8),

        // Institución (texto)
        TextFormField(
          controller: institucion,
          readOnly: soloLectura || !esSuperadminActual,
          decoration: const InputDecoration(
            labelText: 'Institución',
            border: OutlineInputBorder(),
          ),
          validator: (value) => (value == null || value.isEmpty)
              ? 'Este campo es obligatorio'
              : null,
        ),
        const SizedBox(height: 8),

        // Sede (campus) DESDE parameters (dropdown). Si no es superadmin, no puede cambiarse.
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Sede',
            border: OutlineInputBorder(),
          ),
          initialValue: safeCampus,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Seleccione una sede'),
            ),
            ...campusOptions.map(
              (c) => DropdownMenuItem<String>(
                value: c.valor,
                child: Text(c.valor),
              ),
            ),
          ],
          onChanged: (soloLectura || !esSuperadminActual)
              ? null
              : onCampusChanged,
          validator: (value) => (value == null || value.isEmpty)
              ? 'Este campo es obligatorio'
              : null,
        ),
        const SizedBox(height: 8),

        // Programa (career) SOLO para Estudiante, desde parameters
        if (isStudent)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Programa',
              border: OutlineInputBorder(),
            ),
            initialValue: safeCareer,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Seleccione un programa'),
              ),
              ...careerOptions.map(
                (c) => DropdownMenuItem<String>(
                  value: c.valor,
                  child: Text(c.valor),
                ),
              ),
            ],
            onChanged: soloLectura ? null : onCareerChanged,
            validator: (value) =>
                value == null ? 'El programa es obligatorio' : null,
          ),
        if (isStudent) const SizedBox(height: 16),

        if (isStudent)
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Modalidad',
              border: OutlineInputBorder(),
            ),
            initialValue: (modality == 'virtual' || modality == 'presencial')
                ? modality
                : 'presencial',
            items: const [
              DropdownMenuItem(value: 'presencial', child: Text('Presencial')),
              DropdownMenuItem(value: 'virtual', child: Text('Virtual')),
            ],
            onChanged: soloLectura ? null : onModalityChanged,
            validator: (v) => v == null ? 'La modalidad es obligatoria' : null,
          ),
        if (isStudent) const SizedBox(height: 8),

        const Text(
          'Funcionalidades',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),

        ...groupedPermissions.entries.map((entry) {
          final groupName = entry.key;
          final permissionsInGroup = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _ShrinkOneLine(
                  groupName.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                  alignment: Alignment.centerLeft,
                ),
              ),
              Column(
                children: permissionsInGroup.map((perm) {
                  final isChecked = funcionalidades.contains(perm.valor);
                  return CheckboxListTile(
                    title: _ShrinkOneLine(
                      perm.valor,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.left,
                      alignment: Alignment.centerLeft,
                    ),
                    value: isChecked,
                    onChanged: soloLectura
                        ? null
                        : (bool? newValue) {
                            onFuncionalidadChanged(perm.valor, newValue);
                          },
                  );
                }).toList(),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}
