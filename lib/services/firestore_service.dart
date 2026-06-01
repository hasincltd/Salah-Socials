import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Firestore collection paths ────────────────────────────────────────────
//
//  users/{userId}
//  prayerLogs/{userId}/logs/{date}   (date = YYYY-MM-DD)
//  streaks/{userId}
//  friends/{userId}/friendList/{friendId}

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // ── SharedPreferences key constants ──────────────────────────────────────

  static const _kDisplayName = 'settings_display_name';
  static const _kUsername    = 'settings_username';
  static const _kSsCoins     = 'ss_coin_balance';
  static const _kTotalScore  = 'total_streak_score';
  static const _kFriendCount = 'friend_count';

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Creates or merges a user document and caches name fields locally.
  Future<void> createUserProfile(
    String userId, {
    required String username,
    required String displayName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, displayName);
    await prefs.setString(_kUsername, username);

    try {
      await _db.collection('users').doc(userId).set({
        'username': username,
        'displayName': displayName,
        'email': email,
        'homeLocation': null,
        'homeMosqueId': null,
        'country': 'GB',
        'isPremium': false,
        'premiumExpiryDate': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns cached profile data, falling back to Firestore when missing.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedName     = prefs.getString(_kDisplayName);
    final cachedUsername = prefs.getString(_kUsername);

    if (cachedName != null && cachedUsername != null) {
      return {'displayName': cachedName, 'username': cachedUsername};
    }

    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      await prefs.setString(_kDisplayName, data['displayName'] as String? ?? '');
      await prefs.setString(_kUsername, data['username'] as String? ?? '');
      return data;
    } catch (_) {
      return null;
    }
  }

  // ── Prayer logs ───────────────────────────────────────────────────────────

  /// Writes a single prayer toggle to SharedPreferences and Firestore.
  Future<void> savePrayerLog(
    String userId,
    String date,
    String prayerName,
    bool isLogged,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prayer_log_${date}_$prayerName', isLogged);

    try {
      await _db
          .collection('prayerLogs')
          .doc(userId)
          .collection('logs')
          .doc(date)
          .set({
        prayerName.toLowerCase(): isLogged,
        'loggedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns prayer log booleans for a given date (YYYY-MM-DD).
  /// Reads from SharedPreferences first; syncs from Firestore if all false.
  Future<Map<String, bool>> getPrayerLogsForDate(
    String userId,
    String date,
  ) async {
    const names = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prefs = await SharedPreferences.getInstance();
    final cached = {
      for (final n in names)
        n: prefs.getBool('prayer_log_${date}_$n') ?? false,
    };

    if (cached.values.any((v) => v)) return cached;

    try {
      final doc = await _db
          .collection('prayerLogs')
          .doc(userId)
          .collection('logs')
          .doc(date)
          .get();
      if (!doc.exists) return cached;
      final data = doc.data()!;
      final result = <String, bool>{};
      for (final n in names) {
        final val = data[n.toLowerCase()] as bool? ?? false;
        result[n] = val;
        await prefs.setBool('prayer_log_${date}_$n', val);
      }
      return result;
    } catch (_) {
      return cached;
    }
  }

  // ── Streaks ───────────────────────────────────────────────────────────────

  /// Writes streak + coin data to both SharedPreferences and Firestore.
  Future<void> updateStreak(
    String userId, {
    required int activeCount,
    required int totalScore,
    required int ssCoins,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSsCoins, ssCoins);
    await prefs.setInt(_kTotalScore, totalScore);

    try {
      await _db.collection('streaks').doc(userId).set({
        'activeStreakCount': activeCount,
        'totalStreakScore': totalScore,
        'ssCoinsBalance': ssCoins,
        'lastUpdated': FieldValue.serverTimestamp(),
        'revivesUsedThisMonth': 0,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Returns streak data, reading SharedPreferences first.
  Future<Map<String, int>> getStreak(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedCoins = prefs.getInt(_kSsCoins);
    final cachedTotal = prefs.getInt(_kTotalScore);

    if (cachedCoins != null && cachedTotal != null) {
      return {'ssCoinsBalance': cachedCoins, 'totalStreakScore': cachedTotal};
    }

    try {
      final doc = await _db.collection('streaks').doc(userId).get();
      if (!doc.exists) return {'ssCoinsBalance': 0, 'totalStreakScore': 0};
      final data = doc.data()!;
      final coins = data['ssCoinsBalance'] as int? ?? 0;
      final total = data['totalStreakScore'] as int? ?? 0;
      await prefs.setInt(_kSsCoins, coins);
      await prefs.setInt(_kTotalScore, total);
      return {'ssCoinsBalance': coins, 'totalStreakScore': total};
    } catch (_) {
      return {'ssCoinsBalance': 0, 'totalStreakScore': 0};
    }
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  /// Creates a friend request: sender gets "pending", receiver gets "incoming".
  Future<void> sendFriendRequest(String userId, String targetUserId) async {
    final now = FieldValue.serverTimestamp();
    try {
      final batch = _db.batch();
      batch.set(
        _db
            .collection('friends')
            .doc(userId)
            .collection('friendList')
            .doc(targetUserId),
        {'status': 'pending', 'requestedAt': now, 'acceptedAt': null},
      );
      batch.set(
        _db
            .collection('friends')
            .doc(targetUserId)
            .collection('friendList')
            .doc(userId),
        {'status': 'incoming', 'requestedAt': now, 'acceptedAt': null},
      );
      await batch.commit();
    } catch (_) {}
  }

  /// Deletes both sides of a declined or cancelled friend request.
  Future<void> declineFriendRequest(String userId, String requesterId) async {
    try {
      final batch = _db.batch();
      batch.delete(_db
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .doc(requesterId));
      batch.delete(_db
          .collection('friends')
          .doc(requesterId)
          .collection('friendList')
          .doc(userId));
      await batch.commit();
    } catch (_) {}
  }

  /// Returns all incoming (unactioned) friend requests with the sender's displayName.
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests(
      String userId) async {
    try {
      final snap = await _db
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .where('status', isEqualTo: 'incoming')
          .get();
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final requesterId = doc.id;
        String displayName = requesterId;
        try {
          final userDoc =
              await _db.collection('users').doc(requesterId).get();
          if (userDoc.exists) {
            displayName =
                userDoc.data()?['displayName'] as String? ?? requesterId;
          }
        } catch (_) {}
        results.add({'requesterId': requesterId, 'displayName': displayName});
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Loads accepted friends with their profile (displayName) and streak data.
  Future<List<Map<String, dynamic>>> loadFriendsWithProfiles(
      String userId) async {
    try {
      final snap = await _db
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .where('status', isEqualTo: 'accepted')
          .get();
      final results = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final friendId = doc.id;
        String displayName = friendId;
        int activeStreak = 0;
        int totalScore = 0;
        try {
          final userDoc =
              await _db.collection('users').doc(friendId).get();
          if (userDoc.exists) {
            displayName =
                userDoc.data()?['displayName'] as String? ?? friendId;
          }
        } catch (_) {}
        try {
          final streakDoc =
              await _db.collection('streaks').doc(friendId).get();
          if (streakDoc.exists) {
            activeStreak =
                streakDoc.data()?['activeStreakCount'] as int? ?? 0;
            totalScore =
                streakDoc.data()?['totalStreakScore'] as int? ?? 0;
          }
        } catch (_) {}
        results.add({
          'friendId': friendId,
          'displayName': displayName,
          'activeStreak': activeStreak,
          'totalScore': totalScore,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kFriendCount, results.length);
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Stream of accepted friend count for real-time header chip updates.
  Stream<int> streamFriendCount(String userId) {
    return _db
        .collection('friends')
        .doc(userId)
        .collection('friendList')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Marks both sides of a friend relationship as accepted.
  Future<void> acceptFriendRequest(
      String userId, String requesterId) async {
    final now = FieldValue.serverTimestamp();
    try {
      final batch = _db.batch();
      batch.update(
        _db
            .collection('friends')
            .doc(userId)
            .collection('friendList')
            .doc(requesterId),
        {'status': 'accepted', 'acceptedAt': now},
      );
      batch.update(
        _db
            .collection('friends')
            .doc(requesterId)
            .collection('friendList')
            .doc(userId),
        {'status': 'accepted', 'acceptedAt': now},
      );
      await batch.commit();

      final friends = await getFriends(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kFriendCount, friends.length);
    } catch (_) {}
  }

  /// Returns all accepted friends, updating the local friend_count cache.
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      final snap = await _db
          .collection('friends')
          .doc(userId)
          .collection('friendList')
          .where('status', isEqualTo: 'accepted')
          .get();
      final friends = snap.docs
          .map((d) => <String, dynamic>{'friendId': d.id, ...d.data()})
          .toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kFriendCount, friends.length);
      return friends;
    } catch (_) {
      return [];
    }
  }

  // ── User profile updates ─────────────────────────────────────────────────

  /// Saves homeLocation (postcode) to SharedPreferences and Firestore.
  Future<void> updateUserLocation(String userId, {String? postcode}) async {
    if (postcode == null || postcode.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_postcode', postcode);
    try {
      await _db.collection('users').doc(userId).update({
        'homeLocation': postcode,
      });
    } catch (_) {}
  }

  /// Saves homeMosqueId to SharedPreferences and Firestore.
  Future<void> updateUserMosque(String userId, String mosqueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_mosque_id', mosqueId);
    try {
      await _db.collection('users').doc(userId).update({
        'homeMosqueId': mosqueId,
      });
    } catch (_) {}
  }

  // ── Sync on login ─────────────────────────────────────────────────────────

  /// Called once per login session to pull remote data into SharedPreferences.
  Future<void> syncOnLogin(String userId) async {
    await getUserProfile(userId);
    await getStreak(userId);
    await getFriends(userId);
  }
}
