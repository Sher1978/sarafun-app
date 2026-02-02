import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

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
