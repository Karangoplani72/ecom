const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifySellerOnNewOrder = onDocumentCreated(
    {
      document: "transactions/{transactionId}",
      database: "default",
      region: "asia-south1",
    },
    async (event) => {
      const transaction = event.data.data();

      if (!transaction) {
        console.error("Transaction data missing");
        return;
      }

      const storeId = transaction.storeId;
      const grossAmount = transaction.grossAmount || 0;

      try {
        const storeDoc = await admin
            .firestore()
            .collection("stores")
            .doc(storeId)
            .get();

        if (!storeDoc.exists) {
          console.warn(`Store not found: ${storeId}`);
          return;
        }

        const storeData = storeDoc.data();

        if (!storeData) {
          console.warn(`Store data missing: ${storeId}`);
          return;
        }

        const sellerId = storeData.sellerId;

        if (!sellerId) {
          console.warn(`No sellerId found for store: ${storeId}`);
          return;
        }

        const tokensSnapshot = await admin
            .firestore()
            .collection("users")
            .doc(sellerId)
            .collection("tokens")
            .get();

        if (tokensSnapshot.empty) {
          console.log(`No FCM tokens found for seller: ${sellerId}`);
          return;
        }

        const tokens = tokensSnapshot.docs.map((doc) => doc.id);

        const response = await admin.messaging().sendEachForMulticast({
          tokens,
          notification: {
            title: "🎉 New Order Received!",
            body:
              `You received a payment of ₹${grossAmount}. ` +
              "Tap to open your dashboard.",
          },
          data: {
            route: "/seller/dashboard",
          },
        });

        console.log(
            "Notification sent.",
            "Success:",
            response.successCount,
            "Failed:",
            response.failureCount,
        );
      } catch (error) {
        console.error("FCM Dispatch Error:", error);
      }
    },
);
