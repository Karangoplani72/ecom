"use strict";

// ---------------------------------------------------------------------------
// REGION STRATEGY
// ---------------------------------------------------------------------------
// HTTPS / Scheduled functions  → us-central1   (no constraint)
// Firestore-triggered functions → asia-south1   (MUST match Firestore DB region)
//
// CRITICAL: Do NOT use setGlobalOptions({ region: '...' }) when you have
// mixed-region functions. In firebase-functions v7 + CLI v15, setGlobalOptions
// region overrides the Eventarc trigger location even when an explicit region
// is set on the individual onDocument* call. This causes the misleading error:
//   "Trigger's location 'asia-south1' is not compatible with
//    the Firestore database location: 'asia-south1'"
// The actual mismatch is: trigger lands in us-central1, DB is in asia-south1.
// Fix: remove region from setGlobalOptions; set it explicitly on every function.
// ---------------------------------------------------------------------------

const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentWritten, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");
const PDFDocument = require("pdfkit");

admin.initializeApp();

// No setGlobalOptions({ region }) — see note above.
// If you need other global options (memory, timeout, etc.) you can add them
// here WITHOUT a region key.

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");

// ---------------------------------------------------------------------------
// HELPER: Verify Firebase ID Token
// (App Check enforcement removed — client no longer sends an App Check
// token, so requiring one here always rejected every request with 401.)
// ---------------------------------------------------------------------------
async function verifyAuth(req, res) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    console.error("[AUTH][ERROR] Missing or malformed Authorization header.");
    res.status(401).json({error: "Unauthorized: missing auth token."});
    return null;
  }
  const token = authHeader.split("Bearer ")[1];
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    console.log("[AUTH] Token verified. uid:", decoded.uid);
    return decoded;
  } catch (e) {
    console.error("[AUTH][ERROR] Token verification failed:", e.message);
    res.status(401).json({error: "Unauthorized: invalid token."});
    return null;
  }
}

