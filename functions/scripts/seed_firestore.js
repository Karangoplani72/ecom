const admin = require("firebase-admin");

const serviceAccount = require("../serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: "ecom-750fc",
});

const db = admin.firestore();

console.log("Project ID:", admin.app().options.projectId);
console.log("Database ID:", db.formattedName);
async function seed() {
  try {
    await db.collection("users").doc("seller_001").set({
      email: "seller@example.com",
      fullName: "Anjali Shah",
      isActive: true,
      roles: ["seller"],
    });

    await db.collection("stores").doc("store_001").set({
      sellerId: "seller_001",
      name: "Anjali's Elite Studio",
      isActive: true,
    });

    await db.collection("products").doc("product_001").set({
      storeId: "store_001",
      title: "Matte Top Coat",
      status: "active",
      basePrice: 450,
      imageUrl: "",
      stockQuantity: 50,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Database seeded successfully");
    process.exit(0);
  } catch (e) {
    console.error(e);
    process.exit(1);
  }
}

seed();