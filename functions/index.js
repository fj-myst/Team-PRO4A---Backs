const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

// ─── 1. Send FCM push when a new notification doc is created ─────────────────
//
// Triggers on: notifications/{notificationId} create
// Looks up the recipient's FCM token from users/{recipientUid}
// Sends a push notification via FCM

exports.sendPushOnNotification = onDocumentCreated(
  "notifications/{notificationId}",
  async (event) => {
    const notification = event.data?.data();
    if (!notification) return;

    const { recipientUid, type, announcementTitle, createdByName } =
      notification;

    if (!recipientUid || !announcementTitle) return;

    // Look up recipient's FCM token
    const userDoc = await db.collection("users").doc(recipientUid).get();
    if (!userDoc.exists) return;

    const fcmToken = userDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // Build notification content based on type
    const isEdited = type === "announcement_edited";
    const title = isEdited
      ? "Announcement Updated"
      : "You were mentioned in an announcement";
    const body = isEdited
      ? `${createdByName} edited "${announcementTitle}"`
      : `${createdByName} mentioned you in "${announcementTitle}"`;

    // Send FCM message
    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title, body },
        data: {
          type: type ?? "",
          announcementTitle: announcementTitle ?? "",
          createdByName: createdByName ?? "",
          notificationId: event.params.notificationId,
        },
        webpush: {
          notification: {
            title,
            body,
            icon: "/icons/Icon-192.png",
            badge: "/icons/Icon-192.png",
          },
          fcmOptions: {
            link: "/",
          },
        },
        android: {
          notification: {
            title,
            body,
            channelId: "team_pro4a_notifications",
            priority: "high",
          },
        },
      });
    } catch (error) {
      // If token is invalid or expired, remove it from Firestore
      if (
        error.code === "messaging/invalid-registration-token" ||
        error.code === "messaging/registration-token-not-registered"
      ) {
        await db.collection("users").doc(recipientUid).update({
          fcmToken: FieldValue.delete(),
        });
      }
    }
  }
);

// ─── 2. Daily cleanup — delete notifications older than 30 days ──────────────
//
// Runs every day at midnight Manila time (UTC+8)
// Deletes all notification docs where createdAt < 30 days ago

exports.cleanupOldNotifications = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "Asia/Manila",
  },
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - 30);

    const oldNotifications = await db
      .collection("notifications")
      .where("createdAt", "<", cutoff)
      .get();

    if (oldNotifications.empty) return;

    // Delete in batches of 500 (Firestore batch limit)
    const batchSize = 500;
    const docs = oldNotifications.docs;

    for (let i = 0; i < docs.length; i += batchSize) {
      const batch = db.batch();
      docs.slice(i, i + batchSize).forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }

    console.log(`Deleted ${docs.length} old notification(s).`);
  }
);