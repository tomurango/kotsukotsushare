// メモデータのモデル
class PublicMemoData {
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isPublic;
  final String type;
  final String feeling;
  final String truth;
  
  PublicMemoData({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isPublic,
    required this.type,
    required this.feeling,
    required this.truth,
  });
}
