/* functions/src/index.ts */
import {setGlobalOptions} from "firebase-functions/v2";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getMessaging} from "firebase-admin/messaging";
import {getFirestore} from "firebase-admin/firestore";

initializeApp();
setGlobalOptions({region: "us-central1", maxInstances: 10});

interface NotifData {
  tokens?: string[];
  titulo?: string;
  cuerpo?: string;
}

interface CrearUsuarioData {
  email?: string;
  password?: string;
  nombres?: string;
  apellidos?: string;
  rol?: string;
  documento?: string;
}

interface EliminarUsuarioData {
  uid?: string;
}

interface BienvenidaData {
  email?: string;
  nombres?: string;
  apellidos?: string;
  documento?: string;
  portalUrl?: string;
}

const validRoles = new Set(["Estudiante", "Docente", "Administrador"]);

/**
 * Obtiene el rol activo del usuario autenticado que invoca una funcion.
 * @param {string} uid UID del usuario autenticado.
 * @return {Promise<string>} Rol del usuario.
 */
async function getCallerRole(uid: string): Promise<string> {
  const snap = await getFirestore().collection("users").doc(uid).get();
  const data = snap.data();
  if (!data || data.status !== "activo" || typeof data.role !== "string") {
    throw new HttpsError("permission-denied", "Usuario sin permisos.");
  }
  return data.role;
}

/**
 * Exige que el invocador tenga uno de los roles permitidos.
 * @param {string | undefined} uid UID autenticado de la solicitud callable.
 * @param {string[]} allowedRoles Roles autorizados.
 * @return {Promise<string>} Rol validado del invocador.
 */
async function requireRole(
  uid: string | undefined,
  allowedRoles: string[]
): Promise<string> {
  if (!uid) {
    throw new HttpsError("unauthenticated", "Debe iniciar sesion.");
  }
  const callerRole = await getCallerRole(uid);
  if (!allowedRoles.includes(callerRole)) {
    throw new HttpsError("permission-denied", "Rol no autorizado.");
  }
  return callerRole;
}

/**
 * Construye el HTML del correo de bienvenida (tema UDI).
 * @param {string} nombre Nombre completo del usuario.
 * @param {string} portal URL del portal para iniciar sesion.
 * @param {string} userEmail Correo del usuario.
 * @param {string} pass Contrasena inicial (documento).
 * @return {string} HTML listo para enviar.
 */
function buildWelcomeHtml(
  nombre: string,
  portal: string,
  userEmail: string,
  pass: string
): string {
  return [
    "<!doctype html><html lang='es'><head><meta charset='utf-8'>",
    "<meta name='viewport' content='width=device-width,initial-scale=1'>",
    "<style>",
    ":root{--pri:#1e3a8a}",
    "body{font-family:system-ui,-apple-system,Segoe UI,Roboto,",
    "Helvetica,Arial,sans-serif;line-height:1.6;margin:0;",
    "background:#fff;color:#222}",
    ".wrap{max-width:680px;margin:0 auto;padding:24px}",
    "h1{color:var(--pri);margin:0 0 8px;font-size:22px}",
    ".card{background:#fff;border:1px solid rgba(0,0,0,.08);",
    "border-radius:12px;padding:18px;margin:12px 0;",
    "box-shadow:0 2px 8px rgba(0,0,0,.03)}",
    ".big{font-size:18px;font-weight:800;color:var(--pri)}",
    ".muted{color:#555}",
    ".btn{display:inline-block;background:var(--pri);color:#fff;",
    "padding:10px 16px;border-radius:10px;text-decoration:none}",
    "code{background:#f5f5f5;border-radius:8px;padding:2px 6px}",
    "</style></head><body><main class='wrap'>",
    "<h1>Bienvenido(a)</h1>",
    "<div class='card'>",
    "<p>Hola <span class='big'>", nombre, "</span>,</p>",
    "<p class='muted'>Tu cuenta ha sido creada en el sistema.</p>",
    "<p><a class='btn' href='", portal, "' target='_blank'>",
    "Ingresar al sistema</a></p>",
    "<p><strong>URL:</strong> ", portal, "<br/>",
    "<strong>Usuario:</strong> <code>", userEmail, "</code><br/>",
    "<strong>Contrasena:</strong> <code>", pass, "</code></p>",
    "<p class='muted'>Por seguridad, cambia tu contrasena al ingresar.",
    "</p>",
    "</div>",
    "</main></body></html>",
  ].join("");
}

/**
 * Envia una notificacion FCM a multiples tokens.
 * Requiere rol Docente o Administrador.
 */
export const enviarNotificacion = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Docente", "Administrador"]);

  const data = (request.data ?? {}) as NotifData;
  const {tokens, titulo, cuerpo} = data;

  if (!Array.isArray(tokens) || tokens.length === 0) {
    throw new HttpsError(
      "invalid-argument",
      "No se proporcionaron tokens validos."
    );
  }

  try {
    const resp = await getMessaging().sendEachForMulticast({
      notification: {title: titulo, body: cuerpo},
      tokens: tokens,
    });
    return {exitosos: resp.successCount, fallidos: resp.failureCount};
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "Error enviando notificacion.";
    throw new HttpsError("internal", msg);
  }
});

/**
 * Crea un usuario en Firebase Auth.
 * Requiere rol Administrador.
 */
export const crearUsuarioDesdeAdmin = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Administrador"]);

  const data = (request.data ?? {}) as CrearUsuarioData;
  const {email, password, nombres, apellidos, rol, documento} = data;

  if (!email || !password || !nombres || !apellidos || !rol || !documento) {
    throw new HttpsError("invalid-argument", "Faltan datos obligatorios.");
  }
  if (!validRoles.has(rol)) {
    throw new HttpsError("invalid-argument", "Rol invalido.");
  }

  try {
    const user = await getAuth().createUser({
      email: email,
      password: password,
      displayName: `${nombres} ${apellidos}`.trim(),
      disabled: false,
    });
    return {exito: true, uid: user.uid};
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "No se pudo crear el usuario.";
    throw new HttpsError("internal", msg);
  }
});

/**
 * Elimina un usuario de Firebase Auth por UID.
 * Requiere rol Administrador.
 */
export const eliminarUsuarioAuth = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Administrador"]);

  const data = (request.data ?? {}) as EliminarUsuarioData;
  const {uid} = data;

  if (!uid) {
    throw new HttpsError(
      "invalid-argument",
      "Se requiere el UID del usuario."
    );
  }

  try {
    await getAuth().deleteUser(uid);
    return {success: true};
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "No se pudo eliminar el usuario.";
    throw new HttpsError("internal", msg);
  }
});

/**
 * Encola un correo de bienvenida en la coleccion 'mail'.
 * Requiere rol Administrador.
 */
export const enviarCorreoBienvenida = onCall(async (request) => {
  await requireRole(request.auth?.uid, ["Administrador"]);

  const data = (request.data ?? {}) as BienvenidaData;
  const {email, nombres, apellidos, documento, portalUrl} = data;

  if (!email || !nombres || !apellidos || !documento || !portalUrl) {
    throw new HttpsError("invalid-argument", "Datos insuficientes.");
  }

  const nombre = `${nombres} ${apellidos}`.trim();
  const html = buildWelcomeHtml(nombre, portalUrl, email, documento);

  try {
    const db = getFirestore();
    await db.collection("mail").add({
      to: email,
      message: {subject: "Bienvenido(a) al sistema", html: html},
    });
    return {queued: true};
  } catch (err: unknown) {
    const msg =
      err instanceof Error ? err.message : "No se pudo encolar el correo.";
    throw new HttpsError("internal", msg);
  }
});
