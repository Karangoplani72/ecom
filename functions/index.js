'use strict';

const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const PDFDocument = require('pdfkit');

admin.initializeApp();

const RAZORPAY_KEY_ID = defineSecret('RAZORPAY_KEY_ID');
const RAZORPAY_KEY_SECRET = defineSecret('RAZORPAY_KEY_SECRET');

// ---------------------------------------------------------------------------
// HELPER: Verify Firebase ID Token from Authorization header
// ---------------------------------------------------------------------------
async function verifyAuth(req, res) {
  // 1. App Check Verification
  const appCheckToken = req.header('X-Firebase-AppCheck');
  if (!appCheckToken) {
    console.error('[APP CHECK][ERROR] Missing App Check token.');
    res.status(401).json({error: 'Unauthorized: missing App Check token.'});
    return null;
  }
  try {
    await admin.appCheck().verifyToken(appCheckToken);
  } catch (err) {
    console.error('[APP CHECK][ERROR] Invalid App Check token:', err.message);
    res.status(401).json({error: 'Unauthorized: invalid App Check token.'});
    return null;
  }

  // 2. User Auth Verification
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
    async (req, res) => {
      const ts = new Date().toISOString();
      console.log('[FUNCTION][getRazorpayKey] Request received at', ts);

      // App Check Verification
      const appCheckToken = req.header('X-Firebase-AppCheck');
      if (!appCheckToken) {
        console.error('[APP CHECK][ERROR] Missing App Check token.');
        return res.status(401).json({error: 'Unauthorized: missing App Check token.'});
      }
      try {
        await admin.appCheck().verifyToken(appCheckToken);
      } catch (err) {
        console.error('[APP CHECK][ERROR] Invalid App Check token:', err.message);
        return res.status(401).json({error: 'Unauthorized: invalid App Check token.'});
      }

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

function isFlashSaleActive(itemData) {
  const metadata = itemData.metadata || {};
  if (metadata.isFlashDeal !== true) return false;
  if (metadata.flashSaleStatus && metadata.flashSaleStatus !== 'active') return false;

  const startsAt = metadata.flashSaleStartsAt;
  const endsAt = metadata.flashSaleEndsAt;
  if (!startsAt || !endsAt) return false;

  const start = startsAt.toDate ? startsAt.toDate() : (startsAt._seconds ? new Date(startsAt._seconds * 1000) : new Date(startsAt));
  const end = endsAt.toDate ? endsAt.toDate() : (endsAt._seconds ? new Date(endsAt._seconds * 1000) : new Date(endsAt));
  const now = new Date();
  return now >= start && now <= end;
}

function getEffectivePrice(itemData) {
  const basePrice = parseFloat(itemData.basePrice) || 0;
  if (!isFlashSaleActive(itemData)) return basePrice;
  const metadata = itemData.metadata || {};
  const percent = parseFloat(metadata.flashSaleDiscountPercent) || 0;
  return basePrice * (1.0 - percent);
}

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
            entry.catalogData = data;
          }

          // --- Load platform commission rate ---
          const configRef = db.collection('platform_settings').doc('global_config');
          const configDoc = await txn.get(configRef);
          let defaultCommissionRate = 0.085;
          if (configDoc.exists) {
            defaultCommissionRate = parseFloat(configDoc.data().defaultCommissionRate) || 0.085;
          }
          console.log('[CONFIG] Loaded platform defaultCommissionRate:', defaultCommissionRate);

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

          // ── 2c. Create order documents, transaction logs & update wallets ──

          for (const order of orders) {
            const orderRef = db.collection('orders').doc();
            orderIds.push(orderRef.id);

            let orderSubtotal = 0;
            let orderPlatformFee = 0;
            let orderVendorPayout = 0;

            const orderItems = order.items.map((item) => {
              const entry = stockEntries.get(item.productId);
              const catalogData = entry.catalogData;
              const originalPrice = parseFloat(catalogData.basePrice) || 0;
              const effectivePrice = getEffectivePrice(catalogData);
              const qty = parseInt(item.quantity) || 1;

              const isSale = isFlashSaleActive(catalogData);
              const metadata = catalogData.metadata || {};
              const sponsor = metadata.flashSaleSponsor || 'seller';

              let itemPlatformFee = 0;
              let itemPayout = 0;

              if (isSale && sponsor === 'admin') {
                // Admin sponsored
                itemPlatformFee = (originalPrice * defaultCommissionRate) - (originalPrice - effectivePrice);
                itemPayout = originalPrice * (1.0 - defaultCommissionRate);
              } else {
                // Seller sponsored or no active sale
                itemPlatformFee = effectivePrice * defaultCommissionRate;
                itemPayout = effectivePrice * (1.0 - defaultCommissionRate);
              }

              orderSubtotal += effectivePrice * qty;
              orderPlatformFee += itemPlatformFee * qty;
              orderVendorPayout += itemPayout * qty;

              return {
                productId: item.productId,
                title: item.title,
                imageUrl: item.imageUrl,
                quantity: qty,
                unitPrice: effectivePrice,
              };
            });

            const orderDeliveryFee = orderSubtotal < 1000 ? 99.0 : 0.0;
            const orderTotalAmount = orderSubtotal + orderDeliveryFee + orderPlatformFee;

            const orderDoc = {
              orderId: orderRef.id,
              buyerId: buyerId,
              buyerName: buyerName || '',
              storeId: order.storeId,
              storeName: order.storeName || '',
              status: 'pending',
              items: orderItems,
              subtotal: orderSubtotal,
              deliveryFee: orderDeliveryFee,
              platformFee: orderPlatformFee,
              totalAmount: orderTotalAmount,
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
                '| calculated amount: ₹', orderTotalAmount,
                '| payout: ₹', orderVendorPayout,
                '| platformFee: ₹', orderPlatformFee,
                '| paymentId:', paymentId);

            txn.set(orderRef, orderDoc);

            // Log payment transaction record
            const transactionRef = db.collection('transactions').doc();
            const transactionDoc = {
              id: transactionRef.id,
              orderId: orderRef.id,
              referenceId: orderRef.id,
              buyerId: buyerId,
              storeId: order.storeId,
              type: 'sale',
              status: 'completed',
              gateway: 'razorpay',
              externalTransactionId: paymentId,
              grossAmount: orderSubtotal,
              platformCommission: orderPlatformFee,
              netVendorPayout: orderVendorPayout,
              amount: orderVendorPayout,
              currency: 'INR',
              description: `Order placement for ${orderRef.id}`,
              createdAt: serverNow,
              completedAt: serverNow,
            };
            txn.set(transactionRef, transactionDoc);

            // Update merchant wallet. Use atomic increments so the transaction
            // does not need reads after the stock/order writes.
            const walletRef = db.collection('wallets').doc(order.storeId);
            txn.set(walletRef, {
              storeId: order.storeId,
              balance: admin.firestore.FieldValue.increment(0),
              pendingEscrowBalance: admin.firestore.FieldValue.increment(orderVendorPayout),
              currency: 'INR',
              updatedAt: serverNow
            }, { merge: true });

            // Create escrow document for 10 days auto-release
            const escrowRef = db.collection('escrows').doc();
            txn.set(escrowRef, {
              id: escrowRef.id,
              orderId: orderRef.id,
              storeId: order.storeId,
              amount: orderVendorPayout,
              status: 'pending',
              releaseAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 10 * 24 * 60 * 60 * 1000)), // 10 days
              createdAt: serverNow,
              updatedAt: serverNow
            });

            // ── 2d. In-app notifications ──
            const buyerNotifRef = db.collection('users')
                .doc(buyerId)
                .collection('notifications')
                .doc();

            txn.set(buyerNotifRef, {
              title: '✅ Order Placed Successfully',
              body: `Your order #${orderRef.id.substring(0, 8).toUpperCase()} ` +
                    `from ${order.storeName} has been placed. ` +
                    `Total: ₹${(orderTotalAmount || 0).toFixed(2)}`,
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
                    `Amount: ₹${(orderTotalAmount || 0).toFixed(2)}`,
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

exports.releaseMaturedEscrows = onRequest(
    { cors: true, timeoutSeconds: 60 },
    async (req, res) => {
      const db = admin.firestore();
      const now = new Date();
      const serverNow = admin.firestore.FieldValue.serverTimestamp();

      try {
        const maturedEscrowsSnap = await db.collection('escrows')
            .where('status', '==', 'pending')
            .where('releaseAt', '<=', now)
            .get();

        if (maturedEscrowsSnap.empty) {
          return res.json({ success: true, releasedCount: 0 });
        }

        const releasedIds = [];
        await db.runTransaction(async (txn) => {
          for (const doc of maturedEscrowsSnap.docs) {
            const escrow = doc.data();
            const storeId = escrow.storeId;
            const amount = escrow.amount;

            // Update wallet with atomic increments. This avoids transaction
            // reads after writes when multiple escrow records are processed.
            const walletRef = db.collection('wallets').doc(storeId);
            txn.set(walletRef, {
              balance: admin.firestore.FieldValue.increment(amount),
              pendingEscrowBalance: admin.firestore.FieldValue.increment(-amount),
              updatedAt: serverNow
            }, { merge: true });

            // Update escrow doc
            txn.update(doc.ref, {
              status: 'released',
              updatedAt: serverNow
            });

            // Log transaction of type adjustment
            const transactionRef = db.collection('transactions').doc();
            txn.set(transactionRef, {
              id: transactionRef.id,
              orderId: escrow.orderId,
              referenceId: escrow.id,
              storeId: storeId,
              type: 'adjustment',
              status: 'completed',
              amount: amount,
              currency: 'INR',
              description: `Escrow release for order ${escrow.orderId}`,
              createdAt: serverNow,
              completedAt: serverNow
            });

            releasedIds.push(doc.id);
          }
        });

        console.log('[ESCROW] Successfully released', releasedIds.length, 'escrows.');
        return res.json({ success: true, releasedCount: releasedIds.length, releasedIds });
      } catch (error) {
        console.error('[ESCROW][ERROR] Failed to release matured escrows:', error);
        return res.status(500).json({ error: error.message });
      }
    }
);

// ---------------------------------------------------------------------------
// 4. aggregateProductReviews — updates avgRating and reviewCount on product
// ---------------------------------------------------------------------------
const { onDocumentWritten, onDocumentUpdated } = require('firebase-functions/v2/firestore');

exports.aggregateProductReviews = onDocumentWritten('reviews/{reviewId}', async (event) => {
  const db = admin.firestore();
  
  // Get the product ID from the review document
  const reviewData = event.data.after.exists ? event.data.after.data() : event.data.before.data();
  const productId = reviewData.productId;

  if (!productId) {
    console.log('[REVIEWS] No productId found, skipping aggregation.');
    return null;
  }

  console.log('[REVIEWS] Aggregating reviews for product:', productId);

  try {
    const reviewsSnap = await db.collection('reviews').where('productId', '==', productId).get();
    
    let totalRating = 0;
    let reviewCount = 0;

    reviewsSnap.forEach(doc => {
      const data = doc.data();
      if (typeof data.rating === 'number') {
        totalRating += data.rating;
        reviewCount++;
      }
    });

    const avgRating = reviewCount > 0 ? (totalRating / reviewCount) : 0;

    // We must update the catalog product
    await db.collection('catalog').doc(productId).set({
      avgRating: avgRating,
      reviewCount: reviewCount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log('[REVIEWS][SUCCESS] Aggregated rating for product:', productId, '| avgRating:', avgRating, '| count:', reviewCount);
    return null;
  } catch (error) {
    console.error('[REVIEWS][ERROR] Failed to aggregate reviews:', error);
    return null;
  }
});

// ---------------------------------------------------------------------------
// 5. generateInvoicePDF — Generates a PDF invoice for a given order
// ---------------------------------------------------------------------------
exports.generateInvoicePDF = onRequest(
    { cors: true, timeoutSeconds: 30 },
    async (req, res) => {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed. Use POST.' });
      }

      const decoded = await verifyAuth(req, res);
      if (!decoded) return;

      const { orderId } = req.body;
      if (!orderId) {
        return res.status(400).json({ error: 'orderId is required.' });
      }

      const db = admin.firestore();
      try {
        const orderDoc = await db.collection('orders').doc(orderId).get();
        if (!orderDoc.exists) {
          return res.status(404).json({ error: 'Order not found.' });
        }

        const order = orderDoc.data();
        if (order.buyerId !== decoded.uid && order.storeId !== decoded.uid) {
          return res.status(403).json({ error: 'Forbidden: You do not have access to this order.' });
        }

        const doc = new PDFDocument({ margin: 50 });
        const buffers = [];
        doc.on('data', buffers.push.bind(buffers));
        
        // Build PDF
        doc.fontSize(20).text('INVOICE', { align: 'center' });
        doc.moveDown();
        doc.fontSize(12).text(`Order ID: ${order.orderId}`);
        doc.text(`Date: ${order.createdAt ? order.createdAt.toDate().toLocaleString() : new Date().toLocaleString()}`);
        doc.moveDown();
        doc.text(`Sold By: ${order.storeName}`);
        doc.text(`Billed To: ${order.buyerName}`);
        doc.text(`Address: ${order.deliveryAddress}`);
        doc.moveDown();
        
        doc.fontSize(14).text('Items', { underline: true });
        doc.moveDown(0.5);
        
        (order.items || []).forEach(item => {
          doc.fontSize(12).text(`${item.title} (x${item.quantity}) - Rs. ${(item.unitPrice * item.quantity).toFixed(2)}`);
        });
        
        doc.moveDown();
        doc.fontSize(12).text(`Subtotal: Rs. ${order.subtotal.toFixed(2)}`);
        doc.text(`Delivery Fee: Rs. ${order.deliveryFee.toFixed(2)}`);
        doc.text(`Platform Fee: Rs. ${order.platformFee.toFixed(2)}`);
        doc.moveDown();
        doc.fontSize(16).text(`Total Amount: Rs. ${order.totalAmount.toFixed(2)}`, { underline: true });

        doc.end();

        doc.on('end', () => {
          const pdfData = Buffer.concat(buffers);
          res.setHeader('Content-Type', 'application/pdf');
          res.setHeader('Content-Disposition', `attachment; filename="invoice_${orderId}.pdf"`);
          res.send(pdfData);
        });

      } catch (error) {
        console.error('[INVOICE][ERROR] Failed to generate invoice:', error);
        return res.status(500).json({ error: 'Failed to generate invoice.' });
      }
    }
);

// ---------------------------------------------------------------------------
// 6. checkLowStock — Triggers when catalog stock updates
// ---------------------------------------------------------------------------
exports.checkLowStock = onDocumentUpdated(
    { document: 'catalog/{docId}', region: 'asia-south1' },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();

      if (!before || !after) return null;

      const beforeStock = before.metadata && before.metadata.stock ? before.metadata.stock : 0;
      const afterStock = after.metadata && after.metadata.stock ? after.metadata.stock : 0;

      // Only trigger if stock dropped and is now below/equal to 5
      const LOW_STOCK_THRESHOLD = 5;
      if (afterStock <= LOW_STOCK_THRESHOLD && beforeStock > LOW_STOCK_THRESHOLD) {
        const storeId = after.storeId;
        const title = after.title;

        const db = admin.firestore();
        
        // Notify seller about low stock
        await db.collection('users').doc(storeId).collection('notifications').add({
          title: 'Low Stock Alert',
          body: `Product "${title}" has low stock (${afterStock} remaining).`,
          type: 'stock_alert',
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          data: {
            productId: event.params.docId,
            stock: afterStock
          }
        });

        console.log(`[STOCK] Low stock alert created for product ${event.params.docId}`);
      }

      return null;
    }
);

// ---------------------------------------------------------------------------
// 7. updateSearchKeywords — Triggers when catalog is written
// ---------------------------------------------------------------------------
exports.updateSearchKeywords = onDocumentWritten(
    { document: 'catalog/{docId}', region: 'asia-south1' },
    async (event) => {
      if (!event.data.after.exists) return null;
      const data = event.data.after.data();
      const title = data.title || '';
      const description = data.description || '';
      const category = (data.metadata && data.metadata.category) || '';
      
      const text = `${title} ${description} ${category}`.toLowerCase();
      const keywords = [...new Set(text.split(/[^a-z0-9]/).filter(w => w.length > 2))].slice(0, 10);
      
      const currentKeywords = data.searchKeywords || [];
      if (JSON.stringify(keywords) !== JSON.stringify(currentKeywords)) {
        await event.data.after.ref.update({ searchKeywords: keywords });
        console.log(`[SEARCH] Updated keywords for ${event.params.docId}`);
      }
      return null;
    }
);

// ---------------------------------------------------------------------------
// 8. checkAbandonedCarts — Scans for abandoned carts
// ---------------------------------------------------------------------------
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.checkAbandonedCarts = onSchedule(
    { schedule: 'every 24 hours', region: 'asia-south1' },
    async (event) => {
      const db = admin.firestore();
      const oneDayAgo = new Date();
      oneDayAgo.setHours(oneDayAgo.getHours() - 24);

      // Cart items live under users/{uid}/cart. Query the collection group for
      // stale item docs, then notify each distinct owner once.
      const cartsSnapshot = await db.collectionGroup('cart')
          .where('updatedAt', '<', admin.firestore.Timestamp.fromDate(oneDayAgo))
          .get();

      if (cartsSnapshot.empty) return null;

      const batch = db.batch();
      const notifiedUsers = new Set();
      let count = 0;

      for (const doc of cartsSnapshot.docs) {
        const userRef = doc.ref.parent.parent;
        if (!userRef || notifiedUsers.has(userRef.id)) continue;
        notifiedUsers.add(userRef.id);
        const notifRef = userRef.collection('notifications').doc();
        batch.set(notifRef, {
          title: 'You left something behind!',
          body: 'Items in your cart are waiting for you. Complete your purchase now.',
          type: 'abandoned_cart',
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
    }
);
