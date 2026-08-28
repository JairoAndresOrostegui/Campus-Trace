import {randomBytes} from "node:crypto";
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getAuth, UserRecord} from "firebase-admin/auth";
import {getMessaging} from "firebase-admin/messaging";
import {getFirestore} from "firebase-admin/firestore";

initializeApp();
setGlobalOptions({region: "us-central1", maxInstances: 10});

interface NotifData {
  tokens?: string[];
  titulo?: string;
  cuerpo?: string;
}

interface UserPayload {
  uid?: string;
  user?: Record<string, unknown>;
}

interface DeleteUserData {
  uid?: string;
}

interface AccessLinkData {
  uid?: string;
}

interface CallerProfile {
  role: string;
  permissions: string[];
  institution: string;
  campus: string;
}

const validRoles = new Set(["Estudiante", "Docente", "Administrador"]);
const portalUrl = "https://bitacorapedagogica.com/";
const editableProfileFields = [
  "firstName",
  "lastName",
  "institutionalEmail",
  "semester",
  "role",
  "modality",
  "career",
  "campus",
  "institution",
  "phones",
  "status",
  "fcmToken",
  "documentType",
  "documentNumber",
  "photoUrl",
  "permissions",
] as const;

/**
 * Reads and validates a required string field.
 * @param {Record<string, unknown>} data Input data.
 * @param {string} field Required field name.
 * @return {string} Trimmed field value.
 */
function requiredString(
  data: Record<string, unknown>,
  field: string
): string {
  const value = data[field];
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `Campo invalido: ${field}.`);
  }
  return value.trim();
}

/**
 * Returns only string values from an unknown list.
 * @param {unknown} value Potential list.
 * @return {string[]} Valid string values.
 */
function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

/**
 * Normalizes profile fields accepted from callable clients.
 * @param {Record<string, unknown>} data Raw profile.
 * @param {boolean} requireInstitutionalDomain Whether @udi.edu.co is required.
 * @return {Record<string, unknown>} Validated profile.
 */
function normalizeProfile(
  data: Record<string, unknown>,
  requireInstitutionalDomain: boolean
) {
  const profile: Record<string, unknown> = {};
  for (const field of editableProfileFields) {
    if (Object.prototype.hasOwnProperty.call(data, field)) {
      profile[field] = data[field];
    }
  }

  profile.firstName = requiredString(data, "firstName");
  profile.lastName = requiredString(data, "lastName");
  profile.institutionalEmail = requiredString(
    data,
    "institutionalEmail"
  ).toLowerCase();
  profile.role = requiredString(data, "role");
  profile.status = requiredString(data, "status");
  profile.permissions = stringList(data.permissions);
  profile.phones = stringList(data.phones);

  const email = profile.institutionalEmail as string;
  const role = profile.role as string;
  if (requireInstitutionalDomain && !email.endsWith("@udi.edu.co")) {
    throw new HttpsError(
      "invalid-argument",
      "El correo debe pertenecer al dominio @udi.edu.co."
    );
  }
  if (!validRoles.has(role)) {
    throw new HttpsError("invalid-argument", "Rol invalido.");
  }
  return profile;
}

/**
 * Loads the active caller profile used for authorization.
 * @param {string} uid Authenticated UID.
 * @return {Promise<CallerProfile>} Active caller profile.
 */
async function getCallerProfile(uid: string): Promise<CallerProfile> {
  const snap = await getFirestore().collection("users").doc(uid).get();
  const data = snap.data();
  if (!data || data.status !== "activo" || typeof data.role !== "string") {
    throw new HttpsError("permission-denied", "Usuario sin permisos.");
  }
  return {
    role: data.role,
    permissions: stringList(data.permissions),
    institution: typeof data.institution === "string" ? data.institution : "",
    campus: typeof data.campus === "string" ? data.campus : "",
  };
}

/**
 * Requires an authenticated caller with one of the allowed roles.
 * @param {string | undefined} uid Authenticated UID.
 * @param {string[]} allowedRoles Accepted roles.
 * @return {Promise<CallerProfile>} Authorized caller.
 */
async function requireRole(
  uid: string | undefined,
  allowedRoles: string[]
): Promise<CallerProfile> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Debe iniciar sesion.");
  }
  const caller = await getCallerProfile(uid);
  if (!allowedRoles.includes(caller.role)) {
    throw new HttpsError("permission-denied", "Rol no autorizado.");
  }
  return caller;
}

/**
 * Requires permission to execute a user-management operation.
 * @param {string | undefined} uid Authenticated UID.
 * @param {string} permission Required permission.
 * @return {Promise<CallerProfile>} Authorized caller.
 */
