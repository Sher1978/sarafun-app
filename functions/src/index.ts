import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();
const db = admin.firestore();
const fcm = admin.messaging();

// ============================================================================
// 1. Solvency Check System (Reactive Triggers)
// ============================================================================

/**
 * Shared logic to check if a master is solvent.
 * Algorithm:
 * 1. Get Master's Deposit Balance.
 * 2. Get Max Price of their Active Services.
 * 3. Threshold = Max Price * 20%.
 * 4. isVisible = Balance >= Threshold.
 */
async function checkSolvency(masterId: string) {
    const masterRef = db.collection("users").doc(masterId);
    const masterDoc = await masterRef.get();

    if (!masterDoc.exists) return;
    const masterData = masterDoc.data();

    if (masterData?.role !== "master") return; // Only check masters

    const depositBalance = masterData?.depositBalance || 0;

    // Get all ACTIVE service cards for this master
    const servicesSnapshot = await db
        .collection("service_cards")
        .where("master_id", "==", masterId)
        .where("is_active", "==", true)
        .get();

    let maxServicePrice = 0;
    servicesSnapshot.forEach((doc) => {
        const price = doc.data().price_stars || 0;
        if (price > maxServicePrice) {
            maxServicePrice = price;
        }
    });

    // 20% rule
    const threshold = maxServicePrice * 0.20;
    const isSolvent = depositBalance >= threshold;

    if (masterData?.isVisible !== isSolvent) {
        console.log(`[Solvency] Updating Master ${masterId} -> isVisible: ${isSolvent} (Bal: ${depositBalance}, Thr: ${threshold})`);
        await masterRef.update({
            isVisible: isSolvent,
            solvencyThreshold: threshold, // Optional: useful for debugging
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Log to system and notify
        if (!isSolvent) {
            await logToSystem(masterId, "VISIBLE_HIDDEN", `Master hidden. Bal: ${depositBalance}, Thr: ${threshold}`);
            await sendPushNotification(masterId, "Profile Hidden", "Your business is offline due to low balance. Top up now.");
        } else {
            await logToSystem(masterId, "VISIBLE_RESTORED", `Master visible. Bal: ${depositBalance}, Thr: ${threshold}`);
            await sendPushNotification(masterId, "Back Online", "Your business is now visible to clients.");
        }
    }
}

/**
 * Trigger: On User Balance Change
 */
export const onUserBalanceChange = functions.firestore
    .document("users/{uid}")
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();
        if (newData.depositBalance === oldData.depositBalance) return;
        await checkSolvency(context.params.uid);
    });

/**
 * Trigger: On Service Card Write
 */
export const onServiceCardWrite = functions.firestore
    .document("service_cards/{cardId}")
    .onWrite(async (change, context) => {
        const newData = change.after.exists ? change.after.data() : null;
        const oldData = change.before.exists ? change.before.data() : null;
        const masterId = newData?.master_id || oldData?.master_id;
        if (!masterId) return;
        await checkSolvency(masterId);
    });


// ============================================================================
// 2. VIP Status Automation
// ============================================================================

/**
 * Trigger: On Deal Creation
 */
export const onDealCreate = functions.firestore
    .document("deals/{dealId}")
    .onCreate(async (snapshot, context) => {
        const deal = snapshot.data();
        const clientId = deal.clientId;

        if (!clientId) return;

        const now = new Date();
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(now.getDate() - 30);

        const dealsSnapshot = await db
            .collection("deals")
            .where("clientId", "==", clientId)
            .where("createdAt", ">=", thirtyDaysAgo.toISOString())
            .get();

        const dealCount = dealsSnapshot.size;
        const isVip = dealCount >= 10;

        await db.collection("users").doc(clientId).update({
            isVip: isVip,
            dealCountMonthly: dealCount,
            vipLastChecked: admin.firestore.FieldValue.serverTimestamp(),
        });
    });


// ============================================================================
// 3. Trust Circles & Reputation (ABCD)
// ============================================================================

/**
 * Trigger: On Review Creation
 * Updates author's trustScore if they are verified.
 */
export const onReviewCreate = functions.firestore
    .document("reviews/{reviewId}")
    .onWrite(async (change, context) => {
        const newData = change.after.exists ? change.after.data() : null;
        if (!newData) return; // Deleted

        const authorId = newData.authorId || newData.client_id;
        const serviceId = newData.serviceId || newData.service_id;

        // 1. Verify Purchase (Check if there's a deal between author and master for this service)
        const dealsSnapshot = await db.collection("deals")
            .where("clientId", "==", authorId)
            .where("serviceId", "==", serviceId)
            .limit(1)
            .get();

        const isVerified = !dealsSnapshot.empty;
        if (isVerified && !newData.is_verified_purchase) {
            await change.after.ref.update({ is_verified_purchase: true });
        }
    });

/**
 * Trigger: On Deal Completion
 * Rewards whoever recommended this service to the buyer.
 */