// ---------------------------------------------------------------------------
// HELPER: Perform RazorpayX Payout
// ---------------------------------------------------------------------------
async function performRazorpayPayout(storeId, amount, referenceId, db) {
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  // Try fetching RazorpayX Account Number from settings/razorpay doc in Firestore
  const configSnap = await db.collection("settings").doc("razorpay").get();
  const config = configSnap.exists ? configSnap.data() : {};
  const razorpayXAcc = config.razorpayXAccountNumber || process.env.RAZORPAYX_ACCOUNT_NUMBER;

  if (!keyId || !keySecret || !razorpayXAcc || keyId.trim() === "" || keySecret.trim() === "" || razorpayXAcc.trim() === "") {
    console.warn(
        `[RAZORPAYX] Payout skipped: Missing configuration. ` +
        `RAZORPAY_KEY_ID: ${keyId ? "SET" : "MISSING"}, ` +
        `RAZORPAY_KEY_SECRET: ${keySecret ? "SET" : "MISSING"}, ` +
        `RAZORPAYX_ACCOUNT_NUMBER: ${razorpayXAcc ? "SET" : "MISSING"}`,
    );
    return {success: true, mode: "mocked", message: "Bypassed due to missing credentials"};
  }

  // Fetch bank details from sellers/{storeId}/bankDetails/primary
  const bankSnap = await db.collection("sellers").doc(storeId)
      .collection("bankDetails").doc("primary").get();

  if (!bankSnap.exists) {
    throw new Error(`Bank details not found for seller: ${storeId}`);
  }

  const bank = bankSnap.data();
  const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");

  try {
    const response = await fetch("https://api.razorpay.com/v1/payouts", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${auth}`,
      },
      body: JSON.stringify({
        account_number: razorpayXAcc,
        amount: Math.round(amount * 100), // convert to paise
        currency: "INR",
        mode: "IMPS",
        purpose: "payout",
        fund_account: {
          account_type: "bank_account",
          bank_account: {
            name: bank.holderName,
            ifsc: bank.ifsc,
            account_number: bank.accountNumber,
          },
          contact: {
            name: bank.holderName,
            type: "vendor",
          },
        },
      }),
    });

    const resData = await response.json();

    if (!response.ok) {
      console.error("[RAZORPAYX][ERROR] API responded with error:", resData);
      throw new Error((resData.error && resData.error.description) || "RazorpayX Payout API failed");
    }

    console.log("[RAZORPAYX][SUCCESS] Payout initiated:", resData.id);
    return {success: true, mode: "live", payoutId: resData.id};
  } catch (err) {
    console.error("[RAZORPAYX][ERROR] Call failed:", err.message);
    throw err;
  }
}

// ---------------------------------------------------------------------------
// HELPER: Flash sale price logic
// ---------------------------------------------------------------------------
function isFlashSaleActive(itemData) {
  const metadata = itemData.metadata || {};
  if (metadata.isFlashDeal !== true) return false;
  if (metadata.flashSaleStatus && metadata.flashSaleStatus !== "active") return false;
  const startsAt = metadata.flashSaleStartsAt;
  const endsAt = metadata.flashSaleEndsAt;
  if (!startsAt || !endsAt) return false;
  const start = startsAt.toDate ? startsAt.toDate() : (startsAt._seconds ? new Date(startsAt._seconds * 1000) : new Date(startsAt));
  const end = endsAt.toDate ? endsAt.toDate() : (endsAt._seconds ? new Date(endsAt._seconds * 1000) : new Date(endsAt));
  const now = new Date();
  return now >= start && now <= end;
}

function getEffectivePrice(itemData, skuPrice) {
  const basePrice = (typeof skuPrice === "number" && skuPrice > 0) ?
    skuPrice :
    (parseFloat(itemData.basePrice) || 0);
  if (!isFlashSaleActive(itemData)) return basePrice;
  const metadata = itemData.metadata || {};
  const percent = parseFloat(metadata.flashSaleDiscountPercent) || 0;
  return basePrice * (1.0 - percent);
}

// ===========================================================================
// HTTPS FUNCTIONS  (region: us-central1)
// ===========================================================================

// ---------------------------------------------------------------------------
// 1. getRazorpayKey
// ---------------------------------------------------------------------------
exports.getRazorpayKey = onRequest(
    {
      region: "us-central1",
      cors: true,
      secrets: [RAZORPAY_KEY_ID],
      timeoutSeconds: 15,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log("[FUNCTION][getRazorpayKey] Request received at", ts);

      const key = RAZORPAY_KEY_ID.value();
      if (!key || key.trim() === "") {
        console.error("[RAZORPAY][ERROR] RAZORPAY_KEY_ID secret is empty or not set.");
        return res.status(500).json({error: "Payment system not configured. Contact support."});
      }

      console.log("[RAZORPAY] Serving key ID (prefix):", key.substring(0, 12) + "...");
      return res.json({key: key.trim()});
    },
);

// ---------------------------------------------------------------------------
// 2. createRazorpayOrder
// ---------------------------------------------------------------------------
exports.createRazorpayOrder = onRequest(
    {
      region: "us-central1",
      cors: true,
      secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log("[FUNCTION][createRazorpayOrder] Request received at", ts);

      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed. Use POST."});
      }

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const {amount, currency = "INR", receipt} = req.body;

      if (!amount || typeof amount !== "number" || !Number.isInteger(amount) || amount < 100) {
        console.error("[RAZORPAY][ERROR] Invalid amount:", amount, "(must be integer paise >= 100)");
        return res.status(400).json({error: "Invalid amount. Minimum ₹1 (100 paise)."});
      }

      const keyId = RAZORPAY_KEY_ID.value();
      const keySecret = RAZORPAY_KEY_SECRET.value();
      if (!keyId || !keySecret) {
        console.error("[RAZORPAY][ERROR] Razorpay secrets not configured.");
        return res.status(500).json({error: "Payment system not configured. Contact support."});
      }

      const rzp = new Razorpay({key_id: keyId, key_secret: keySecret});
      const receiptId = receipt || `rcpt_${decoded.uid.substring(0, 8)}_${Date.now()}`;

      console.log("[RAZORPAY] Creating order: amount=", amount, "paise, currency=", currency,
          ", receipt=", receiptId, ", buyerUid=", decoded.uid);

      try {
        const rzpOrder = await rzp.orders.create({
          amount,
          currency,
          receipt: receiptId,
          payment_capture: 1,
        });

        console.log("[RAZORPAY][SUCCESS] Order created. razorpay_order_id:", rzpOrder.id,
            "| amount:", rzpOrder.amount, "| ts:", ts, "| buyerUid:", decoded.uid);

        return res.json({id: rzpOrder.id, amount: rzpOrder.amount, currency: rzpOrder.currency});
      } catch (e) {
        console.error("[RAZORPAY][ERROR] orders.create failed:", e.message,
            "| error detail:", JSON.stringify(e.error || {}));
        return res.status(500).json({error: "Failed to create payment order. Please try again."});
      }
    },
);

// ---------------------------------------------------------------------------
// 3. verifyAndFinalizePayment
// ---------------------------------------------------------------------------
exports.verifyAndFinalizePayment = onRequest(
    {
      region: "us-central1",
      cors: true,
      secrets: [RAZORPAY_KEY_SECRET],
      timeoutSeconds: 60,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log("[FUNCTION][verifyAndFinalizePayment] Request received at", ts);

      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed. Use POST."});
      }

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const {
        razorpay_payment_id: paymentId,
        razorpay_order_id: rzpOrderId,
        razorpay_signature: signature,
        buyerId,
        buyerName,
        deliveryAddress,
        orders,
        couponCode,
      } = req.body;

      if (!buyerId || decoded.uid !== buyerId) {
        console.error("[PAYMENT][SECURITY] UID mismatch. token.uid:", decoded.uid,
            "| requested buyerId:", buyerId);
        return res.status(403).json({error: "Forbidden: buyer ID mismatch."});
      }

      if (!paymentId || !rzpOrderId || !signature) {
        console.error("[PAYMENT][ERROR] Missing payment identifiers.",
            {paymentId, rzpOrderId, sigPresent: !!signature});
        return res.status(400).json({error: "Missing payment identifiers."});
      }
      if (!orders || !Array.isArray(orders) || orders.length === 0) {
        console.error("[PAYMENT][ERROR] Missing or empty orders array for buyer:", buyerId);
        return res.status(400).json({error: "No orders provided."});
      }
      if (!deliveryAddress) {
        return res.status(400).json({error: "Delivery address is required."});
      }

      // ── HMAC-SHA256 Signature Verification ──────────────────────────────────
      console.log("[PAYMENT] Verifying HMAC-SHA256 signature for paymentId:", paymentId,
          "| rzpOrderId:", rzpOrderId);

      const keySecret = RAZORPAY_KEY_SECRET.value();
      if (!keySecret) {
        console.error("[PAYMENT][ERROR] RAZORPAY_KEY_SECRET not configured.");
        return res.status(500).json({error: "Payment verification system not configured."});
      }

      const expectedSignature = crypto
          .createHmac("sha256", keySecret)
          .update(`${rzpOrderId}|${paymentId}`)
          .digest("hex");

      if (expectedSignature !== signature) {
        console.error("[PAYMENT][SECURITY] Signature MISMATCH.",
            "| expected:", expectedSignature,
            "| received:", signature,
            "| paymentId:", paymentId,
            "| buyerId:", buyerId,
            "| ts:", ts);
        return res.status(400).json({
          error: "Payment verification failed: invalid signature. This incident has been logged.",
        });
      }

      console.log("[PAYMENT][SUCCESS] Signature verified.",
          "| paymentId:", paymentId, "| rzpOrderId:", rzpOrderId, "| buyerId:", buyerId);

      const db = admin.firestore();

      // Fetch coupon if provided
      let couponRef = null;
      if (couponCode && typeof couponCode === "string" && couponCode.trim().length > 0) {
        const couponQuery = await db.collection("coupons")
            .where("code", "==", couponCode.toUpperCase().trim())
            .limit(1)
            .get();
        if (!couponQuery.empty) {
          couponRef = couponQuery.docs[0].ref;
        } else {
          console.warn("[PAYMENT] Coupon code not found:", couponCode);
          return res.status(400).json({error: "Invalid or expired coupon code."});
        }
      }

      const orderIds = [];

      try {
        await db.runTransaction(async (txn) => {
        // ── PHASE 1: ALL READS ───────────────────────────────────────────────
          let couponDoc = null;
          let couponDetail = null;
          if (couponRef) {
            couponDoc = await txn.get(couponRef);
            if (!couponDoc.exists) throw new Error("Coupon no longer exists.");
            couponDetail = couponDoc.data();
            if (!couponDetail.isActive) throw new Error("This coupon is no longer active.");
            const expiry = couponDetail.expiryDate.toDate ?
            couponDetail.expiryDate.toDate() :
            (couponDetail.expiryDate._seconds ?
                new Date(couponDetail.expiryDate._seconds * 1000) :
                new Date(couponDetail.expiryDate));
            if (expiry < new Date()) throw new Error("This coupon has expired.");
          }

          console.log("[FIRESTORE] Reading catalog docs for", orders.length, "order(s)...");

          const stockEntries = new Map();

          for (const order of orders) {
            for (const item of order.items) {
              let existing = stockEntries.get(item.productId);
              if (!existing) {
                existing = {
                  catalogRef: db.collection("catalog").doc(item.productId),
                  storeProductRef: db.collection("stores").doc(order.storeId)
                      .collection("products").doc(item.productId),
                  title: item.title,
                  totalQty: 0,
                  skuQty: new Map(),
                };
                stockEntries.set(item.productId, existing);
              }
              existing.totalQty += item.quantity;
              if (item.skuId) {
                existing.skuQty.set(item.skuId, (existing.skuQty.get(item.skuId) || 0) + item.quantity);
              }
            }
          }

          for (const [productId, entry] of stockEntries) {
            const catalogDoc = await txn.get(entry.catalogRef);
            if (!catalogDoc.exists) {
              throw new Error(`Product not found in catalog: "${entry.title}" (${productId})`);
            }

            const data = catalogDoc.data();
            const variantSkus = Array.isArray(data.variantSkus) ? data.variantSkus : [];
            const hasVariants = variantSkus.length > 0;

            entry.catalogData = data;
            entry.hasVariants = hasVariants;

            if (hasVariants) {
              const skuList = variantSkus.map((s) => ({...s}));
              entry.skuList = skuList;

              for (const [skuId, requestedQty] of entry.skuQty) {
                const sku = skuList.find((s) => s.skuId === skuId);
                if (!sku) {
                  throw new Error(`Selected variant not found for "${entry.title}" (sku: ${skuId}).`);
                }
                const skuStock = typeof sku.stock === "number" ? sku.stock : 0;
                console.log("[FIRESTORE] SKU stock check — productId:", productId,
                    "| skuId:", skuId, "| skuStock:", skuStock, "| requested:", requestedQty);
                if (skuStock < requestedQty) {
                  throw new Error(
                      `Insufficient stock for "${entry.title}" (${sku.combination ?
                    JSON.stringify(sku.combination) : skuId}). ` +
                  `Available: ${skuStock}, Requested: ${requestedQty}.`,
                  );
                }
              }
            } else {
              const metadata = data.metadata || {};
              const currentStock = typeof metadata.stock === "number" ? metadata.stock : 0;
              console.log("[FIRESTORE] Stock check — productId:", productId,
                  "| currentStock:", currentStock, "| requested:", entry.totalQty);
              if (currentStock < entry.totalQty) {
                throw new Error(
                    `Insufficient stock for "${entry.title}". ` +
                `Available: ${currentStock}, Requested: ${entry.totalQty}.`,
                );
              }
              entry.currentStock = currentStock;
            }
          }

          const configRef = db.collection("platform_settings").doc("global_config");
          const configDoc = await txn.get(configRef);
          let defaultCommissionRate = 0.085;
          if (configDoc.exists) {
            defaultCommissionRate = parseFloat(configDoc.data().defaultCommissionRate) || 0.085;
          }
          console.log("[CONFIG] Loaded platform defaultCommissionRate:", defaultCommissionRate);

          // ── PHASE 2: ALL WRITES ──────────────────────────────────────────────
          const serverNow = admin.firestore.FieldValue.serverTimestamp();

          for (const [productId, entry] of stockEntries) {
            let stockUpdate;

            if (entry.hasVariants) {
              const skuList = entry.skuList;
              for (const [skuId, requestedQty] of entry.skuQty) {
                const idx = skuList.findIndex((s) => s.skuId === skuId);
                const currentSkuStock = typeof skuList[idx].stock === "number" ? skuList[idx].stock : 0;
                const newSkuStock = Math.max(0, currentSkuStock - requestedQty);
                skuList[idx] = {...skuList[idx], stock: newSkuStock};
                console.log("[FIRESTORE] Deducting SKU stock — productId:", productId,
                    "| skuId:", skuId, "|", currentSkuStock, "→", newSkuStock);
              }
              const newTotalStock = skuList.reduce(
                  (sum, s) => sum + (typeof s.stock === "number" ? s.stock : 0), 0,
              );
              console.log("[FIRESTORE] New total stock across all SKUs — productId:", productId,
                  "| newTotalStock:", newTotalStock);
              stockUpdate = {"variantSkus": skuList, "metadata.stock": newTotalStock, "updatedAt": serverNow};
            } else {
              const newStock = Math.max(0, entry.currentStock - entry.totalQty);
              console.log("[FIRESTORE] Deducting stock — productId:", productId,
                  "|", entry.currentStock, "→", newStock);
              stockUpdate = {"metadata.stock": newStock, "updatedAt": serverNow};
            }

            txn.update(entry.catalogRef, stockUpdate);
            txn.update(entry.storeProductRef, stockUpdate);
          }

          // Calculate subtotals
          let totalSubtotal = 0;
          const orderSubtotals = [];

          for (const order of orders) {
            let sub = 0;
            for (const item of order.items) {
              const entry = stockEntries.get(item.productId);
              const catalogData = entry.catalogData;
              let sku = null;
              if (entry.hasVariants && item.skuId) {
                sku = entry.skuList.find((s) => s.skuId === item.skuId);
              }
              const skuPrice = sku && typeof sku.price === "number" && sku.price > 0 ? sku.price : undefined;
              const effectivePrice = getEffectivePrice(catalogData, skuPrice);
              const qty = parseInt(item.quantity) || 1;
              sub += effectivePrice * qty;
            }
            orderSubtotals.push(sub);
            totalSubtotal += sub;
          }

          let overallDiscount = 0;
          if (couponDetail) {
            const minOrder = parseFloat(couponDetail.minOrderValue) || 0.0;
            if (totalSubtotal < minOrder) {
              throw new Error(
                  `Order subtotal (₹${totalSubtotal}) is less than the coupon's minimum order value (₹${minOrder}).`,
              );
            }
            if (couponDetail.discountType === "percentage") {
              overallDiscount = totalSubtotal * (parseFloat(couponDetail.value) / 100);
            } else {
              overallDiscount = Math.min(parseFloat(couponDetail.value) || 0.0, totalSubtotal);
            }
          }

          // Create order documents
          let orderIndex = 0;
          for (const order of orders) {
            const orderRef = db.collection("orders").doc();
            orderIds.push(orderRef.id);

            const orderSubtotal = orderSubtotals[orderIndex];
            let orderDiscount = 0;
            if (overallDiscount > 0 && totalSubtotal > 0) {
              orderDiscount = overallDiscount * (orderSubtotal / totalSubtotal);
            }

            let orderPlatformFee = 0;
            let orderVendorPayout = 0;

            const orderItems = order.items.map((item) => {
              const entry = stockEntries.get(item.productId);
              const catalogData = entry.catalogData;
              const qty = parseInt(item.quantity) || 1;

              let sku = null;
              if (entry.hasVariants && item.skuId) {
                sku = entry.skuList.find((s) => s.skuId === item.skuId);
              }

              const skuPrice = sku && typeof sku.price === "number" && sku.price > 0 ? sku.price : undefined;
              const originalPrice = skuPrice !== undefined ? skuPrice : (parseFloat(catalogData.basePrice) || 0);
              const effectivePrice = getEffectivePrice(catalogData, skuPrice);
              const isSale = isFlashSaleActive(catalogData);
              const metadata = catalogData.metadata || {};
              const sponsor = metadata.flashSaleSponsor || "seller";

              let itemPlatformFee = 0;
              let itemPayout = 0;

              if (isSale && sponsor === "admin") {
                itemPlatformFee = (originalPrice * defaultCommissionRate) - (originalPrice - effectivePrice);
                itemPayout = originalPrice * (1.0 - defaultCommissionRate);
              } else {
                itemPlatformFee = effectivePrice * defaultCommissionRate;
                itemPayout = effectivePrice * (1.0 - defaultCommissionRate);
              }

              orderPlatformFee += itemPlatformFee * qty;
              orderVendorPayout += itemPayout * qty;

              return {
                productId: item.productId,
                title: item.title,
                imageUrl: item.imageUrl,
                quantity: qty,
                unitPrice: effectivePrice,
                ...(item.skuId ? {skuId: item.skuId} : {}),
                ...(item.selectedCombination ? {selectedCombination: item.selectedCombination} : {}),
              };
            });

            const orderDeliveryFee = orderSubtotal < 1000 ? 99.0 : 0.0;
            const orderTotalAmount = Math.max(0, orderSubtotal + orderDeliveryFee + orderPlatformFee - orderDiscount);

            const orderDoc = {
              orderId: orderRef.id,
              buyerId,
              buyerName: buyerName || "",
              storeId: order.storeId,
              storeName: order.storeName || "",
              status: "pending",
              items: orderItems,
              subtotal: orderSubtotal,
              deliveryFee: orderDeliveryFee,
              platformFee: orderPlatformFee,
              discount: orderDiscount,
              couponCode: couponCode || null,
              totalAmount: orderTotalAmount,
              paymentMethod: order.paymentMethod || "Online (Razorpay)",
              paymentStatus: "completed",
              paymentId,
              razorpayOrderId: rzpOrderId,
              deliveryAddress,
              createdAt: serverNow,
              updatedAt: serverNow,
            };

            console.log("[ORDER] Creating order document:", orderRef.id,
                "| buyerId:", buyerId, "| storeId:", order.storeId,
                "| calculated amount: ₹", orderTotalAmount,
                "| payout: ₹", orderVendorPayout,
                "| platformFee: ₹", orderPlatformFee,
                "| paymentId:", paymentId);

            txn.set(orderRef, orderDoc);

            const transactionRef = db.collection("transactions").doc();
            txn.set(transactionRef, {
              id: transactionRef.id,
              orderId: orderRef.id,
              referenceId: orderRef.id,
              buyerId,
              storeId: order.storeId,
              type: "sale",
              status: "completed",
              gateway: "razorpay",
              externalTransactionId: paymentId,
              grossAmount: orderSubtotal,
              platformCommission: orderPlatformFee,
              discount: orderDiscount,
              netVendorPayout: orderVendorPayout,
              amount: orderVendorPayout,
              currency: "INR",
              description: `Order placement for ${orderRef.id}`,
              createdAt: serverNow,
              completedAt: serverNow,
            });

            const walletRef = db.collection("wallets").doc(order.storeId);
            txn.set(walletRef, {
              storeId: order.storeId,
              balance: admin.firestore.FieldValue.increment(0),
              pendingEscrowBalance: admin.firestore.FieldValue.increment(orderVendorPayout),
              currency: "INR",
              updatedAt: serverNow,
            }, {merge: true});

            const storeRef = db.collection("stores").doc(order.storeId);
            txn.set(storeRef, {
              totalOrders: admin.firestore.FieldValue.increment(1),
              updatedAt: serverNow,
            }, {merge: true});

            const escrowRef = db.collection("escrows").doc();
            txn.set(escrowRef, {
              id: escrowRef.id,
              orderId: orderRef.id,
              storeId: order.storeId,
              amount: orderVendorPayout,
              status: "pending",
              releaseAt: admin.firestore.Timestamp.fromDate(
                  new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
              ),
              createdAt: serverNow,
              updatedAt: serverNow,
            });

            const buyerNotifRef = db.collection("users").doc(buyerId)
                .collection("notifications").doc();
            txn.set(buyerNotifRef, {
              title: "✅ Order Placed Successfully",
              body: `Your order #${orderRef.id.substring(0, 8).toUpperCase()} ` +
                          `from ${order.storeName} has been placed. ` +
                          `Total: ₹${(orderTotalAmount || 0).toFixed(2)}`,
              deepLinkPath: `/buyer/orders/${orderRef.id}`,
              isRead: false,
              createdAt: serverNow,
            });

            const sellerNotifRef = db.collection("users").doc(order.storeId)
                .collection("notifications").doc();
            txn.set(sellerNotifRef, {
              title: "🛍️ New Order Received",
              body: `New order from ${buyerName}. ` +
                          `Order #${orderRef.id.substring(0, 8).toUpperCase()}. ` +
                          `Amount: ₹${(orderTotalAmount || 0).toFixed(2)}`,
              deepLinkPath: `/seller/orders/${orderRef.id}`,
              isRead: false,
              createdAt: serverNow,
            });

            orderIndex++;
          }
        });

        console.log("[SUCCESS][verifyAndFinalizePayment] Transaction committed.",
            "| orderIds:", orderIds.join(", "),
            "| buyerId:", buyerId,
            "| paymentId:", paymentId,
            "| ts:", ts);

        // Clear buyer cart (non-transactional, non-fatal)
        try {
          console.log("[CART] Clearing cart for buyer:", buyerId);
          const cartRef = db.collection("users").doc(buyerId).collection("cart");
          const cartSnap = await cartRef.get();
          if (!cartSnap.empty) {
            const batch = db.batch();
            cartSnap.docs.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            console.log("[CART][SUCCESS] Cart cleared for buyer:", buyerId,
                "| items removed:", cartSnap.size);
          } else {
            console.log("[CART] Cart already empty for buyer:", buyerId);
          }
        } catch (cartErr) {
          console.error("[CART][ERROR] Failed to clear cart for buyer:", buyerId,
              "| error:", cartErr.message,
              "| NOTE: Order was created successfully. Cart will be cleared by client.");
        }

        return res.json({success: true, orderIds});
      } catch (txnError) {
        console.error("[FIRESTORE][ERROR] Transaction failed.",
            "| error:", txnError.message,
            "| paymentId:", paymentId,
            "| buyerId:", buyerId,
            "| ts:", ts);
        return res.status(500).json({
          error: txnError.message ||
          "Order creation failed after payment. Please contact support with your payment ID.",
          paymentId,
        });
      }
    },
);