async function requireUserPermission(
  uid: string | undefined,
  permission: string
): Promise<CallerProfile> {
  const caller = await requireRole(uid, ["Administrador", "Docente"]);
  if (
    caller.role !== "Administrador" &&
    !caller.permissions.includes(permission)
  ) {
    throw new HttpsError("permission-denied", "Permiso no autorizado.");
  }
  return caller;
}

/**
 * Restricts teacher management to non-admin users without privilege changes.
 * @param {CallerProfile} caller Authorized caller.
 * @param {Record<string, unknown>} profile Requested profile.
 * @param {Record<string, unknown>} existing Current profile, if any.
 */
function validateTeacherScope(
  caller: CallerProfile,
  profile: Record<string, unknown>,
  existing?: Record<string, unknown>
) {
  if (caller.role !== "Docente") return;

  const targetRole = existing?.role ?? profile.role;
  if (targetRole === "Administrador" || profile.role === "Administrador") {
    throw new HttpsError(
      "permission-denied",
      "Un docente no puede administrar usuarios Administrador."
    );
  }
  if (existing) {
    profile.role = existing.role;
    profile.permissions = existing.permissions ?? [];
    profile.institution = existing.institution;
    profile.campus = existing.campus;
  } else {
    profile.permissions = stringList(profile.permissions).filter(
      (permission) => permission === "bitacora.ver"
    );
  }
}

/**
 * Escapes user-provided values before rendering an email.
 * @param {string} value Raw value.
 * @return {string} HTML-safe value.
 */
function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

/**
 * Builds the password setup email.
 * @param {string} name Recipient name.
 * @param {string} email Recipient email.
 * @param {string} link Firebase password action link.
 * @return {string} Rendered HTML.
 */
function buildAccessHtml(name: string, email: string, link: string): string {
  const safeName = escapeHtml(name);
  const safeEmail = escapeHtml(email);
  const safeLink = escapeHtml(link);
  const safePortal = escapeHtml(portalUrl);
  return [
    "<!doctype html><html lang='es'><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>",
    "<style>",
    "body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;",
    "line-height:1.6;margin:0;background:#fff;color:#222}",
    ".wrap{max-width:680px;margin:0 auto;padding:24px}",
    ".card{border:1px solid #ddd;border-radius:12px;padding:18px}",
    ".btn{display:inline-block;background:#1e3a8a;color:#fff;",
    "padding:10px 16px;border-radius:10px;text-decoration:none}",
    "</style></head><body><main class='wrap'><div class='card'>",
    `<h1>Acceso a Campus-Trace</h1><p>Hola ${safeName},</p>`,
    "<p>Usa el siguiente enlace personal para definir o restablecer tu ",
    "contrasena. El numero de documento no se usa como contrasena.</p>",
    `<p><a class='btn' href='${safeLink}'>Configurar contrasena</a></p>`,
    `<p><strong>Usuario:</strong> ${safeEmail}</p>`,
    `<p>Despues ingresa desde <a href='${safePortal}'>${safePortal}</a>.</p>`,
    "<p>Si no solicitaste este acceso, puedes ignorar el mensaje.</p>",
    "</div></main></body></html>",
  ].join("");
}

/**
 * Generates and queues a password setup link for an existing user.
 * @param {UserRecord} user Firebase Authentication user.
 * @param {string} name Recipient name.
 * @return {Promise<void>} Resolves after queuing the email.
 */
async function enqueueAccessLink(
  user: UserRecord,
  name: string
): Promise<void> {
  if (!user.email) {
    throw new HttpsError("failed-precondition", "El usuario no tiene correo.");
  }
  const link = await getAuth().generatePasswordResetLink(user.email);
  await getFirestore().collection("mail").add({
    to: user.email,
    message: {
      subject: "Configura tu acceso a Campus-Trace",
      html: buildAccessHtml(name, user.email, link),
    },
  });
}

export const enviarNotificacion = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Docente", "Administrador"]);
  const data = (request.data ?? {}) as NotifData;
  const tokens = data.tokens;
  if (!Array.isArray(tokens) || tokens.length === 0 || tokens.length > 500) {
    throw new HttpsError(
      "invalid-argument",
      "Debe proporcionar entre 1 y 500 tokens."
    );
  }
  try {
    const response = await getMessaging().sendEachForMulticast({
      notification: {title: data.titulo, body: data.cuerpo},
      tokens,
    });
    return {exitosos: response.successCount, fallidos: response.failureCount};
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Error de envio.";
    throw new HttpsError("internal", message);
  }
});

