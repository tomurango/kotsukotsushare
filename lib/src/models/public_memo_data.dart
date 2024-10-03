class PublicMemoData {
  final String id;
  final String content;
  final bool isPublic;
  final DateTime createdAt;
  final String type;
  final String feeling;
  final String truth;
  final String userId; // 投稿者のUIDを追加

  PublicMemoData({
    required this.id,
    required this.content,
    required this.isPublic,
    required this.createdAt,
    required this.type,
    required this.feeling,
    required this.truth,
    required this.userId,
  });
}