// ---------------------------------------------------------------------------
// 4. releaseMaturedEscrows  (manual HTTP trigger, admin use)
// ---------------------------------------------------------------------------
exports.releaseMaturedEscrows = onRequest(
    {region: "us-central1", cors: true, timeoutSeconds: 60},
    async (req, res) => {
      const db = admin.firestore();
      const now = new Date();
      const serverNow = admin.firestore.FieldValue.serverTimestamp();
      const {escrowId} = req.body || {};

      try {
        let maturedDocs = [];

        if (escrowId) {
          const escrowDoc = await db.collection("escrows").doc(escrowId).get();
          if (!escrowDoc.exists) {
            return res.status(404).json({error: "Escrow not found."});
          }
          maturedDocs = [escrowDoc];
        } else {
          const maturedEscrowsSnap = await db.collection("escrows")
              .where("status", "==", "pending")
              .where("releaseAt", "<=", now)
              .get();
          maturedDocs = maturedEscrowsSnap.docs;
        }

        if (maturedDocs.length === 0) {
          return res.json({success: true, releasedCount: 0});
        }

        const releasedIds = [];
        await db.runTransaction(async (txn) => {
          for (const doc of maturedDocs) {
            // Read the escrow inside the transaction to prevent race conditions
            const escrowRef = doc.ref;
            const escrowDoc = await txn.get(escrowRef);

            if (!escrowDoc.exists) continue;

            const escrow = escrowDoc.data();

            // Allow release if pending or early release requested
            if (escrow.status !== "pending" && escrow.status !== "release_requested") continue;

            const storeId = escrow.storeId;
            const amount = escrow.amount;

            const walletRef = db.collection("wallets").doc(storeId);
            txn.set(walletRef, {
              balance: admin.firestore.FieldValue.increment(amount),
              pendingEscrowBalance: admin.firestore.FieldValue.increment(-amount),
              updatedAt: serverNow,
            }, {merge: true});

            txn.update(escrowRef, {
              status: "released",
              releasedReason: escrowId ? "early_release" : "matured",
              updatedAt: serverNow,
            });

            const transactionRef = db.collection("transactions").doc();
            txn.set(transactionRef, {
              id: transactionRef.id,
              orderId: escrow.orderId,
              referenceId: escrow.id,
              storeId,
              type: "adjustment",
              status: "completed",
              amount,
              currency: "INR",
              description: escrowId ?
                  `Early escrow release for order ${escrow.orderId}` :
                  `Escrow release for order ${escrow.orderId}`,
              createdAt: serverNow,
              completedAt: serverNow,
            });

            releasedIds.push(doc.id);
          }
        });

        console.log("[ESCROW] Successfully released", releasedIds.length, "escrows.");
        return res.json({success: true, releasedCount: releasedIds.length, releasedIds});
      } catch (error) {
        console.error("[ESCROW][ERROR] Failed to release matured escrows:", error);
        return res.status(500).json({error: error.message});
      }
    },
);

