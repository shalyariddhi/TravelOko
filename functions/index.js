/* eslint-disable */
const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

// ═══════════════════════════════════════════════════════════════════════════════
// 🔧 HELPERS
// ═══════════════════════════════════════════════════════════════════════════════

// Split tokens into ≤500-token chunks (FCM multicast limit)
function chunkArray(arr, size) {
  const result = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🧠 SMART TIMING: Find the best hour to notify a user
// ═══════════════════════════════════════════════════════════════════════════════

function getBestHour(activeHours) {
  if (!activeHours || typeof activeHours !== "object") return 18; // Default: 6 PM
  let bestHour = 18;
  let max = 0;

  for (const hour in activeHours) {
    const count = activeHours[hour] || 0;
    if (count > max) {
      max = count;
      bestHour = parseInt(hour, 10);
    }
  }
  return bestHour;
}

// Compute the next occurrence of a given hour (UTC-adjusted if needed)
function getNextOccurrence(targetHour) {
  const now = new Date();
  const scheduled = new Date();
  scheduled.setHours(targetHour, 0, 0, 0);

  // If the target hour already passed today, schedule for tomorrow
  if (scheduled <= now) {
    scheduled.setDate(scheduled.getDate() + 1);
  }
  return scheduled;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🟣 TOPIC MATCHING: Check if a trip is relevant to a user's interests
// ═══════════════════════════════════════════════════════════════════════════════

function isRelevant(userTopics, tripTags) {
  // If user has no topic preferences, they get everything (opt-in later)
  if (!userTopics || userTopics.length === 0) return true;
  if (!tripTags || tripTags.length === 0) return true;

  return tripTags.some((tag) =>
    userTopics.some(
      (topic) => topic.toLowerCase() === tag.toLowerCase()
    )
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🔴 ENGAGEMENT FILTERING: Determine notification priority tier
// ═══════════════════════════════════════════════════════════════════════════════

// Returns: "high" | "medium" | "low" | "skip"
function getEngagementTier(engagementScore) {
  const score = engagementScore || 0;
  if (score >= 30) return "high";    // Immediate push
  if (score >= 10) return "medium";  // Queued push (batched)
  if (score >= 0) return "low";      // Digest only or skip
  return "skip";                     // Negative score = churned user
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🧱 INTELLIGENT COLLECTOR: Gather eligible tokens with full filtering
// ═══════════════════════════════════════════════════════════════════════════════

// Returns { immediateTokens: [...], queuedUsers: [{uid, tokens, bestHour}] }
async function collectSmartTokens(userIds, notificationKey, tripTags) {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  const immediateTokens = [];
  const queuedUsers = [];

  // Batch user-doc fetches
  const userSnaps = await Promise.all(
    userIds.map((uid) => admin.firestore().collection("users").doc(uid).get())
  );

  const eligible = [];
  for (const snap of userSnaps) {
    if (!snap.exists) continue;
    const data = snap.data();

    // 1. Respect per-user notification preferences
    if (data.notifications && data.notifications[notificationKey] === false) continue;

    // 2. Skip users inactive for >7 days
    if (data.lastActiveAt) {
      const lastActive = data.lastActiveAt.toDate();
      if (lastActive < sevenDaysAgo) continue;
    }

    // 3. Topic relevance filter
    if (!isRelevant(data.notificationTopics, tripTags)) continue;

    // 4. Engagement tier
    const tier = getEngagementTier(data.engagementScore);
    if (tier === "skip") continue;

    eligible.push({
      uid: snap.id,
      tier,
      activeHours: data.activity?.activeHours || {},
    });
  }

  // Fetch device tokens for all eligible users in parallel
  const tokenSnaps = await Promise.all(
    eligible.map((u) =>
      admin.firestore().collection("users").doc(u.uid).collection("tokens").get()
    )
  );

  for (let i = 0; i < eligible.length; i++) {
    const user = eligible[i];
    const tokens = [];
    tokenSnaps[i].forEach((t) => tokens.push(t.id));
    if (tokens.length === 0) continue;

    if (user.tier === "high") {
      // High engagement → immediate push
      immediateTokens.push(...tokens);
    } else if (user.tier === "medium") {
      // Medium → queue for best send time
      const bestHour = getBestHour(user.activeHours);
      queuedUsers.push({ uid: user.uid, tokens, bestHour });
    }
    // Low tier: skip (or you could batch into a daily digest)
  }

  return { immediateTokens, queuedUsers };
}

// ═══════════════════════════════════════════════════════════════════════════════
// ⚡ SEND: Immediate batched delivery
// ═══════════════════════════════════════════════════════════════════════════════

async function sendBatched(tokens, notification, data) {
  if (!tokens || tokens.length === 0) return;
  const chunks = chunkArray(tokens, 500);
  return Promise.all(
    chunks.map((chunk) =>
      admin.messaging().sendEachForMulticast({ tokens: chunk, notification, data })
    )
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// 📬 QUEUE: Schedule notification for optimal delivery time
// ═══════════════════════════════════════════════════════════════════════════════

async function queueNotifications(users, notification, data) {
  if (!users || users.length === 0) return;

  const batch = admin.firestore().batch();
  for (const user of users) {
    const scheduledAt = getNextOccurrence(user.bestHour);
    const ref = admin.firestore().collection("notification_queue").doc();
    batch.set(ref, {
      targetUserId: user.uid,
      tokens: user.tokens,
      notification,
      data,
      scheduledAt: admin.firestore.Timestamp.fromDate(scheduledAt),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sent: false,
    });
  }
  return batch.commit();
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 TRIGGER: New Trip Created → Smart Notification Pipeline
// ═══════════════════════════════════════════════════════════════════════════════

exports.onNewTrip = onDocumentCreated("trips/{tripId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const trip = snap.data();
  const organizerId = trip.organizerId;
  if (!organizerId) return;

  // Fetch followers of the trip organizer
  const followersSnap = await admin
    .firestore()
    .collection("users")
    .doc(organizerId)
    .collection("followers")
    .get();

  const followerIds = followersSnap.docs.map((d) => d.id);
  if (followerIds.length === 0) return null;

  const tripTags = trip.tags || [];

  // Smart collection: filters by preference, engagement, relevance
  const { immediateTokens, queuedUsers } = await collectSmartTokens(
    followerIds,
    "newTrips",
    tripTags
  );

  const notification = {
    title: "New Trip 🚀",
    body: trip.title ? `${trip.title}` : "A new trip was posted!",
  };
  const data = { type: "new_trip", tripId: event.params.tripId };

  // Send immediately to high-engagement users
  await sendBatched(immediateTokens, notification, data);

  // Queue for medium-engagement users at their best hour
  await queueNotifications(queuedUsers, notification, data);
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 TRIGGER: New Post Created → Smart Notification Pipeline
// ═══════════════════════════════════════════════════════════════════════════════

exports.onNewPost = onDocumentCreated("posts/{postId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const post = snap.data();
  const authorId = post.userId || post.authorId;
  if (!authorId) return;

  const followersSnap = await admin
    .firestore()
    .collection("users")
    .doc(authorId)
    .collection("followers")
    .get();

  const followerIds = followersSnap.docs.map((d) => d.id);
  if (followerIds.length === 0) return null;

  const postTags = post.tags || [];

  const { immediateTokens, queuedUsers } = await collectSmartTokens(
    followerIds,
    "newTrips",
    postTags
  );

  const authorName = post.userName || post.authorName || "Someone";
  const notification = {
    title: "New Post 📸",
    body: `${authorName} shared a new travel story!`,
  };
  const data = { type: "new_post", postId: event.params.postId };

  await sendBatched(immediateTokens, notification, data);
  await queueNotifications(queuedUsers, notification, data);
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 TRIGGER: New Follower → Immediate (always relevant)
// ═══════════════════════════════════════════════════════════════════════════════

exports.onNewFollower = onDocumentCreated(
  "users/{userId}/followers/{followerId}",
  async (event) => {
    const userId = event.params.userId;
    const followerId = event.params.followerId;

    const followerSnap = await admin
      .firestore()
      .collection("users")
      .doc(followerId)
      .get();
    const followerName = followerSnap.exists
      ? followerSnap.data().displayName || "Someone"
      : "Someone";

    // Follower notifications are always immediate (high-signal event)
    const tokensSnap = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("tokens")
      .get();

    const tokens = tokensSnap.docs.map((t) => t.id);
    if (tokens.length === 0) return null;

    return sendBatched(
      tokens,
      {
        title: "New Follower 🎉",
        body: `${followerName} started following you!`,
      },
      { type: "new_follower", followerId }
    );
  }
);

// ═══════════════════════════════════════════════════════════════════════════════
// ⏰ CRON: Process notification queue every 15 minutes
// ═══════════════════════════════════════════════════════════════════════════════

exports.processNotificationQueue = onSchedule("every 15 minutes", async () => {
  const now = admin.firestore.Timestamp.now();

  const pendingSnap = await admin
    .firestore()
    .collection("notification_queue")
    .where("sent", "==", false)
    .where("scheduledAt", "<=", now)
    .limit(200)
    .get();

  if (pendingSnap.empty) return;

  const batch = admin.firestore().batch();

  for (const doc of pendingSnap.docs) {
    const job = doc.data();
    try {
      await sendBatched(job.tokens, job.notification, job.data);
      batch.update(doc.ref, { sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
    } catch (e) {
      console.error(`Failed to send queued notification ${doc.id}:`, e);
      batch.update(doc.ref, { error: e.message });
    }
  }

  return batch.commit();
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🔄 CRON: Decay engagement scores (run daily) — prevents score inflation
// ═══════════════════════════════════════════════════════════════════════════════

exports.decayEngagementScores = onSchedule("every 24 hours", async () => {
  const usersSnap = await admin
    .firestore()
    .collection("users")
    .where("engagementScore", ">", 0)
    .limit(500)
    .get();

  if (usersSnap.empty) return;

  const batch = admin.firestore().batch();
  for (const doc of usersSnap.docs) {
    const currentScore = doc.data().engagementScore || 0;
    const decayed = Math.floor(currentScore * 0.95);
    batch.update(doc.ref, { engagementScore: decayed });
  }

  return batch.commit();
});

// ═══════════════════════════════════════════════════════════════════════════════
// 📊 ANALYTICS: Increment Unique View
// ═══════════════════════════════════════════════════════════════════════════════

exports.incrementUniqueView = onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const postId = data.postId;
  const userId = data.userId || auth.uid;

  if (!postId || !userId) {
    throw new HttpsError("invalid-argument", "Missing postId or userId.");
  }

  const db = admin.firestore();
  const viewRef = db.collection("posts").doc(postId).collection("views").doc(userId);
  const postRef = db.collection("posts").doc(postId);

  return db.runTransaction(async (transaction) => {
    const viewDoc = await transaction.get(viewRef);
    if (!viewDoc.exists) {
      transaction.set(viewRef, { viewedAt: admin.firestore.FieldValue.serverTimestamp() });
      transaction.update(postRef, { viewsCount: admin.firestore.FieldValue.increment(1) });
      return { success: true, newView: true };
    }
    return { success: true, newView: false };
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🚀 BOOST SYSTEM: Boost Post
// ═══════════════════════════════════════════════════════════════════════════════

exports.boostPost = onCall(async (request) => {
  const data = request.data;
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be logged in.");
  }

  const postId = data.postId;
  const score = data.score || 10;
  const durationDays = data.durationDays || 3;

  if (!postId) {
    throw new HttpsError("invalid-argument", "Missing postId.");
  }

  const db = admin.firestore();
  const postRef = db.collection("posts").doc(postId);

  const postDoc = await postRef.get();
  if (!postDoc.exists) {
    throw new HttpsError("not-found", "Post not found.");
  }

  const post = postDoc.data();
  if (post.authorId !== auth.uid && post.userId !== auth.uid) {
    throw new HttpsError("permission-denied", "Only the author can boost this post.");
  }

  const views = post.viewsCount || 1;
  const likes = post.likesCount || 0;
  const comments = post.commentsCount || 0;
  const saves = post.savesCount || 0;
  const shares = post.sharesCount || 0;

  const totalEngagement = likes + comments + saves + shares;
  const engagementRate = totalEngagement / views;

  if (engagementRate < 0.05 && views > 10) {
    throw new HttpsError("failed-precondition", "Post engagement is too low to be boosted.");
  }

  const expiry = new Date();
  expiry.setDate(expiry.getDate() + durationDays);

  await postRef.update({
    isBoosted: true,
    boostScore: score,
    boostExpiry: admin.firestore.Timestamp.fromDate(expiry),
  });

  return { success: true, expiry: expiry.toISOString() };
});

// ═══════════════════════════════════════════════════════════════════════════════
// 🌟 RANKING & TRUST ENGINES (Offloaded from Client)
// ═══════════════════════════════════════════════════════════════════════════════

exports.onReviewCreated = onDocumentCreated("places/{placeId}/reviews/{reviewId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const review = snap.data();
  const placeId = event.params.placeId;
  const reviewerId = review.userId;

  const db = admin.firestore();

  // 1. Recalculate Popularity Score for the Place
  const placeRef = db.collection("places").doc(placeId);
  const placeDoc = await placeRef.get();
  
  if (placeDoc.exists) {
    const placeData = placeDoc.data();
    const rating = placeData.avgRating || 0;
    const reviewsCount = placeData.reviewsCount || 0;
    
    let createdAtMs = Date.now();
    if (placeData.createdAt && placeData.createdAt.toDate) {
      createdAtMs = placeData.createdAt.toDate().getTime();
    }

    const ageDays = (Date.now() - createdAtMs) / (1000 * 60 * 60 * 24);
    const recencyBoost = 1 / (1 + ageDays);
    const popularityScore = (rating * 0.5) + (Math.log10(reviewsCount + 1) * 0.3) + (recencyBoost * 0.2);

    await placeRef.update({ popularityScore });
  }

  // 2. Update Trust Score for the Reviewer
  if (reviewerId) {
    const userRef = db.collection("users").doc(reviewerId);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      let trustScore = 0;

      // Basic trust rules
      if (userData.email) trustScore += 20;
      if (userData.photoUrl && userData.photoUrl.length > 0) trustScore += 10;
      
      const reviewsCount = (userData.reviewsCount || 0) + 1; // including this new review
      if (reviewsCount > 5) trustScore += 40;

      // Gamification Badges
      let badges = userData.badges || [];
      if (reviewsCount >= 10 && !badges.includes('Local Expert 🏅')) badges.push('Local Expert 🏅');
      else if (reviewsCount >= 5 && !badges.includes('Active Reviewer ✍️')) badges.push('Active Reviewer ✍️');

      await userRef.update({
        verifiedScore: trustScore,
        reviewsCount: admin.firestore.FieldValue.increment(1),
        badges: badges
      });
    }
  }
});
