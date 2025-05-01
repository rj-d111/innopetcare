const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();



exports.helloWorld = functions.https.onCall((request) => {
  console.log("Received data:", request.data);  // Optional: log for testing
  const {name} =request.data;
  console.log("Incoming name:", name);

  return { message: `Hello, ${name}!` };
});



exports.bookAppointment = functions.https.onCall(async (request) => {
  try {
    const { clientId, projectId, date, time } = request.data;

    if (!clientId || !projectId || !date || !time) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required appointment data.');
    }

    const db = admin.database();

    // Format the appointment time path for the count reference
    const countRef = db.ref(`appointmentCounts/${projectId}/${date}/${time}`);

    const transactionResult = await countRef.transaction((currentCount) => {
      currentCount = currentCount || 0;
      if (currentCount >= 5) return; // Abort if the limit is reached
      return currentCount + 1;
    });

    if (!transactionResult.committed) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Appointment limit reached for this time slot.'
      );
    }

    return { success: true, message: 'Slot successfully reserved. Proceed to save appointment.' };

  } catch (error) {
    console.error("bookAppointment ERROR:", error);

    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError('internal', 'Something went wrong.', error.message);
  }
});


exports.reserveVetAppointmentSlot = functions.https.onCall(async (request) => {
  try {
    const {
      projectId,
      clientId,
      date,
      time,
      condition,
      additional,
      pet,
      reason,
    } = request.data;

    if (!projectId || !clientId || !date || !time || !reason || !pet) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required appointment data.');
    }

    const db = admin.database();
    const firestore = admin.firestore();

    // Count reference for concurrency control
    const countRef = db.ref(`appointmentCounts/${projectId}/${date}/${time}`);

    const transactionResult = await countRef.transaction((currentCount) => {
      currentCount = currentCount || 0;
      if (currentCount >= 5) return; // abort
      return currentCount + 1;
    });

    if (!transactionResult.committed) {
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Appointment limit reached for this time slot.'
      );
    }

    // Parse event_datetime as a proper JS Date
    const eventDateTime = new Date(`${date}T${time}`); // date: 'YYYY-MM-DD', time: 'HH:mm'

    // Save to Firestore
    await firestore.collection('appointments').add({
      clientId,
      projectId,
      event_datetime: admin.firestore.Timestamp.fromDate(eventDateTime),
      reason,
      condition,
      additional,
      pet,
      numberOfVisitors: numberOfVisitors || 1,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { success: true, message: 'Vet appointment successfully booked.' };

  } catch (error) {
    console.error("reserveVetAppointmentSlot ERROR:", error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError('internal', 'Unexpected error occurred.', error.message);
  }
});