// ---------------------------------------------------------------------------
// 5. generateInvoicePDF
// ---------------------------------------------------------------------------
exports.generateInvoicePDF = onRequest(
    {region: "us-central1", cors: true, timeoutSeconds: 30},
    async (req, res) => {
      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed. Use POST."});
      }

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const {orderId} = req.body;
      if (!orderId) {
        return res.status(400).json({error: "orderId is required."});
      }

      const db = admin.firestore();
      try {
        const orderDoc = await db.collection("orders").doc(orderId).get();
        if (!orderDoc.exists) {
          return res.status(404).json({error: "Order not found."});
        }

        const order = orderDoc.data();
        if (order.buyerId !== decoded.uid && order.storeId !== decoded.uid) {
          return res.status(403).json({error: "Forbidden: You do not have access to this order."});
        }

        const doc = new PDFDocument({margin: 50});
        const buffers = [];
        doc.on("data", buffers.push.bind(buffers));

        doc.fontSize(20).text("INVOICE", {align: "center"});
        doc.moveDown();
        doc.fontSize(12).text(`Order ID: ${order.orderId}`);
        doc.text(`Date: ${order.createdAt ? order.createdAt.toDate().toLocaleString() : new Date().toLocaleString()}`);
        doc.moveDown();
        doc.text(`Sold By: ${order.storeName}`);
        doc.text(`Billed To: ${order.buyerName}`);
        doc.text(`Address: ${order.deliveryAddress}`);
        doc.moveDown();
        doc.fontSize(14).text("Items", {underline: true});
        doc.moveDown(0.5);

        (order.items || []).forEach((item) => {
          doc.fontSize(12).text(
              `${item.title} (x${item.quantity}) - Rs. ${(item.unitPrice * item.quantity).toFixed(2)}`,
          );
        });

        doc.moveDown();
        doc.fontSize(12).text(`Subtotal: Rs. ${order.subtotal.toFixed(2)}`);
        doc.text(`Delivery Fee: Rs. ${order.deliveryFee.toFixed(2)}`);
        doc.text(`Platform Fee: Rs. ${order.platformFee.toFixed(2)}`);
        doc.moveDown();
        doc.fontSize(16).text(`Total Amount: Rs. ${order.totalAmount.toFixed(2)}`, {underline: true});

        doc.end();

        doc.on("end", () => {
          const pdfData = Buffer.concat(buffers);
          res.setHeader("Content-Type", "application/pdf");
          res.setHeader("Content-Disposition", `attachment; filename="invoice_${orderId}.pdf"`);
          res.send(pdfData);
        });
      } catch (error) {
        console.error("[INVOICE][ERROR] Failed to generate invoice:", error);
        return res.status(500).json({error: "Failed to generate invoice."});
      }
    },
);

