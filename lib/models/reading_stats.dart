/// Reading statistics model
class ReadingStats {
  final int totalWordsRead;
  final int totalSessionsCompleted;
  final int totalReadingTimeSeconds;
  final int currentStreak; // consecutive days
  final int longestStreak;
  final DateTime? lastSessionDate;
  final Map<String, int> weeklyWords; // 'Mon', 'Tue', etc.
  final List<int> dailyMinutes; // last 7 days

  ReadingStats({
    this.totalWordsRead = 0,
    this.totalSessionsCompleted = 0,
    this.totalReadingTimeSeconds = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
    Map<String, int>? weeklyWords,
    List<int>? dailyMinutes,
  })  : weeklyWords = weeklyWords ?? {},
        dailyMinutes = dailyMinutes ?? List.filled(7, 0);

  ReadingStats copyWith({
    int? totalWordsRead,
    int? totalSessionsCompleted,
    int? totalReadingTimeSeconds,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastSessionDate,
    Map<String, int>? weeklyWords,
    List<int>? dailyMinutes,
  }) {
    return ReadingStats(
      totalWordsRead: totalWordsRead ?? this.totalWordsRead,
      totalSessionsCompleted: totalSessionsCompleted ?? this.totalSessionsCompleted,
      totalReadingTimeSeconds: totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      weeklyWords: weeklyWords ?? Map.from(this.weeklyWords),
      dailyMinutes: dailyMinutes ?? List.from(this.dailyMinutes),
    );
  }

  Map<String, dynamic> toJson() => {
    'totalWordsRead': totalWordsRead,
    'totalSessionsCompleted': totalSessionsCompleted,
    'totalReadingTimeSeconds': totalReadingTimeSeconds,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastSessionDate': lastSessionDate?.toIso8601String(),
    'weeklyWords': weeklyWords,
    'dailyMinutes': dailyMinutes,
  };

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalWordsRead: json['totalWordsRead'] as int? ?? 0,
      totalSessionsCompleted: json['totalSessionsCompleted'] as int? ?? 0,
      totalReadingTimeSeconds: json['totalReadingTimeSeconds'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastSessionDate: json['lastSessionDate'] != null
          ? DateTime.parse(json['lastSessionDate'] as String)
          : null,
      weeklyWords: json['weeklyWords'] != null
          ? Map<String, int>.from(json['weeklyWords'] as Map)
          : null,
      dailyMinutes: json['dailyMinutes'] != null
          ? List<int>.from(json['dailyMinutes'] as List)
          : null,
    );
  }
}
