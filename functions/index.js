const {setGlobalOptions} = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

exports.generateAbsencesDaily = onSchedule(
    {
      schedule: "0 23 * * *",
      timeZone: "Africa/Tunis",
    },
    async () => {
      const db = admin.firestore();
      const now = new Date();
      const dateKey = now.toISOString().split("T")[0];

      const employeesSnapshot = await db
          .collection("Users")
          .where("role", "==", "employee")
          .get();

      const batch = db.batch();

      for (const doc of employeesSnapshot.docs) {
        const emp = doc.data();

        const ref = db.collection("attendance").doc(`${doc.id}_${dateKey}`);

        const existing = await ref.get();

        // ❌ إذا يوجد attendance لا نلمسها
        if (existing.exists) {
          const data = existing.data();

          if (data.status === "present") {
            continue; // حاضر → لا نغير شيء
          }

          // إذا absent أو أي حالة أخرى → نتركه
          continue;
        }

        // ✅ إذا لا يوجد أي attendance → نعتبره absent
        batch.set(ref, {
          employeeId: doc.id,
          employeeName: emp.firstName || "",
          status: "absent",
          notes: "غياب تلقائي (لم يتم تسجيل حضور)",
          startTime: now.toISOString(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      console.log("Absences generated safely");
    });
exports.generateFridayAbsencesOnce = onSchedule(
    {
      schedule: "0 23 * * *",
      timeZone: "Africa/Tunis",
    },
    async () => {
      const db = admin.firestore();
      const now = new Date();

      console.log("🚀 Running auto absence job at", now);

      // ✅ only Friday
      if (now.getDay() !== 5) {
        console.log("⛔ Not Friday, exit");
        return;
      }

      // 📌 stable date key (local-safe)
      const dateKey = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Africa/Tunis",
      }).format(now); // YYYY-MM-DD

      console.log("📅 Target date:", dateKey);

      const employeesSnapshot = await db
          .collection("Users")
          .where("role", "==", "employee")
          .get();

      console.log("👥 Employees:", employeesSnapshot.size);

      for (const emp of employeesSnapshot.docs) {
        const employeeId = emp.id;

        const docRef = db
            .collection("attendance")
            .doc(`${employeeId}_${dateKey}`);

        const existing = await docRef.get();

        // ✅ avoid duplicates
        if (existing.exists) {
          console.log("✔ Already exists:", employeeId);
          continue;
        }

        try {
          await docRef.set({
            employeeId,
            employeeName: emp.data().firstName || emp.data().email || "",
            status: "absent",

            notes: "غياب تلقائي يوم الجمعة (يوم عطلة أسبوعية)",

            startTime: now.toISOString(),
            endTime: now.toISOString(),

            workedOnFriday: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log("✔ Absence created:", employeeId);
        } catch (err) {
          console.error("❌ Error for", employeeId, err);
        }
      }

      return null;
    });