// ---------------------------------------------------------------------------
// 6. completeSettlement  (HTTPS, us-central1)
// ---------------------------------------------------------------------------
// Called from Dart AdminRepositoryImpl.completeSettlement() via HTTP POST.
// POST body: { settlementId: string }
// Auth:      Bearer token — caller must have admin or superAdmin role.
//
// What it does (atomic transaction):
//   1. Validates caller is admin.
//   2. Reads the settlement from `payouts` first, then `settlements` as
//      fallback — matching the pattern used in processSettlement/rejectSettlement.
//   3. Guards against double-completion (status must be 'processing').
//   4. Decrements wallet.balance by settlement amount (funds leave platform
//      wallet on payout completion).
//   5. Marks the settlement doc status → 'completed', sets completedAt.
//   6. Writes a `transactions` record of type 'payout' for the audit trail.
//   7. Notifies the seller via users/{storeId}/notifications.
// ---------------------------------------------------------------------------
exports.completeSettlement = onRequest(
    {
      region: "us-central1",
      cors: true,
      secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET],
      timeoutSeconds: 60,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log("[FUNCTION][completeSettlement] Request received at", ts);

      if (req.method !== "POST") {
        return res.status(405).json({error: "Method not allowed. Use POST."});
      }

      // ── Auth ─────────────────────────────────────────────────────────────────
      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      // ── Admin role check ─────────────────────────────────────────────────────
      const db = admin.firestore();
      const userDoc = await db.collection("users").doc(decoded.uid).get();
      if (!userDoc.exists) {
        console.error("[SETTLEMENT][AUTH] Caller user doc not found. uid:", decoded.uid);
        return res.status(403).json({error: "Forbidden: user not found."});
      }
      const roles = userDoc.data().roles || [];
      if (!roles.includes("admin") && !roles.includes("superAdmin")) {
        console.error("[SETTLEMENT][AUTH] Non-admin attempted completeSettlement. uid:", decoded.uid);
        return res.status(403).json({error: "Forbidden: admin access required."});
      }

      // ── Input validation ─────────────────────────────────────────────────────
      const {settlementId} = req.body;
      if (!settlementId || typeof settlementId !== "string" || settlementId.trim() === "") {
        return res.status(400).json({error: "settlementId is required."});
      }

      console.log("[SETTLEMENT] Processing completeSettlement for id:", settlementId,
          "| adminUid:", decoded.uid);

      try {
        // Try payouts collection first, fall back to settlements
        const payoutRef = db.collection("payouts").doc(settlementId);
        const settlementRef = db.collection("settlements").doc(settlementId);

        const payoutDoc = await payoutRef.get();
        const settlementDoc = await settlementRef.get();

        let docRef;
        let docData;
        let collection;

        if (payoutDoc.exists) {
          docRef = payoutRef;
          docData = payoutDoc.data();
          collection = "payouts";
        } else if (settlementDoc.exists) {
          docRef = settlementRef;
          docData = settlementDoc.data();
          collection = "settlements";
        } else {
          throw new Error(`Settlement not found: ${settlementId}`);
        }

        console.log("[SETTLEMENT] Found in collection:", collection,
            "| current status:", docData.status,
            "| storeId:", docData.storeId || docData.sellerId,
            "| amount:", docData.amount);

        // Guard: only allow completing from 'processing' status.
        if (docData.status === "completed") {
          throw new Error("Settlement is already completed.");
        }
        if (docData.status === "failed") {
          throw new Error("Settlement was rejected and cannot be completed.");
        }
        if (docData.status !== "processing") {
          throw new Error(
              `Settlement cannot be completed from status '${docData.status}'. ` +
              `It must be in 'processing' status first.`,
          );
        }

        const storeId = docData.storeId || docData.sellerId;
        const amount = typeof docData.amount === "number" ? docData.amount : 0;

        if (!storeId) {
          throw new Error("Settlement document is missing storeId/sellerId field.");
        }
        if (amount <= 0) {
          throw new Error("Settlement amount must be greater than zero.");
        }

        // Validate wallet balance before executing payout
        const walletRef = db.collection("wallets").doc(storeId);
        const walletDoc = await walletRef.get();

        if (!walletDoc.exists) {
          throw new Error(`Wallet not found for storeId: ${storeId}`);
        }

        const currentBalance = typeof walletDoc.data().balance === "number" ?
            walletDoc.data().balance : 0;

        if (currentBalance < amount) {
          throw new Error(
              `Insufficient wallet balance for payout. ` +
              `Available: ₹${currentBalance.toFixed(2)}, Requested: ₹${amount.toFixed(2)}.`,
          );
        }

        // ── TRIGGER BANK PAYMENT (RazorpayX Payout) ─────────────────────────────
        console.log("[SETTLEMENT] Triggering RazorpayX payout for amount:", amount);
        let payoutResult;
        try {
          payoutResult = await performRazorpayPayout(storeId, amount, settlementId, db);
        } catch (apiErr) {
          console.error("[SETTLEMENT][ERROR] RazorpayX Payout failed. Setting status to failed:", apiErr.message);
          // Mark settlement as failed in database
          await docRef.update({
            status: "failed",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            failureReason: apiErr.message,
          });
          return res.status(500).json({error: `RazorpayX Payout failed: ${apiErr.message}`});
        }

        // ── PHASE 2: WRITES (Firestore Transaction) ──────────────────────────────
        await db.runTransaction(async (txn) => {
          const serverNow = admin.firestore.FieldValue.serverTimestamp();

          // 1. Decrement wallet balance
          txn.update(walletRef, {
            balance: admin.firestore.FieldValue.increment(-amount),
            updatedAt: serverNow,
          });

          // 2. Mark settlement as completed
          txn.update(docRef, {
            status: "completed",
            completedAt: serverNow,
            processedBy: decoded.uid,
            updatedAt: serverNow,
            razorpayPayoutId: payoutResult.payoutId || null,
            payoutMode: payoutResult.mode,
          });

          // 3. Write payout transaction record for audit trail
          const transactionRef = db.collection("transactions").doc();
          txn.set(transactionRef, {
            id: transactionRef.id,
            referenceId: settlementId,
            storeId,
            type: "payout",
            status: "completed",
            amount,
            currency: "INR",
            description: `Settlement payout completed for ${settlementId}`,
            processedBy: decoded.uid,
            createdAt: serverNow,
            completedAt: serverNow,
            razorpayPayoutId: payoutResult.payoutId || null,
          });

          // 4. Notify the seller
          const notifRef = db.collection("users").doc(storeId)
              .collection("notifications").doc();
          txn.set(notifRef, {
            title: "💰 Payout Completed",
            body: `Your payout of ₹${amount.toFixed(2)} has been successfully processed.`,
            type: "payout_completed",
            deepLinkPath: "/seller/wallet",
            isRead: false,
            createdAt: serverNow,
          });

          console.log("[SETTLEMENT][SUCCESS] Transaction staged & completed via Razorpay.",
              "| settlementId:", settlementId,
              "| collection:", collection,
              "| storeId:", storeId,
              "| amount: ₹", amount,
              "| payoutId:", payoutResult.payoutId || "MOCKED",
              "| adminUid:", decoded.uid,
              "| ts:", ts);
        });

        return res.json({success: true, settlementId});
      } catch (error) {
        console.error("[SETTLEMENT][ERROR] completeSettlement failed.",
            "| settlementId:", settlementId,
            "| adminUid:", decoded.uid,
            "| error:", error.message,
            "| ts:", ts);
        return res.status(500).json({error: error.message});
      }
    },
);

