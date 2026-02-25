/// Model for persisted reading progress (stored in Hive)
/// Keyed by document hash (SHA-256 for PDFs, content hash for text)
class ReadingProgress {
  final String documentHash;
  final String documentTitle;
  final String? filePath;
  final int currentPage;       // for PDFs
  final int totalPages;        // for PDFs
  final int wordIndex;         // current word position in the document
  final int totalWords;
  final int lastWpm;
  final int lastWordsAtATime;
  final int lastThemeIndex;
  final String lastFont;
  final double lastFontSize;
  final DateTime lastAccessed;
  final String documentType;   // 'pdf', 'text', 'url'
  final String? sourceUrl;     // for web articles
  final int totalReadingTimeSeconds; // cumulative reading time

  ReadingProgress({
    required this.documentHash,
    required this.documentTitle,
    this.filePath,
    this.currentPage = 0,
    this.totalPages = 0,
    this.wordIndex = 0,
    this.totalWords = 0,
    this.lastWpm = 300,
    this.lastWordsAtATime = 1,
    this.lastThemeIndex = 0,
    this.lastFont = 'Inter',
    this.lastFontSize = 48.0,
    required this.lastAccessed,
    this.documentType = 'text',
    this.sourceUrl,
    this.totalReadingTimeSeconds = 0,
  });

  double get progressPercent =>
      totalWords > 0 ? (wordIndex / totalWords).clamp(0.0, 1.0) : 0.0;

  ReadingProgress copyWith({
    String? documentHash,
    String? documentTitle,
    String? filePath,
    int? currentPage,
    int? totalPages,
    int? wordIndex,
    int? totalWords,
    int? lastWpm,
    int? lastWordsAtATime,
    int? lastThemeIndex,
    String? lastFont,
    double? lastFontSize,
    DateTime? lastAccessed,
    String? documentType,
    String? sourceUrl,
    int? totalReadingTimeSeconds,
  }) {
    return ReadingProgress(
      documentHash: documentHash ?? this.documentHash,
      documentTitle: documentTitle ?? this.documentTitle,
      filePath: filePath ?? this.filePath,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      wordIndex: wordIndex ?? this.wordIndex,
      totalWords: totalWords ?? this.totalWords,
      lastWpm: lastWpm ?? this.lastWpm,
      lastWordsAtATime: lastWordsAtATime ?? this.lastWordsAtATime,
      lastThemeIndex: lastThemeIndex ?? this.lastThemeIndex,
      lastFont: lastFont ?? this.lastFont,
      lastFontSize: lastFontSize ?? this.lastFontSize,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      documentType: documentType ?? this.documentType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      totalReadingTimeSeconds: totalReadingTimeSeconds ?? this.totalReadingTimeSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'documentHash': documentHash,
    'documentTitle': documentTitle,
    'filePath': filePath,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'wordIndex': wordIndex,
    'totalWords': totalWords,
    'lastWpm': lastWpm,
    'lastWordsAtATime': lastWordsAtATime,
    'lastThemeIndex': lastThemeIndex,
    'lastFont': lastFont,
    'lastFontSize': lastFontSize,
    'lastAccessed': lastAccessed.toIso8601String(),
    'documentType': documentType,
    'sourceUrl': sourceUrl,
    'totalReadingTimeSeconds': totalReadingTimeSeconds,
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      documentHash: json['documentHash'] as String,
      documentTitle: json['documentTitle'] as String,
      filePath: json['filePath'] as String?,
      currentPage: json['currentPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      wordIndex: json['wordIndex'] as int? ?? 0,
      totalWords: json['totalWords'] as int? ?? 0,
      lastWpm: json['lastWpm'] as int? ?? 300,
      lastWordsAtATime: json['lastWordsAtATime'] as int? ?? 1,
      lastThemeIndex: json['lastThemeIndex'] as int? ?? 0,
      lastFont: json['lastFont'] as String? ?? 'Inter',
      lastFontSize: (json['lastFontSize'] as num?)?.toDouble() ?? 48.0,
      lastAccessed: DateTime.parse(json['lastAccessed'] as String),
      documentType: json['documentType'] as String? ?? 'text',
      sourceUrl: json['sourceUrl'] as String?,
      totalReadingTimeSeconds: json['totalReadingTimeSeconds'] as int? ?? 0,
    );
  }
}
