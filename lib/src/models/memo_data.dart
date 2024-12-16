// メモデータのモデル
class MemoData {
  final String cardId;
  final String id;
  final String content;
  final DateTime createdAt;
  final bool isPublic;
  final String type;
  final String feeling;
  final String truth;
  
  MemoData({
    required this.cardId,
    required this.id,
    required this.content,
    required this.createdAt,
    required this.isPublic,
    required this.type,
    required this.feeling,
    required this.truth,
  });

  // 空のデータを生成するファクトリメソッド
  factory MemoData.empty() {
    return MemoData(
    cardId: '',
    id: '',
    content: '',
    createdAt: DateTime.now(),
    isPublic: true,
    type: '',
    feeling: '',
    truth: '',
    );
  }
}