exports.onOrderStatusUpdate = onDocumentUpdated(
    {
      document: "orders/{orderId}",
      region: "us-central1",
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (before.status === after.status) {
        return null;
      }

      const orderId = event.params.orderId;
      const db = admin.firestore();
      const serverNow = admin.firestore.FieldValue.serverTimestamp();

      if (after.status === "delivered") {
        console.log("[ESCROW] Order delivered, extending escrow release to 7 days for orderId:", orderId);

        try {
          const escrowSnap = await db.collection("escrows")
              .where("orderId", "==", orderId)
              .where("status", "==", "pending")
              .limit(1)
              .get();

          if (escrowSnap.empty) {
            console.log("[ESCROW] No pending escrow found for orderId:", orderId);
            return null;
          }

          const escrowDoc = escrowSnap.docs[0];

          await escrowDoc.ref.update({
            releaseAt: admin.firestore.Timestamp.fromDate(
                new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
            ),
            updatedAt: serverNow,
          });

          console.log("[ESCROW][SUCCESS] Updated releaseAt for delivered order:", orderId);
          return null;
        } catch (error) {
          console.error("[ESCROW][ERROR] Failed to update releaseAt for delivered order:", orderId, error);
          return null;
        }
      } else if (["cancelled", "refunded", "returned", "failed"].includes(after.status)) {
        console.log(`[ESCROW] Order ${after.status}, cancelling escrow for orderId:`, orderId);

        try {
          const escrowSnap = await db.collection("escrows")
              .where("orderId", "==", orderId)
              .where("status", "==", "pending")
              .limit(1)
              .get();

          if (escrowSnap.empty) {
            console.log("[ESCROW] No pending escrow found to cancel for orderId:", orderId);
            return null;
          }

          const escrowDoc = escrowSnap.docs[0];
          const escrow = escrowDoc.data();
          const storeId = escrow.storeId;
          const amount = escrow.amount;

          await db.runTransaction(async (txn) => {
            const walletRef = db.collection("wallets").doc(storeId);
            // Deduct from pendingEscrowBalance, do NOT add to balance
            txn.set(walletRef, {
              pendingEscrowBalance: admin.firestore.FieldValue.increment(-amount),
              updatedAt: serverNow,
            }, {merge: true});

            txn.update(escrowDoc.ref, {
              status: "cancelled",
              releasedReason: `order_${after.status}`,
              updatedAt: serverNow,
            });

            const transactionRef = db.collection("transactions").doc();
            txn.set(transactionRef, {
              id: transactionRef.id,
              orderId,
              referenceId: escrowDoc.id,
              storeId,
              type: "adjustment",
              status: "cancelled",
              amount,
              currency: "INR",
              description: `Escrow cancelled — order ${orderId} ${after.status}`,
              createdAt: serverNow,
              completedAt: serverNow,
            });
          });

          console.log(`[ESCROW][SUCCESS] Cancelled escrow for ${after.status} order:`, orderId,
              "| storeId:", storeId, "| amount:", amount);
          return null;
        } catch (error) {
          console.error(`[ESCROW][ERROR] Failed to cancel escrow for ${after.status} order:`, orderId, error);
          return null;
        }
      }
      return null;
    },
);

