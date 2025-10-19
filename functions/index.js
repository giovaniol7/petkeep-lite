const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyFamily = onCall(
  {
    region: "southamerica-east1",
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (request) => {
    const { petId, message } = request.data;

    if (!petId || !message) {
      throw new Error("Dados insuficientes.");
    }

    const petDoc = await admin.firestore().collection("pets").doc(petId).get();
    if (!petDoc.exists) {
      throw new Error("Pet não encontrado.");
    }

    const familyCode = petDoc.data().familyCode;
    const usersSnapshot = await admin.firestore()
      .collection("users")
      .where("familyCode", "==", familyCode)
      .get();

    const tokens = [];
    usersSnapshot.forEach((doc) => {
      const userTokens = doc.data().fcmTokens || [];
      tokens.push(...userTokens);
    });

    if (tokens.length === 0) {
      console.log(`Nenhum token encontrado para a família: ${familyCode}`);
      return { success: false };
    }

    const payload = {
      notification: {
        title: "PetKeeper Lite",
        body: message,
      },
    };

    await admin.messaging().sendEachForMulticast({
        tokens,
        ...payload,
    });

    console.log(`✅ Notificação enviada para ${tokens.length} dispositivos`);
    return { success: true, sentTo: tokens.length };
  }
);
