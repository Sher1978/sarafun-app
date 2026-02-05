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
// 3. Telegram Authentication (Callable)
// ============================================================================

export const authenticateTelegram = functions.https.onCall(async (data, context) => {
    // 1. The "First Breath" Log
    console.log("🚀 authenticateTelegram called with data:", JSON.stringify(data));

    try {
        // 2. Defensive input check
        if (!data || !data.initData) {
            throw new functions.https.HttpsError("invalid-argument", "Missing initData");
        }

        // 2b. URL Decode if necessary (Client might send encoded string)
        if (initData.includes("%")) {
            try {
                initData = decodeURIComponent(initData);
                console.log("decoded initData:", initData);
            } catch (e) {
                console.warn("Failed to decodeURIComponent initData", e);
            }
        }

        // 3. Validate Telegram Hash
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
