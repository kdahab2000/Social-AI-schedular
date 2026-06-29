class WorldCupMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime matchTime;
  final String status;
  final int? homeScore;
  final int? awayScore;
  final String stage;
  final String? group;

  WorldCupMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchTime,
    required this.status,
    this.homeScore,
    this.awayScore,
    required this.stage,
    this.group,
  });

  factory WorldCupMatch.fromJson(Map<String, dynamic> json) {
    final score = json['score'] as Map<String, dynamic>?;
    final fullTime = score?['fullTime'] as Map<String, dynamic>?;
    final homeScoreVal = fullTime?['home'] as int?;
    final awayScoreVal = fullTime?['away'] as int?;

    return WorldCupMatch(
      id: json['id'].toString(),
      homeTeam: (json['homeTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      awayTeam: (json['awayTeam'] as Map<String, dynamic>)['name'] as String? ?? 'TBD',
      matchTime: DateTime.parse(json['utcDate'] as String).toLocal(),
      status: json['status'] as String? ?? 'SCHEDULED',
      homeScore: homeScoreVal,
      awayScore: awayScoreVal,
      stage: json['stage'] as String? ?? '',
      group: json['group'] as String?,
    );
  }

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
  bool get isFinished => status == 'FINISHED';
  bool get isScheduled => status == 'SCHEDULED' || status == 'TIMED';

  String get scoreText {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  String get stageLabel {
    switch (stage) {
      case 'GROUP_STAGE': return group != null ? 'المجموعة $group' : 'دور المجموعات';
      case 'ROUND_OF_16': return 'دور الـ16';
      case 'QUARTER_FINALS': return 'ربع النهائي';
      case 'SEMI_FINALS': return 'نصف النهائي';
      case 'THIRD_PLACE': return 'المركز الثالث';
      case 'FINAL': return 'النهائي';
      default: return stage;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'IN_PLAY': return '🔴 مباشر';
      case 'PAUSED': return '⏸️ استراحة';
      case 'FINISHED': return '✅ انتهت';
      case 'SCHEDULED':
      case 'TIMED': return '🕐 قادمة';
      case 'POSTPONED': return '⏳ مؤجلة';
      case 'CANCELLED': return '❌ ملغية';
      default: return status;
    }
  }
}
