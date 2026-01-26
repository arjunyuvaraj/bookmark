import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class UserStats {
  final int currentStreak;
  final int longestStreak;
  final int totalCardsStudied;
  final int totalSessions;
  final int correctAnswers;
  final int totalAnswers;
  final DateTime? lastStudyDate;
  final int dailyGoalCards;
  final int weeklyGoalSessions;
  final int monthlyGoalQuizzes;
  final int cardsStudiedToday;
  final int sessionsThisWeek;
  final int quizzesThisMonth;

  UserStats({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalCardsStudied = 0,
    this.totalSessions = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.lastStudyDate,
    this.dailyGoalCards = 30,
    this.weeklyGoalSessions = 7,
    this.monthlyGoalQuizzes = 4,
    this.cardsStudiedToday = 0,
    this.sessionsThisWeek = 0,
    this.quizzesThisMonth = 0,
  });

  double get accuracy {
    if (totalAnswers == 0) return 0;
    return (correctAnswers / totalAnswers) * 100;
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      totalCardsStudied: json['totalCardsStudied'] ?? 0,
      totalSessions: json['totalSessions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      totalAnswers: json['totalAnswers'] ?? 0,
      lastStudyDate: (json['lastStudyDate'] as Timestamp?)?.toDate(),
      dailyGoalCards: json['dailyGoalCards'] ?? 30,
      weeklyGoalSessions: json['weeklyGoalSessions'] ?? 7,
      monthlyGoalQuizzes: json['monthlyGoalQuizzes'] ?? 4,
      cardsStudiedToday: json['cardsStudiedToday'] ?? 0,
      sessionsThisWeek: json['sessionsThisWeek'] ?? 0,
      quizzesThisMonth: json['quizzesThisMonth'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'totalCardsStudied': totalCardsStudied,
    'totalSessions': totalSessions,
    'correctAnswers': correctAnswers,
    'totalAnswers': totalAnswers,
    'lastStudyDate': lastStudyDate != null ? Timestamp.fromDate(lastStudyDate!) : null,
    'dailyGoalCards': dailyGoalCards,
    'weeklyGoalSessions': weeklyGoalSessions,
    'monthlyGoalQuizzes': monthlyGoalQuizzes,
    'cardsStudiedToday': cardsStudiedToday,
    'sessionsThisWeek': sessionsThisWeek,
    'quizzesThisMonth': quizzesThisMonth,
  };
}

class ActivityItem {
  final String id;
  final String type;
  final String title;
  final String? setId;
  final String? setTitle;
  final int? score;
  final DateTime timestamp;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.setId,
    this.setTitle,
    this.score,
    required this.timestamp,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json, String id) {
    return ActivityItem(
      id: id,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      setId: json['setId'],
      setTitle: json['setTitle'],
      score: json['score'],
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'setId': setId,
    'setTitle': setTitle,
    'score': score,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference _statsDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('data').doc('stats');
  }

  CollectionReference _activityCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('activity');
  }

  Future<UserStats> getUserStats(String userId) async {
    try {
      final doc = await _statsDoc(userId).get();
      if (!doc.exists) {
        await _initializeStats(userId);
        return UserStats();
      }
      return UserStats.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) print('Error getting user stats: $e');
      return UserStats();
    }
  }

  Stream<UserStats> streamUserStats(String userId) {
    return _statsDoc(userId).snapshots().map((doc) {
      if (!doc.exists) return UserStats();
      return UserStats.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  Future<void> _initializeStats(String userId) async {
    try {
      await _statsDoc(userId).set(UserStats().toJson());
    } catch (e) {
      if (kDebugMode) print('Error initializing stats: $e');
    }
  }

  Future<void> recordStudySession({
    required String userId,
    required String setId,
    required String setTitle,
    required int cardsStudied,
    int correctAnswers = 0,
    int totalAnswers = 0,
  }) async {
    try {
      final now = DateTime.now();
      final stats = await getUserStats(userId);

      // Calculate streak
      int newStreak = stats.currentStreak;
      final lastDate = stats.lastStudyDate;

      if (lastDate != null) {
        final daysDiff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;

        if (daysDiff == 1) {
          newStreak = stats.currentStreak + 1;
        } else if (daysDiff > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      // Check if this is the same day
      final isSameDay = lastDate != null &&
          lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day;

      // Reset daily/weekly/monthly counters if needed
      int cardsToday = isSameDay ? stats.cardsStudiedToday + cardsStudied : cardsStudied;

      // Check week reset
      int sessionsWeek = stats.sessionsThisWeek;
      if (lastDate != null) {
        final lastWeek = _getWeekNumber(lastDate);
        final currentWeek = _getWeekNumber(now);
        if (lastWeek != currentWeek) sessionsWeek = 0;
      }
      sessionsWeek += 1;

      // Check month reset
      int quizzesMonth = stats.quizzesThisMonth;
      if (lastDate != null && lastDate.month != now.month) {
        quizzesMonth = 0;
      }

      await _statsDoc(userId).set({
        'currentStreak': newStreak,
        'longestStreak': newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
        'totalCardsStudied': stats.totalCardsStudied + cardsStudied,
        'totalSessions': stats.totalSessions + 1,
        'correctAnswers': stats.correctAnswers + correctAnswers,
        'totalAnswers': stats.totalAnswers + totalAnswers,
        'lastStudyDate': Timestamp.fromDate(now),
        'dailyGoalCards': stats.dailyGoalCards,
        'weeklyGoalSessions': stats.weeklyGoalSessions,
        'monthlyGoalQuizzes': stats.monthlyGoalQuizzes,
        'cardsStudiedToday': cardsToday,
        'sessionsThisWeek': sessionsWeek,
        'quizzesThisMonth': quizzesMonth,
      }, SetOptions(merge: true));

      // Log activity
      await logActivity(
        userId: userId,
        type: 'study',
        title: 'Studied $setTitle',
        setId: setId,
        setTitle: setTitle,
      );
    } catch (e) {
      if (kDebugMode) print('Error recording study session: $e');
    }
  }

  Future<void> recordQuizCompleted({
    required String userId,
    required String setId,
    required String setTitle,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final stats = await getUserStats(userId);
      final now = DateTime.now();

      // Check month reset
      int quizzesMonth = stats.quizzesThisMonth;
      final lastDate = stats.lastStudyDate;
      if (lastDate != null && lastDate.month != now.month) {
        quizzesMonth = 0;
      }
      quizzesMonth += 1;

      await _statsDoc(userId).update({
        'correctAnswers': FieldValue.increment(score),
        'totalAnswers': FieldValue.increment(totalQuestions),
        'quizzesThisMonth': quizzesMonth,
      });

      // Log activity
      final percentage = totalQuestions > 0 ? ((score / totalQuestions) * 100).round() : 0;
      await logActivity(
        userId: userId,
        type: 'quiz',
        title: 'Completed Quiz - $percentage%',
        setId: setId,
        setTitle: setTitle,
        score: percentage,
      );
    } catch (e) {
      if (kDebugMode) print('Error recording quiz: $e');
    }
  }

  Future<void> recordSetCreated({
    required String userId,
    required String setId,
    required String setTitle,
  }) async {
    try {
      await logActivity(
        userId: userId,
        type: 'created',
        title: 'Created "$setTitle"',
        setId: setId,
        setTitle: setTitle,
      );
    } catch (e) {
      if (kDebugMode) print('Error recording set created: $e');
    }
  }

  Future<void> logActivity({
    required String userId,
    required String type,
    required String title,
    String? setId,
    String? setTitle,
    int? score,
  }) async {
    try {
      await _activityCollection(userId).add(ActivityItem(
        id: '',
        type: type,
        title: title,
        setId: setId,
        setTitle: setTitle,
        score: score,
        timestamp: DateTime.now(),
      ).toJson());
    } catch (e) {
      if (kDebugMode) print('Error logging activity: $e');
    }
  }

  Future<List<ActivityItem>> getRecentActivity(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _activityCollection(userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error getting activity: $e');
      return [];
    }
  }

  Stream<List<ActivityItem>> streamRecentActivity(String userId, {int limit = 10}) {
    return _activityCollection(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityItem.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> updateGoals({
    required String userId,
    int? dailyCards,
    int? weeklySessions,
    int? monthlyQuizzes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (dailyCards != null) updates['dailyGoalCards'] = dailyCards;
      if (weeklySessions != null) updates['weeklyGoalSessions'] = weeklySessions;
      if (monthlyQuizzes != null) updates['monthlyGoalQuizzes'] = monthlyQuizzes;

      if (updates.isNotEmpty) {
        await _statsDoc(userId).update(updates);
      }
    } catch (e) {
      if (kDebugMode) print('Error updating goals: $e');
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }
}
