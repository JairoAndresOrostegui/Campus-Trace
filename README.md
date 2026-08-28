# Bitácora Pedagógica

Campus-Trace es una aplicación Flutter para crear, diligenciar y evaluar
bitácoras pedagógicas. Usa Firebase para autenticación, datos, archivos,
notificaciones y funciones de administración.

## Funcionalidades

- Administración de usuarios con roles Administrador, Docente y Estudiante.
- Creación y duplicación de plantillas de bitácora.
- Secciones, subsecciones y campos configurables.
- Inscripción de estudiantes mediante código.
- Borradores, envío y bloqueo de respuestas.
- Comentarios, retroalimentación y calificación docente.
- Exportación de bitácoras a PDF.
- Fotografías de perfil y notificaciones push.
- Historial básico de acciones y descargas.

## Roles y acceso

- **Administrador:** gestiona usuarios sin restricción de sede o dominio de
  correo, y puede administrar todas las plantillas y entregas. También puede
  usar su propio UID como propietario docente desde **Bitácoras por docente**.
- **Docente:** administra únicamente las plantillas cuyo campo `createdBy`
  contiene su UID. Puede gestionar e incluir estudiantes de otras sedes para
  clases virtuales, pero no puede administrar usuarios Administrador.
- **Estudiante:** puede inscribirse usando un código, editar su propio borrador
  y enviarlo. Una entrega enviada solo puede ser desbloqueada por el docente
  asignado o un administrador.

Las comprobaciones de interfaz no sustituyen la seguridad. La autorización
efectiva está definida en `firestore.rules`, `storage.rules` y las Cloud
Functions.

## Acceso y correos

Los usuarios creados desde el módulo administrativo no reciben el número de
documento como contraseña. El sistema crea la cuenta con una contraseña
aleatoria no conocida y envía un enlace personal para definirla.

Cuando un administrador o docente autorizado cambia un correo:

1. La Cloud Function actualiza el mismo UID en Firebase Authentication.
2. Actualiza el perfil correspondiente en Firestore.
3. Envía al nuevo correo un enlace para configurar la contraseña.

La lista de usuarios y el formulario de edición permiten reenviar manualmente
el enlace de acceso. El envío usa la colección `mail` y la instancia activa
`firestore-send-email-s603` de la extensión **Trigger Email**. Su manifiesto se
conserva en `firebase.json` y `extensions/firestore-send-email-s603.env`; la
contraseña SMTP permanece como referencia segura a Secret Manager.

Los estudiantes que se registran por sí mismos eligen una contraseña de al
menos ocho caracteres y reciben el enlace normal de verificación de Firebase.

## Tecnologías

- Flutter y Dart.
- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage.
- Firebase Cloud Messaging.
- Cloud Functions para Firebase, Node.js 22 y TypeScript.
- Provider para estado de sesión.

## Estructura

```text
lib/
  auth/       autenticación, guards y layouts por rol
  core/       configuración compartida y acceso a Storage
  features/   plantillas, entregas, evaluación y PDF
  profile/    perfil y fotografía
  providers/  estado global del usuario
  user/       administración de usuarios
  utils/      validaciones, colores y notificaciones
test/         pruebas unitarias y de widgets
functions/    Cloud Functions TypeScript
assets/       fuentes y recursos estáticos
```

## Configuración local

Requisitos:

- Flutter compatible con Dart `^3.9.0`.
- Node.js 22 para `functions/`.
- Firebase CLI y FlutterFire CLI.
- Un proyecto Firebase con Authentication por correo/contraseña habilitado.

Instala las dependencias:

```bash
flutter pub get
cd functions
npm install
cd ..
```

Si se trabaja con otro proyecto Firebase, genera su configuración local:

```bash
flutterfire configure
```

Los archivos nativos `google-services.json` y `GoogleService-Info.plist` están
ignorados por Git y deben generarse o descargarse para cada entorno.

## Desarrollo y validación

```bash
flutter run -d chrome
flutter analyze
flutter test
cd functions && npm run lint && npm run build
```

Las reglas incluyen pruebas de autorización para los tres roles:

```bash
firebase emulators:exec --only firestore "npm --prefix functions run test:rules"
```

## Despliegue

Compila la aplicación web:

```bash
flutter build web
firebase deploy --only hosting
firebase deploy --only extensions
```

Despliega backend, reglas e índices:

```bash
firebase deploy --only functions
firebase deploy --only firestore:rules,firestore:indexes,storage
```

Después de cambiar funciones o reglas, ambos componentes deben desplegarse;
actualizar solamente la aplicación Flutter no activa esos cambios en Firebase.

Los pushes a `main` ejecutan `.github/workflows/deploy-hostinger.yml`: valida y
compila la aplicación y publica el contenido web en la rama
`hostinger-deploy`, utilizada para mantener el alojamiento de Hostinger.

## Pruebas

Las pruebas actuales cubren modelos, normalización de respuestas, utilidades de
color y el enrutamiento inicial. Los cambios en reglas de seguridad deben
acompañarse de casos en Firebase Emulator Suite para estudiantes, docentes y
administradores.
