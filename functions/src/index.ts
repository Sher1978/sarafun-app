import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";

admin.initializeApp();

const db = admin.firestore();
const fcm = admin.messaging();

/**
 * Scheduled function to check master balances and manage visibility/notifications.
 * Runs every hour.
 */
export const checkMasterBalances = functions.pubsub
    .schedule("every 1 hours")
    .onRun(async (context) => {
        const mastersSnapshot = await db
            .collection("users")
            .where("role", "==", "master")
            .get();

        const now = admin.firestore.Timestamp.now();
        const nowMs = now.toMillis();

        for (const masterDoc of mastersSnapshot.docs) {
            const masterData = masterDoc.data();
            const masterId = masterDoc.id;
            const depositBalance = masterData.depositBalance || 0;

            // 1. Calculate Threshold: 20% of the most expensive service
            const servicesSnapshot = await db
                .collection("service_cards")
                .where("master_id", "==", masterId)
                .where("is_active", "==", true)
                .get();

            let maxPrice = 0;
            servicesSnapshot.forEach((doc) => {
                const price = doc.data().price_stars || 0;
                if (price > maxPrice) maxPrice = price;
            });

            const threshold = maxPrice * 0.2;
            const isBelowThreshold = depositBalance < threshold;

            if (isBelowThreshold) {
                // Handle Low Balance state
                let lowBalanceSince = masterData.lowBalanceSince;

                if (!lowBalanceSince) {
                    // First time dropping below threshold
                    lowBalanceSince = now;
                    await masterDoc.ref.update({ lowBalanceSince: now });
                }

                const elapsedHours = (nowMs - lowBalanceSince.toMillis()) / (1000 * 60 * 60);

                // 24-6-1 Notification Rule + Hiding
                if (elapsedHours >= 24) {
                    // Hide master if not already hidden
                    if (masterData.isVisible !== false) {
                        await masterDoc.ref.update({ isVisible: false });
                        await logToSystem(masterId, "VISIBLE_HIDDEN", `Master hidden due to low balance for >24h. Balance: ${depositBalance}, Threshold: ${threshold}`);
                        await sendPushNotification(masterId, "Profile Hidden", "Your business is now offline due to low balance. Top up to resume service.");
                    }
                } else if (elapsedHours >= 23 && elapsedHours < 24) {
                    // 1 hour before hiding
                    await sendPushNotification(masterId, "Final Warning", "1 hour left. Your business is about to go offline. Top up now!");
                } else if (elapsedHours >= 18 && elapsedHours < 19) {
                    // 6 hours before hiding (approximately at the 18th hour of being low balance)
                    await sendPushNotification(masterId, "Urgent Notice", "Only 6 hours left until your profile is hidden from clients!");
                } else if (elapsedHours >= 0 && elapsedHours < 1) {
                    // Just started grace period
                    await sendPushNotification(masterId, "Low Balance Alert", "Your profile will be hidden in 24h. Top up now to stay visible.");
                }
            } else {
                // Balance is healthy
                if (masterData.lowBalanceSince) {
                    await masterDoc.ref.update({ lowBalanceSince: null });
                }

                if (masterData.isVisible === false) {
                    await masterDoc.ref.update({ isVisible: true });
                    await logToSystem(masterId, "VISIBLE_RESTORED", `Master visibility restored. Balance: ${depositBalance}, Threshold: ${threshold}`);
                    await sendPushNotification(masterId, "Business Online", "Your balance is healthy! Your profile is now visible to clients.");
                }
            }
        }

        return null;
    });

/**
 * Helper to log visibility changes.
 */
async function logToSystem(masterId: string, type: string, message: string) {
    await db.collection("system_logs").add({
        masterId,
        type,
        message,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Helper to send FCM notifications.
 * Assumes fcmToken is stored in the user document.
 */
async function sendPushNotification(uid: string, title: string, body: string) {
    const userDoc = await db.collection("users").doc(uid).get();
    const fcmToken = userDoc.data()?.fcmToken;

    if (fcmToken) {
        const message = {
            notification: { title, body },
            token: fcmToken,
        };
        try {
            await fcm.send(message);
            console.log(`Notification sent to ${uid}: ${title}`);
        } catch (error) {
            console.error(`Error sending notification to ${uid}:`, error);
        }
    }
}

/**
 * Authenticates a Telegram user using initData.
 * Returns a Firebase Custom Token.
 */
export const authenticateTelegram = functions.https.onCall(async (data, context) => {
    const initData = data.initData;
    if (!initData) {
        throw new functions.https.HttpsError("invalid-argument", "Missing initData");
    }

    const botToken = process.env.TELEGRAM_BOT_TOKEN;
    if (!botToken) {
        console.error("TELEGRAM_BOT_TOKEN not set in environment");
        throw new functions.https.HttpsError("internal", "Server configuration error");
    }

    // 1. Validate Telegram Hash
    const parsedData = new URLSearchParams(initData);
    const hash = parsedData.get("hash");
    parsedData.delete("hash");

    // Sort keys alphabetically
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
        throw new functions.https.HttpsError("unauthenticated", "Invalid Telegram hash");
    }

    // 2. Parse User Info
    const userJson = parsedData.get("user");
    if (!userJson) {
        throw new functions.https.HttpsError("invalid-argument", "User data not found in initData");
    }

    const telegramUser = JSON.parse(userJson);
    const telegramId = telegramUser.id.toString();

    // 3. Create or Update User in Firestore
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
        // Update display name/username if changed
        await userRef.update({
            displayName: telegramUser.first_name,
            username: telegramUser.username || "",
        });
    }

    // 4. Create Firebase Custom Token
    const customToken = await admin.auth().createCustomToken(telegramId);
    return { token: customToken };
});