// ---------------------------------------------------------------------------
// F2. aggregateProductReviews — recalculate avgRating on review write
// ---------------------------------------------------------------------------
exports.aggregateProductReviews = onDocumentWritten(
    {
      document: "reviews/{reviewId}",
      region: "us-central1",
    },
    async (event) => {
      const db = admin.firestore();
      const reviewData = event.data.after.exists ?
      event.data.after.data() :
      event.data.before.data();
      const productId = reviewData.productId;

      if (!productId) {
        console.log("[REVIEWS] No productId found, skipping aggregation.");
        return null;
      }

      console.log("[REVIEWS] Aggregating reviews for product:", productId);

      try {
        const reviewsSnap = await db.collection("reviews")
            .where("productId", "==", productId)
            .get();

        let totalRating = 0;
        let reviewCount = 0;

        reviewsSnap.forEach((doc) => {
          const data = doc.data();
          if (typeof data.rating === "number") {
            totalRating += data.rating;
            reviewCount++;
          }
        });

        const avgRating = reviewCount > 0 ? (totalRating / reviewCount) : 0;

        await db.collection("catalog").doc(productId).set({
          avgRating,
          reviewCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});

        console.log("[REVIEWS][SUCCESS] Aggregated rating for product:", productId,
            "| avgRating:", avgRating, "| count:", reviewCount);

        const catalogDoc = await db.collection("catalog").doc(productId).get();
        if (catalogDoc.exists) {
          const storeId = catalogDoc.data().storeId;
          if (storeId) {
            const storeProducts = await db.collection("catalog")
                .where("storeId", "==", storeId)
                .get();

            let storeRatingSum = 0;
            let storeTotalReviews = 0;

            storeProducts.forEach((pDoc) => {
              const pData = pDoc.data();
              const rc = pData.reviewCount || 0;
              const ar = pData.avgRating || 0;
              if (rc > 0) {
                storeRatingSum += ar * rc;
                storeTotalReviews += rc;
              }
            });

            const storeAvgRating = storeTotalReviews > 0 ?
            (storeRatingSum / storeTotalReviews) :
            0;

            await db.collection("stores").doc(storeId).set({
              rating: storeAvgRating,
              totalReviews: storeTotalReviews,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, {merge: true});

            console.log("[REVIEWS][SUCCESS] Updated store:", storeId,
                "| storeRating:", storeAvgRating.toFixed(2),
                "| totalReviews:", storeTotalReviews);
          }
        }

        return null;
      } catch (error) {
        console.error("[REVIEWS][ERROR] Failed to aggregate reviews:", error);
        return null;
      }
    },
);

// ---------------------------------------------------------------------------
// F3. checkLowStock — notify seller when catalog stock drops below threshold
// ---------------------------------------------------------------------------
exports.checkLowStock = onDocumentUpdated(
    {
      document: "catalog/{docId}",
      region: "us-central1",
    },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (!before || !after) return null;

      const beforeStock = (before.metadata && before.metadata.stock) ? before.metadata.stock : 0;
      const afterStock = (after.metadata && after.metadata.stock) ? after.metadata.stock : 0;
      const LOW_STOCK_THRESHOLD = 5;

      if (afterStock <= LOW_STOCK_THRESHOLD && beforeStock > LOW_STOCK_THRESHOLD) {
        const storeId = after.storeId;
        const title = after.title;
        const db = admin.firestore();

        await db.collection("users").doc(storeId)
            .collection("notifications").add({
              title: "Low Stock Alert",
              body: `Product "${title}" has low stock (${afterStock} remaining).`,
              type: "stock_alert",
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              data: {productId: event.params.docId, stock: afterStock},
            });

        console.log(`[STOCK] Low stock alert created for product ${event.params.docId}`);
      }

      return null;
    },
);

// ---------------------------------------------------------------------------
// F4. updateSearchKeywords — regenerate search keywords on catalog write
// ---------------------------------------------------------------------------
exports.updateSearchKeywords = onDocumentWritten(
    {
      document: "catalog/{docId}",
      region: "us-central1",
    },
    async (event) => {
      if (!event.data.after.exists) return null;

      const data = event.data.after.data();
      const title = data.title || "";
      const description = data.description || "";
      const category = (data.metadata && data.metadata.category) || "";

      const text = `${title} ${description} ${category}`.toLowerCase();
      const keywords = [...new Set(
          text.split(/[^a-z0-9]/).filter((w) => w.length > 2),
      )].slice(0, 10);

      const currentKeywords = data.searchKeywords || [];
      if (JSON.stringify(keywords) !== JSON.stringify(currentKeywords)) {
        await event.data.after.ref.update({searchKeywords: keywords});
        console.log(`[SEARCH] Updated keywords for ${event.params.docId}`);
      }

      return null;
    },
);

// ===========================================================================
// SCHEDULED FUNCTIONS  (region: us-central1)
// ===========================================================================

