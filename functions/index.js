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

      const dateKey = new Intl.DateTimeFormat("en-CA", {
        timeZone: "Africa/Tunis",
      }).format(now);

      const isFriday =
      new Intl.DateTimeFormat("en-US", {
        weekday: "short",
        timeZone: "Africa/Tunis",
      }).format(now) === "Fri";

      console.log("📅 Date:", dateKey);
      console.log("📌 Friday:", isFriday);

      const employeesSnapshot = await db
          .collection("Users")
          .where("role", "==", "employee")
          .get();

      const batch = db.batch();

      for (const employeeDoc of employeesSnapshot.docs) {
        const employeeId = employeeDoc.id;
        const employeeData = employeeDoc.data();

        // Vérifier si un attendance existe déjà aujourd'hui
        const attendanceSnapshot = await db
            .collection("attendance")
            .where("employeeId", "==", employeeId)
            .get();

        let alreadyExists = false;

        for (const attendanceDoc of attendanceSnapshot.docs) {
          const attendanceData = attendanceDoc.data();

          if (!attendanceData.startTime) continue;

          try {
            let attendanceDate;

            if (
              attendanceData.startTime &&
              typeof attendanceData.startTime.toDate === "function"
            ) {
              attendanceDate = attendanceData.startTime.toDate();
            } else {
              attendanceDate = new Date(attendanceData.startTime);
            }

            const attendanceDateKey =
            new Intl.DateTimeFormat("en-CA", {
              timeZone: "Africa/Tunis",
            }).format(attendanceDate);

            if (attendanceDateKey === dateKey) {
              alreadyExists = true;
              break;
            }
          } catch (e) {
            console.error(
                "❌ Error parsing attendance date:",
                attendanceDoc.id,
                e,
            );
          }
        }

        if (alreadyExists) {
          console.log(
              `✔ Attendance already exists for ${employeeId}`,
          );
          continue;
        }

        const absenceRef = db
            .collection("attendance")
            .doc(`${employeeId}_${dateKey}`);

        batch.set(absenceRef, {
          employeeId,
          employeeName:
          employeeData.firstName ||
          employeeData.email ||
          "",
          status: isFriday ? "present" : "absent",
          notes: isFriday ?
            "يوم الجمعة (يوم عطلة أسبوعية)" :
            "غياب",
          workedOnFriday: isFriday ? false : null,

          startTime: now.toISOString(),
          endTime: now.toISOString(),

          createdAt:
          admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(
            `❌ Auto absence created for ${employeeId}`,
        );
      }

      await batch.commit();

      console.log("✅ Daily absences generated successfully");
      return null;
    },
);