export const onDealRewarded = functions.firestore
    .document("deals/{dealId}")
    .onUpdate(async (change, context) => {
        const deal = change.after.data();
        const oldDeal = change.before.data();

        // Only fire when status moves to 'completed'
        if (deal.status !== "completed" || oldDeal.status === "completed") return;

        const buyerId = deal.clientId;
        const serviceId = deal.serviceId;

        // 1. Find all reviews for this service
        const reviewsSnapshot = await db.collection("reviews")
            .where("service_id", "==", serviceId)
            .where("is_verified_purchase", "==", true)
            .get();

        for (const doc of reviewsSnapshot.docs) {
            const review = doc.data();
            const authorId = review.authorId || review.client_id;
            if (authorId === buyerId) continue;

            // 2. Check if author is in buyer's C-1 or C-2 circle
            const buyerDoc = await db.collection("users").doc(buyerId).get();
            const buyerData = buyerDoc.data();
            const circles = buyerData?.trustCircles || {};

            const isC1 = circles.c1?.includes(authorId);
            const isC2 = circles.c2?.includes(authorId) ||
                buyerData?.referralPath?.includes(authorId) ||
                buyerData?.favoriteMasters?.includes(authorId);

            if (isC1 || isC2) {
                // REWARD AUTHOR
                let points = 10; // Base for recommendation
                const rating = review.total_score || review.rating;
                if (rating > 4) points += 5;
                if (rating < 3) points -= 20; // Adjusted per user request

                await db.collection("users").doc(authorId).update({
                    trustScore: admin.firestore.FieldValue.increment(points)
                });

                console.log(`[Trust] Rewarding user ${authorId} with ${points} pts for recommendation to ${buyerId}`);
                await logToSystem(authorId, "TRUST_REWARD", `Earned ${points} points for recommendation of service ${serviceId}`);
            }
        }
    });


// ============================================================================
// 3. Telegram Authentication (Callable)
// ============================================================================

export const authenticateTelegram = functions.https.onCall(async (data, context) => {
    // 1. The "First Breath" Log
    console.log("🚀 authenticateTelegram called with data:", JSON.stringify(data));
    // TODO: SHER, ВСТАВЬ СВОЙ ТОКЕН ОТ BOTFATHER СЮДА ДЛЯ ТЕСТА:
    const botToken = process.env.TELEGRAM_BOT_TOKEN || ""; // Замени на реальный токен или используй env
    if (!botToken) {
        console.error("CRITICAL ERROR: Telegram Bot Token is missing!");
        throw new functions.https.HttpsError("unauthenticated", "Bot token not configured on backend");
    }
    let initData = data.initData;

    try {
        // 2. Defensive input check
        if (!data || !data.initData) {
            throw new functions.https.HttpsError("invalid-argument", "Missing initData");
        }

        // 3. Validate Telegram Hash
        // NOTE: We do NOT use decodeURIComponent on the whole string here.
        // URLSearchParams will handle decoding of individual values correctly.
        const parsedData = new URLSearchParams(initData);
        const hash = parsedData.get("hash");
        parsedData.delete("hash");

        // Remove 'signature' if present (new Telegram format artifact)
        if (parsedData.has("signature")) {
            parsedData.delete("signature");
            console.log("Removed signature from check string");
        }

        const keys = Array.from(parsedData.keys()).sort();
        const dataCheckString = keys
            .map((key) => `${key}=${parsedData.get(key)}`)
            .join("\n");

        const secretKey = crypto.createHmac("sha256", "WebAppData")
            .update(botToken)
            .digest();

        const expectedHash = crypto.createHmac("sha256", secretKey)
            .update(dataCheckString)
            .digest("hex");

        if (hash !== expectedHash) {
            console.warn("❌ Invalid Telegram hash");
            console.warn("Received Hash:", hash);
            console.warn("Expected Hash:", expectedHash);
            console.warn("Data Check String:", dataCheckString);
            console.warn("Bot Token First 4 Chars:", botToken.substring(0, 4));
            throw new functions.https.HttpsError("unauthenticated", "Invalid Telegram hash");
        }

        // 4. Parse User Info
        const userJson = parsedData.get("user");
        if (!userJson) {
            throw new functions.https.HttpsError("invalid-argument", "User data not found in initData");
        }

        const telegramUser = JSON.parse(userJson);
        const telegramId = telegramUser.id.toString();

        // 5. Create or Update User
        const userRef = admin.firestore().collection("users").doc(telegramId);
        const userDoc = await userRef.get();

        if (!userDoc.exists) {
            await userRef.set({
                uid: telegramId,
                telegramId: telegramUser.id,
                displayName: telegramUser.first_name,
                username: telegramUser.username || "",
                role: "client",
                balanceStars: 0,
                depositBalance: 0,
                isVip: false,
                dealCountMonthly: 0,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        } else {
            // Update profile reading from latest TG data
            await userRef.update({
                displayName: telegramUser.first_name,
                username: telegramUser.username || "",
            });
        }

        // 6. Create Custom Token
        const customToken = await admin.auth().createCustomToken(telegramId);

        // Return result
        return { token: customToken };

    } catch (error: any) {
        console.error("🔥 CRASH inside authenticateTelegram:", error);
        // Re-throw HttpsErrors, wrap others
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", "Logic failed", error.toString());
    }
});


// Helper functions
async function logToSystem(masterId: string, type: string, message: string) {
    await db.collection("system_logs").add({
        masterId,
        type,
        message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

async function sendPushNotification(uid: string, title: string, body: string) {
    // Implementation placeholder or use fcm if token available
    const userDoc = await db.collection("users").doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;
    if (fcmToken) {
        try {
            await fcm.send({ token: fcmToken, notification: { title, body } });
        } catch (e) { console.error("FCM Error", e); }
    }
}
