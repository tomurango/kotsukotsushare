// メモデータのモデル
class MemoData {
  final String cardId;
  final String id;
  final String content;
  final DateTime createdAt;
  //final bool isPublic;
  final String type;
  final String feeling;
  final String truth;
  final List<String> tags; // タグシステム（新機能）

  MemoData({
    required this.cardId,
    required this.id,
    required this.content,
    required this.createdAt,
    //required this.isPublic,
    required this.type,
    required this.feeling,
    required this.truth,
    this.tags = const [], // デフォルトは空リスト
  });

  // 空のデータを生成するファクトリメソッド
  factory MemoData.empty() {
    return MemoData(
    cardId: '',
    id: '',
    content: '',
    createdAt: DateTime.now(),
    //isPublic: true,
    type: '',
    feeling: '',
    truth: '',
    tags: [],
    );
  }

  // tagsを更新した新しいインスタンスを返す
  MemoData copyWith({
    String? cardId,
    String? id,
    String? content,
    DateTime? createdAt,
    String? type,
    String? feeling,
    String? truth,
    List<String>? tags,
  }) {
    return MemoData(
      cardId: cardId ?? this.cardId,
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      feeling: feeling ?? this.feeling,
      truth: truth ?? this.truth,
      tags: tags ?? this.tags,
    );
  }
}
