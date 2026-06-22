'use strict';

const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();

const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');

// ---------------------------------------------------------------------------
// HELPER: Verify Firebase ID Token from Authorization header
// ---------------------------------------------------------------------------
async function verifyAuth(req, res) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.error('[AUTH][ERROR] Missing or malformed Authorization header.');
    res.status(401).json({error: 'Unauthorized: missing auth token.'});
    return null;
  }
  const token = authHeader.split('Bearer ')[1];
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    console.log('[AUTH] Token verified. uid:', decoded.uid);
    return decoded;
  } catch (e) {
    console.error('[AUTH][ERROR] Token verification failed:', e.message);
    res.status(401).json({error: 'Unauthorized: invalid token.'});
    return null;
  }
}

// ---------------------------------------------------------------------------
// 1. getRazorpayKey — returns public Razorpay key ID to the client
// ---------------------------------------------------------------------------
exports.getRazorpayKey = onRequest(
    {
      cors: true,
      secrets: [RAZORPAY_KEY_ID],
      timeoutSeconds: 15,
    },
    (req, res) => {
      const ts = new Date().toISOString();
      console.log('[FUNCTION][getRazorpayKey] Request received at', ts);

      const key = RAZORPAY_KEY_ID.value();
      if (!key || key.trim() === '') {
        console.error('[RAZORPAY][ERROR] RAZORPAY_KEY_ID secret is empty or not set.');
        return res.status(500).json({error: 'Payment system not configured. Contact support.'});
      }

      console.log('[RAZORPAY] Serving key ID (prefix):', key.substring(0, 12) + '...');
      return res.json({key: key.trim()});
    },
);

// ---------------------------------------------------------------------------
// 2. createRazorpayOrder — creates a server-side Razorpay order
//    POST body: { amount: <paise int>, currency: 'INR', receipt: 'optional' }
//    Returns:   { id, amount, currency }
// ---------------------------------------------------------------------------
exports.createRazorpayOrder = onRequest(
    {
      cors: true,
      secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET],
      timeoutSeconds: 30,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log('[FUNCTION][createRazorpayOrder] Request received at', ts);

      if (req.method !== 'POST') {
        return res.status(405).json({error: 'Method not allowed. Use POST.'});
      }

      // --- Auth ---
      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      // --- Validate input ---
      const {amount, currency = 'INR', receipt} = req.body;

      if (!amount || typeof amount !== 'number' || !Number.isInteger(amount) || amount < 100) {
        console.error('[RAZORPAY][ERROR] Invalid amount:', amount, '(must be integer paise >= 100)');
        return res.status(400).json({error: 'Invalid amount. Minimum ₹1 (100 paise).'});
      }

      // --- Secrets ---
      const keyId = RAZORPAY_KEY_ID.value();
      const keySecret = RAZORPAY_KEY_SECRET.value();
      if (!keyId || !keySecret) {
        console.error('[RAZORPAY][ERROR] Razorpay secrets not configured.');
        return res.status(500).json({error: 'Payment system not configured. Contact support.'});
      }

      const rzp = new Razorpay({key_id: keyId, key_secret: keySecret});
      const receiptId = receipt || `rcpt_${decoded.uid.substring(0, 8)}_${Date.now()}`;

      console.log('[RAZORPAY] Creating order: amount=', amount, 'paise, currency=', currency,
          ', receipt=', receiptId, ', buyerUid=', decoded.uid);

      try {
        const rzpOrder = await rzp.orders.create({
          amount: amount,
          currency: currency,
          receipt: receiptId,
          payment_capture: 1,
        });

        console.log('[RAZORPAY][SUCCESS] Order created. razorpay_order_id:', rzpOrder.id,
            '| amount:', rzpOrder.amount, '| ts:', ts, '| buyerUid:', decoded.uid);

        return res.json({
          id: rzpOrder.id,
          amount: rzpOrder.amount,
          currency: rzpOrder.currency,
        });
      } catch (e) {
        console.error('[RAZORPAY][ERROR] orders.create failed:', e.message,
            '| error detail:', JSON.stringify(e.error || {}));
        return res.status(500).json({
          error: 'Failed to create payment order. Please try again.',
        });
      }
    },
);

