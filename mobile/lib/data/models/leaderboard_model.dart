class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.score,
    required this.grade,
    required this.isCurrentUser,
  });

  final int rank;
  final String displayName;
  final int score;
  final String grade;
  final bool isCurrentUser;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] as int,
        displayName: json['displayName'] as String,
        score: json['score'] as int,
        grade: json['grade'] as String,
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
}
