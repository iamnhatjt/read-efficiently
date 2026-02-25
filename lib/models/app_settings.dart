/// App settings model
class AppSettings {
  final int wpm;
  final int wordsAtATime;
  final double fontSize;
  final int themeIndex;
  final String fontFamily;
  final bool showContextLines;
  final bool autoPageTurn;
  final bool ttsEnabled;
  final double ttsSpeed;
  final String ttsVoice;
  final bool framelessWindow;
  final bool alwaysOnTop;
  final bool focusMode;

  const AppSettings({
    this.wpm = 300,
    this.wordsAtATime = 1,
    this.fontSize = 48.0,
    this.themeIndex = 0,
    this.fontFamily = 'Inter',
    this.showContextLines = true,
    this.autoPageTurn = true,
    this.ttsEnabled = false,
    this.ttsSpeed = 1.0,
    this.ttsVoice = '',
    this.framelessWindow = false,
    this.alwaysOnTop = false,
    this.focusMode = false,
  });

  AppSettings copyWith({
    int? wpm,
    int? wordsAtATime,
    double? fontSize,
    int? themeIndex,
    String? fontFamily,
    bool? showContextLines,
    bool? autoPageTurn,
    bool? ttsEnabled,
    double? ttsSpeed,
    String? ttsVoice,
    bool? framelessWindow,
    bool? alwaysOnTop,
    bool? focusMode,
  }) {
    return AppSettings(
      wpm: wpm ?? this.wpm,
      wordsAtATime: wordsAtATime ?? this.wordsAtATime,
      fontSize: fontSize ?? this.fontSize,
      themeIndex: themeIndex ?? this.themeIndex,
      fontFamily: fontFamily ?? this.fontFamily,
      showContextLines: showContextLines ?? this.showContextLines,
      autoPageTurn: autoPageTurn ?? this.autoPageTurn,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      ttsSpeed: ttsSpeed ?? this.ttsSpeed,
      ttsVoice: ttsVoice ?? this.ttsVoice,
      framelessWindow: framelessWindow ?? this.framelessWindow,
      alwaysOnTop: alwaysOnTop ?? this.alwaysOnTop,
      focusMode: focusMode ?? this.focusMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'wpm': wpm,
    'wordsAtATime': wordsAtATime,
    'fontSize': fontSize,
    'themeIndex': themeIndex,
    'fontFamily': fontFamily,
    'showContextLines': showContextLines,
    'autoPageTurn': autoPageTurn,
    'ttsEnabled': ttsEnabled,
    'ttsSpeed': ttsSpeed,
    'ttsVoice': ttsVoice,
    'framelessWindow': framelessWindow,
    'alwaysOnTop': alwaysOnTop,
    'focusMode': focusMode,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      wpm: json['wpm'] as int? ?? 300,
      wordsAtATime: json['wordsAtATime'] as int? ?? 1,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 48.0,
      themeIndex: json['themeIndex'] as int? ?? 0,
      fontFamily: json['fontFamily'] as String? ?? 'Inter',
      showContextLines: json['showContextLines'] as bool? ?? true,
      autoPageTurn: json['autoPageTurn'] as bool? ?? true,
      ttsEnabled: json['ttsEnabled'] as bool? ?? false,
      ttsSpeed: (json['ttsSpeed'] as num?)?.toDouble() ?? 1.0,
      ttsVoice: json['ttsVoice'] as String? ?? '',
      framelessWindow: json['framelessWindow'] as bool? ?? false,
      alwaysOnTop: json['alwaysOnTop'] as bool? ?? false,
      focusMode: json['focusMode'] as bool? ?? false,
    );
  }
}