// ---------------------------------------------------------------------------
// 3. verifyAndFinalizePayment — HMAC verification + atomic Firestore writes
//    POST body:
//      razorpay_payment_id, razorpay_order_id, razorpay_signature
//      buyerId, buyerName, deliveryAddress
//      orders: Array<{ storeId, storeName, items, subtotal, deliveryFee,
//                       platformFee, totalAmount, paymentMethod }>
//    Returns: { success: true, orderIds: string[] }
// ---------------------------------------------------------------------------
exports.verifyAndFinalizePayment = onRequest(
    {
      cors: true,
      secrets: [RAZORPAY_KEY_SECRET],
      timeoutSeconds: 60,
    },
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log('[FUNCTION][verifyAndFinalizePayment] Request received at', ts);

      if (req.method !== 'POST') {
        return res.status(405).json({error: 'Method not allowed. Use POST.'});
      }

      // --- Auth ---
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
      } = req.body;

      // --- Validate caller is the actual buyer ---
      if (!buyerId || decoded.uid !== buyerId) {
        console.error('[PAYMENT][SECURITY] UID mismatch. token.uid:', decoded.uid,
            '| requested buyerId:', buyerId);
        return res.status(403).json({error: 'Forbidden: buyer ID mismatch.'});
      }

      // --- Input validation ---
      if (!paymentId || !rzpOrderId || !signature) {
        console.error('[PAYMENT][ERROR] Missing payment identifiers.',
            {paymentId, rzpOrderId, sigPresent: !!signature});
        return res.status(400).json({error: 'Missing payment identifiers.'});
      }
      if (!orders || !Array.isArray(orders) || orders.length === 0) {
        console.error('[PAYMENT][ERROR] Missing or empty orders array for buyer:', buyerId);
        return res.status(400).json({error: 'No orders provided.'});
      }
      if (!deliveryAddress) {
        return res.status(400).json({error: 'Delivery address is required.'});
      }

      // ─── STEP 1: HMAC-SHA256 Signature Verification ────────────────────────
      console.log('[PAYMENT] Verifying HMAC-SHA256 signature for paymentId:', paymentId,
          '| rzpOrderId:', rzpOrderId);

      const keySecret = RAZORPAY_KEY_SECRET.value();
      if (!keySecret) {
        console.error('[PAYMENT][ERROR] RAZORPAY_KEY_SECRET not configured.');
        return res.status(500).json({error: 'Payment verification system not configured.'});
      }

      const expectedSignature = crypto
          .createHmac('sha256', keySecret)
          .update(`${rzpOrderId}|${paymentId}`)
          .digest('hex');

      if (expectedSignature !== signature) {
        console.error('[PAYMENT][SECURITY] Signature MISMATCH.',
            '| expected:', expectedSignature,
            '| received:', signature,
            '| paymentId:', paymentId,
            '| buyerId:', buyerId,
            '| ts:', ts);
        return res.status(400).json({
          error: 'Payment verification failed: invalid signature. This incident has been logged.',
        });
      }

      console.log('[PAYMENT][SUCCESS] Signature verified.',
          '| paymentId:', paymentId, '| rzpOrderId:', rzpOrderId, '| buyerId:', buyerId);

      // ─── STEP 2: Atomic Firestore Transaction ──────────────────────────────
      const db = admin.firestore();
      const orderIds = [];

      try {
        await db.runTransaction(async (txn) => {
          // ── 2a. PHASE 1 — ALL READS FIRST ──
          // Firestore transactions require every txn.get() to happen before
          // any txn.set()/txn.update()/txn.delete(). The previous version
          // interleaved a get() + two update()s per item inside one loop,
          // so the *second* item's read ran after the *first* item's write
          // and Firestore rejected the whole transaction. We now do a single
          // read pass — deduplicating by productId in case the same product
          // appears more than once across the order list — and only start
          // writing once every read has completed.
          console.log('[FIRESTORE] Reading catalog docs for', orders.length, 'order(s)...');

          const stockEntries = new Map(); // productId -> { catalogRef, storeProductRef, title, totalQty }

          for (const order of orders) {
            for (const item of order.items) {
              const existing = stockEntries.get(item.productId);
              if (existing) {
                existing.totalQty += item.quantity;
                continue;
              }
              stockEntries.set(item.productId, {
                catalogRef: db.collection('catalog').doc(item.productId),
                storeProductRef: db.collection('stores')
                    .doc(order.storeId)
                    .collection('products')
                    .doc(item.productId),
                title: item.title,
                totalQty: item.quantity,
              });
            }
          }

          for (const [productId, entry] of stockEntries) {
            const catalogDoc = await txn.get(entry.catalogRef);

            if (!catalogDoc.exists) {
              throw new Error(`Product not found in catalog: "${entry.title}" (${productId})`);
            }

            const data = catalogDoc.data();
            const metadata = data.metadata || {};
            const currentStock = typeof metadata.stock === 'number' ? metadata.stock : 0;

            console.log('[FIRESTORE] Stock check — productId:', productId,
                '| currentStock:', currentStock, '| requested:', entry.totalQty);

            if (currentStock < entry.totalQty) {
              throw new Error(
                  `Insufficient stock for "${entry.title}". ` +
                  `Available: ${currentStock}, Requested: ${entry.totalQty}.`,
              );
            }

            entry.currentStock = currentStock;
            entry.status = data.status || 'active';
          }

          // ── 2b. PHASE 2 — ALL WRITES ──
          const serverNow = admin.firestore.FieldValue.serverTimestamp();

          for (const [productId, entry] of stockEntries) {
            // Guard: never allow negative stock
            const newStock = Math.max(0, entry.currentStock - entry.totalQty);
            const newStatus = newStock <= 0 ? 'outOfStock' : entry.status;

            const stockUpdate = {
              'metadata.stock': newStock,
              'status': newStatus,
              'updatedAt': serverNow,
            };

            console.log('[FIRESTORE] Deducting stock — productId:', productId,
                '|', entry.currentStock, '→', newStock, '| newStatus:', newStatus);

            txn.update(entry.catalogRef, stockUpdate);
            txn.update(entry.storeProductRef, stockUpdate);
          }

          // ── 2c. Create order documents ──

          for (const order of orders) {
            const orderRef = db.collection('orders').doc();
            orderIds.push(orderRef.id);

            const orderDoc = {
              orderId: orderRef.id,
              buyerId: buyerId,
              buyerName: buyerName || '',
              storeId: order.storeId,
              storeName: order.storeName || '',
              status: 'pending',
              items: order.items.map((item) => ({
                productId: item.productId,
                title: item.title,
                imageUrl: item.imageUrl,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
              })),
              subtotal: order.subtotal,
              deliveryFee: order.deliveryFee,
              platformFee: order.platformFee,
              totalAmount: order.totalAmount,
              paymentMethod: order.paymentMethod || 'Online (Razorpay)',
              paymentStatus: 'completed',
              paymentId: paymentId,
              razorpayOrderId: rzpOrderId,
              deliveryAddress: deliveryAddress,
              createdAt: serverNow,
              updatedAt: serverNow,
            };

            console.log('[ORDER] Creating order document:', orderRef.id,
                '| buyerId:', buyerId,
                '| storeId:', order.storeId,
                '| amount: ₹', order.totalAmount,
                '| paymentId:', paymentId,
                '| ts:', ts);

            txn.set(orderRef, orderDoc);

            // ── 2d. In-app notifications ──
            const buyerNotifRef = db.collection('users')
                .doc(buyerId)
                .collection('notifications')
                .doc();

            txn.set(buyerNotifRef, {
              title: '✅ Order Placed Successfully',
              body: `Your order #${orderRef.id.substring(0, 8).toUpperCase()} ` +
                    `from ${order.storeName} has been placed. ` +
                    `Total: ₹${(order.totalAmount || 0).toFixed(2)}`,
              deepLinkPath: `/buyer/orders/${orderRef.id}`,
              isRead: false,
              createdAt: serverNow,
            });

            const sellerNotifRef = db.collection('users')
                .doc(order.storeId)
                .collection('notifications')
                .doc();

            txn.set(sellerNotifRef, {
              title: '🛍️ New Order Received',
              body: `New order from ${buyerName}. ` +
                    `Order #${orderRef.id.substring(0, 8).toUpperCase()}. ` +
                    `Amount: ₹${(order.totalAmount || 0).toFixed(2)}`,
              deepLinkPath: `/seller/orders/${orderRef.id}`,
              isRead: false,
              createdAt: serverNow,
            });
          }
        });

        console.log('[SUCCESS][verifyAndFinalizePayment] Transaction committed.',
            '| orderIds:', orderIds.join(', '),
            '| buyerId:', buyerId,
            '| paymentId:', paymentId,
            '| ts:', ts);

        // ─── STEP 3: Clear buyer cart (non-transactional, non-fatal) ──────────
        try {
          console.log('[CART] Clearing cart for buyer:', buyerId);
          const cartRef = db.collection('users').doc(buyerId).collection('cart');
          const cartSnap = await cartRef.get();

          if (!cartSnap.empty) {
            const batch = db.batch();
            cartSnap.docs.forEach((doc) => batch.delete(doc.ref));
            await batch.commit();
            console.log('[CART][SUCCESS] Cart cleared for buyer:', buyerId,
                '| items removed:', cartSnap.size);
          } else {
            console.log('[CART] Cart already empty for buyer:', buyerId);
          }
        } catch (cartErr) {
          // Order is already created — this is non-fatal. Log and continue.
          console.error('[CART][ERROR] Failed to clear cart for buyer:', buyerId,
              '| error:', cartErr.message,
              '| NOTE: Order was created successfully. Cart will be cleared by client.');
        }

        return res.json({success: true, orderIds});
      } catch (txnError) {
        console.error('[FIRESTORE][ERROR] Transaction failed.',
            '| error:', txnError.message,
            '| paymentId:', paymentId,
            '| buyerId:', buyerId,
            '| ts:', ts);
        return res.status(500).json({
          error: txnError.message ||
            'Order creation failed after payment. Please contact support with your payment ID.',
          paymentId: paymentId,
        });
      }
    },
);