const {readFileSync} = require("node:fs");
const {join} = require("node:path");
const {after, before, beforeEach, test} = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");

const projectId = "campus-trace-rules-test";
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(join(__dirname, "../../firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    const users = {
      admin: {role: "Administrador", status: "activo"},
      teacher1: {role: "Docente", status: "activo"},
      teacher2: {role: "Docente", status: "activo"},
      student1: {role: "Estudiante", status: "activo"},
      student2: {role: "Estudiante", status: "activo"},
    };
    await Promise.all(
      Object.entries(users).map(([uid, data]) =>
        db.collection("users").doc(uid).set(data)
      )
    );
    await db.collection("form_templates").doc("owned").set({
      createdBy: "teacher1",
      enrolledUserIds: ["student1"],
    });
    await db.collection("form_templates").doc("other").set({
      createdBy: "teacher2",
      enrolledUserIds: [],
    });
    await db.collection("form_templates").doc("open").set({
      createdBy: "teacher1",
      enrolledUserIds: [],
    });
    await db.collection("form_entries_drafts").doc("student1__owned").set({
      userId: "student1",
      templateId: "owned",
      answers: {field1: "respuesta"},
      stage: "draft",
      locked: false,
    });
  });
});

after(async () => {
  await testEnv.cleanup();
});

function dbFor(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

test("el estudiante edita respuestas pero no calificacion", async () => {
  const ref = dbFor("student1")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  await assertSucceeds(ref.update({"answers.field1": "nueva"}));
  await assertFails(ref.update({grade: 5, stage: "graded"}));
});

test("una entrega enviada ya no puede ser modificada por el estudiante", async () => {
  const ref = dbFor("student1")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  await assertSucceeds(ref.update({locked: true, stage: "submitted"}));
  await assertFails(ref.update({"answers.field1": "posterior"}));
  await assertFails(ref.update({locked: false, stage: "draft"}));
});

test("solo el docente asignado puede revisar la entrega", async () => {
  const ownerRef = dbFor("teacher1")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  const otherRef = dbFor("teacher2")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  await assertSucceeds(
    ownerRef.update({grade: 4.5, stage: "graded", gradedBy: "teacher1"})
  );
  await assertFails(otherRef.update({grade: 5, stage: "graded"}));
});

test("el docente asignado puede devolver una entrega para correccion", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await context.firestore().collection("form_entries_drafts")
      .doc("student1__owned").update({
        locked: true,
        stage: "submitted",
      });
  });

  const ref = dbFor("teacher1")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  await assertSucceeds(ref.update({locked: false, stage: "draft"}));
});

test("un docente solo modifica sus plantillas", async () => {
  const db = dbFor("teacher1");
  await assertSucceeds(
    db.collection("form_templates").doc("owned").update({status: "active"})
  );
  await assertFails(
    db.collection("form_templates").doc("other").update({status: "active"})
  );
});

test("el estudiante solo cambia su propio UID de inscripcion", async () => {
  const ownRef = dbFor("student1").collection("form_templates").doc("open");
  await assertSucceeds(ownRef.update({enrolledUserIds: ["student1"]}));

  const otherRef = dbFor("student2")
    .collection("form_templates")
    .doc("other");
  await assertFails(otherRef.update({enrolledUserIds: ["student1"]}));
});

test("el administrador conserva acceso de revision", async () => {
  const ref = dbFor("admin")
    .collection("form_entries_drafts")
    .doc("student1__owned");
  await assertSucceeds(ref.update({grade: 5, stage: "graded"}));
});