// ---------------------------------------------------------------------------
// S1. scheduledEscrowRelease — auto-release matured escrows every hour
// ---------------------------------------------------------------------------
exports.scheduledEscrowRelease = onSchedule(
    {
      schedule: "every 1 hours",
      region: "us-central1",
      secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET],
    },
    async () => {
      const db = admin.firestore();
      const now = new Date();
      const serverNow = admin.firestore.FieldValue.serverTimestamp();

      try {
        const maturedEscrowsSnap = await db.collection("escrows")
            .where("status", "==", "pending")
            .where("releaseAt", "<=", now)
            .get();

        if (maturedEscrowsSnap.empty) {
          console.log("[ESCROW][SCHEDULED] No matured escrows to release.");
          return null;
        }

        const releasedMatures = [];
        const bankDetailsMap = {};

        // Fetch bank details from the correct path: sellers/{storeId}/bankDetails/primary
        for (const doc of maturedEscrowsSnap.docs) {
          const storeId = doc.data().storeId;
          if (bankDetailsMap[storeId] === undefined) {
            const bankSnap = await db.collection("sellers").doc(storeId)
                .collection("bankDetails").doc("primary").get();
            bankDetailsMap[storeId] = bankSnap.exists;
          }
        }

        // 1. Release matured escrows to available balance
        await db.runTransaction(async (txn) => {
          for (const doc of maturedEscrowsSnap.docs) {
            // Re-read escrow to prevent race conditions
            const escrowRef = doc.ref;
            const escrowDoc = await txn.get(escrowRef);

            if (!escrowDoc.exists || escrowDoc.data().status !== "pending") continue;

            const escrow = escrowDoc.data();
            const storeId = escrow.storeId;
            const amount = escrow.amount;

            const walletRef = db.collection("wallets").doc(storeId);
            txn.set(walletRef, {
              balance: admin.firestore.FieldValue.increment(amount),
              pendingEscrowBalance: admin.firestore.FieldValue.increment(-amount),
              updatedAt: serverNow,
            }, {merge: true});

            txn.update(escrowRef, {
              status: "released",
              releasedReason: "matured",
              updatedAt: serverNow,
            });

            const transactionRef = db.collection("transactions").doc();
            txn.set(transactionRef, {
              id: transactionRef.id,
              orderId: escrow.orderId,
              referenceId: escrow.id,
              storeId,
              type: "adjustment",
              status: "completed",
              amount,
              currency: "INR",
              description: `Escrow release for order ${escrow.orderId}`,
              createdAt: serverNow,
              completedAt: serverNow,
            });

            releasedMatures.push({
              storeId,
              amount,
              escrowId: escrow.id,
              orderId: escrow.orderId,
            });
          }
        });

        console.log("[ESCROW][SCHEDULED] Released", releasedMatures.length, "matured escrows to wallets.");

        // 2. Automatically trigger Razorpay Payouts for released escrows
        for (const mature of releasedMatures) {
          const {storeId, amount, escrowId} = mature;

          if (!bankDetailsMap[storeId]) {
            console.log("[ESCROW][SCHEDULED] Skipping auto-payout: No bank account linked for seller:", storeId);
            continue;
          }

          console.log("[ESCROW][SCHEDULED] Initiating auto-payout of ₹", amount, "for seller:", storeId);

          const payoutId = db.collection("payouts").doc().id;
          const payoutRef = db.collection("payouts").doc(payoutId);

          // Pre-create the payout in 'processing' status
          await payoutRef.set({
            id: payoutId,
            storeId: storeId,
            bankAccountId: "primary",
            amount: amount,
            currency: "INR",
            status: "processing",
            requestedAt: admin.firestore.FieldValue.serverTimestamp(),
            processedAt: null,
            isAutoPayout: true,
            referenceEscrowId: escrowId,
          });

          try {
            // Trigger actual Razorpay transfer
            const payoutResult = await performRazorpayPayout(storeId, amount, payoutId, db);

            // If success, commit the balance decrement & finalize status
            await db.runTransaction(async (txn) => {
              const serverNowWrite = admin.firestore.FieldValue.serverTimestamp();
              const walletRef = db.collection("wallets").doc(storeId);

              // Validate balance before decrementing
              const walletDoc = await txn.get(walletRef);
              const balance = walletDoc.exists ? (walletDoc.data().balance || 0) : 0;

              if (balance < amount) {
                throw new Error("Insufficient wallet balance for automated payout");
              }

              // Decrement wallet balance
              txn.update(walletRef, {
                balance: admin.firestore.FieldValue.increment(-amount),
                updatedAt: serverNowWrite,
              });

              // Complete payout document
              txn.update(payoutRef, {
                status: "completed",
                processedAt: serverNowWrite,
                updatedAt: serverNowWrite,
                razorpayPayoutId: payoutResult.payoutId || null,
                payoutMode: payoutResult.mode,
              });

              // Log the transaction
              const transactionRef = db.collection("transactions").doc();
              txn.set(transactionRef, {
                id: transactionRef.id,
                referenceId: payoutId,
                storeId,
                type: "payout",
                status: "completed",
                amount,
                currency: "INR",
                description: `Auto-payout completed for ${payoutId}`,
                createdAt: serverNowWrite,
                completedAt: serverNowWrite,
                razorpayPayoutId: payoutResult.payoutId || null,
              });

              // Notify the seller
              const notifRef = db.collection("users").doc(storeId)
                  .collection("notifications").doc();
              txn.set(notifRef, {
                title: "💸 Auto-Payout Completed",
                body: `An automatic payout of ₹${amount.toFixed(2)} has been successfully processed to your bank.`,
                type: "payout_completed",
                deepLinkPath: "/seller/wallet",
                isRead: false,
                createdAt: serverNowWrite,
              });

              console.log("[ESCROW][SCHEDULED][SUCCESS] Auto-payout completed for seller:", storeId,
                  "| amount: ₹", amount, "| payoutId:", payoutId);
            });
          } catch (payoutErr) {
            console.error("[ESCROW][SCHEDULED][ERROR] Auto-payout failed for seller:", storeId,
                "| error:", payoutErr.message);

            // Update status to failed so admin can review and manual-retry
            await payoutRef.update({
              status: "failed",
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              failureReason: payoutErr.message,
            });

            // Notify seller of failed transfer
            await db.collection("users").doc(storeId).collection("notifications").add({
              title: "⚠️ Auto-Payout Failed",
              body: `Auto-payout of ₹${amount.toFixed(2)} failed: ${payoutErr.message}. Admin will retry soon.`,
              type: "payout_failed",
              deepLinkPath: "/seller/wallet",
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        return null;
      } catch (error) {
        console.error("[ESCROW][SCHEDULED][ERROR] Scheduler failed:", error);
        return null;
      }
    },
);

// ---------------------------------------------------------------------------
// S2. checkAbandonedCarts — notify buyers with stale carts every 24 hours
// ---------------------------------------------------------------------------
exports.checkAbandonedCarts = onSchedule(
    {schedule: "every 24 hours", region: "us-central1"},
    async () => {
      const db = admin.firestore();
      const oneDayAgo = new Date();
      oneDayAgo.setHours(oneDayAgo.getHours() - 24);

      const cartsSnapshot = await db.collectionGroup("cart")
          .where("updatedAt", "<", admin.firestore.Timestamp.fromDate(oneDayAgo))
          .get();

      if (cartsSnapshot.empty) return null;

      const batch = db.batch();
      const notifiedUsers = new Set();
      let count = 0;

      for (const doc of cartsSnapshot.docs) {
        const userRef = doc.ref.parent.parent;
        if (!userRef || notifiedUsers.has(userRef.id)) continue;
        notifiedUsers.add(userRef.id);
        const notifRef = userRef.collection("notifications").doc();
        batch.set(notifRef, {
          title: "You left something behind!",
          body: "Items in your cart are waiting for you. Complete your purchase now.",
          type: "abandoned_cart",
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        count++;
      }

      if (count > 0) {
        await batch.commit();
        console.log(`[ABANDONED CARTS] Sent ${count} reminders.`);
      }
      return null;
    },
);