export const crearUsuarioDesdeAdmin = onCall(async (request) => {
  const caller = await requireUserPermission(
    request.auth?.uid,
    "usuarios.crear"
  );
  const data = (request.data ?? {}) as UserPayload;
  if (!data.user) {
    throw new HttpsError("invalid-argument", "Faltan datos del usuario.");
  }
  const profile = normalizeProfile(
    data.user,
    caller.role !== "Administrador"
  );
  validateTeacherScope(caller, profile);

  const email = profile.institutionalEmail as string;
  const displayName = `${profile.firstName} ${profile.lastName}`.trim();
  let created: UserRecord | undefined;
  try {
    created = await getAuth().createUser({
      email,
      password: randomBytes(32).toString("base64url"),
      displayName,
      emailVerified: true,
      disabled: profile.status !== "activo",
    });
    await getFirestore().collection("users").doc(created.uid).set(profile);
    const shouldSendLink = profile.status === "activo";
    if (shouldSendLink) {
      await enqueueAccessLink(created, displayName);
    }
    return {
      exito: true,
      uid: created.uid,
      enlaceEnviado: shouldSendLink,
    };
  } catch (error: unknown) {
    if (created) {
      await getAuth().deleteUser(created.uid).catch(() => undefined);
      await getFirestore().collection("users").doc(created.uid).delete()
        .catch(() => undefined);
    }
    const message = error instanceof Error ? error.message : "Error de alta.";
    throw new HttpsError("internal", message);
  }
});

export const actualizarUsuarioDesdeAdmin = onCall(async (request) => {
  const caller = await requireUserPermission(
    request.auth?.uid,
    "usuarios.editar"
  );
  const data = (request.data ?? {}) as UserPayload;
  if (!data.uid || !data.user) {
    throw new HttpsError("invalid-argument", "Faltan UID o datos del usuario.");
  }

  const ref = getFirestore().collection("users").doc(data.uid);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Usuario no encontrado.");
  }
  const previousProfile = snapshot.data() as Record<string, unknown>;
  const profile = normalizeProfile(
    data.user,
    caller.role !== "Administrador"
  );
  validateTeacherScope(caller, profile, previousProfile);

  const auth = getAuth();
  const previousAuth = await auth.getUser(data.uid);
  const email = profile.institutionalEmail as string;
  const displayName = `${profile.firstName} ${profile.lastName}`.trim();
  const emailChanged = previousAuth.email?.toLowerCase() !== email;

  try {
    const updatedAuth = await auth.updateUser(data.uid, {
      email,
      displayName,
      emailVerified: emailChanged ? true : previousAuth.emailVerified,
      disabled: profile.status !== "activo",
    });
    await ref.set(profile, {merge: true});
    if (emailChanged && profile.status === "activo") {
      await enqueueAccessLink(updatedAuth, displayName);
    }
    return {
      exito: true,
      enlaceEnviado: emailChanged && profile.status === "activo",
    };
  } catch (error: unknown) {
    await auth.updateUser(data.uid, {
      email: previousAuth.email,
      displayName: previousAuth.displayName,
      emailVerified: previousAuth.emailVerified,
      disabled: previousAuth.disabled,
    }).catch(() => undefined);
    await ref.set(previousProfile).catch(() => undefined);
    const message = error instanceof Error ?
      error.message : "Error de edicion.";
    throw new HttpsError("internal", message);
  }
});

export const enviarEnlaceAcceso = onCall(async (request) => {
  const caller = await requireUserPermission(
    request.auth?.uid,
    "usuarios.editar"
  );
  const data = (request.data ?? {}) as AccessLinkData;
  if (!data.uid) {
    throw new HttpsError("invalid-argument", "Se requiere el UID.");
  }
  const snapshot = await getFirestore().collection("users").doc(data.uid).get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Usuario no encontrado.");
  }
  const profile = snapshot.data() as Record<string, unknown>;
  validateTeacherScope(caller, {...profile}, profile);
  if (profile.status !== "activo") {
    throw new HttpsError(
      "failed-precondition",
      "No se puede enviar acceso a un usuario inactivo."
    );
  }
  const user = await getAuth().getUser(data.uid);
  const name = `${profile.firstName ?? ""} ${profile.lastName ?? ""}`.trim();
  await enqueueAccessLink(user, name);
  return {enviado: true};
});

export const eliminarUsuarioAuth = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Administrador"]);
  const data = (request.data ?? {}) as DeleteUserData;
  if (!data.uid) {
    throw new HttpsError("invalid-argument", "Se requiere el UID.");
  }
  try {
    await getAuth().deleteUser(data.uid);
    return {success: true};
  } catch (error: unknown) {
    const message = error instanceof Error ?
      error.message : "Error al eliminar.";
    throw new HttpsError("internal", message);
  }
});
