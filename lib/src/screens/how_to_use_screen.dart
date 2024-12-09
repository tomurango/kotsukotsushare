import 'package:flutter/material.dart';

class HowToUseScreen extends StatefulWidget {
  const HowToUseScreen({Key? key}) : super(key: key);

  @override
  State<HowToUseScreen> createState() => _HowToUseScreenState();
}

class _HowToUseScreenState extends State<HowToUseScreen> {
  final PageController _pageController = PageController();
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    _currentPageNotifier = ValueNotifier<int>(0);

    // PageController を監視し、ページ番号を更新
    _pageController.addListener(() {
      final currentPage = (_pageController.page ?? 0).round();
      if (_currentPageNotifier.value != currentPage) {
        _currentPageNotifier.value = currentPage;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tutorialPages = [
      _HowToUsePage(
        imagePath: 'assets/images/how_to_use/create_cards_after.png',
        title: 'カードを作ろう',
        description: '大切なことをカードに書き留めましょう。\n\nカードの情報は自分だけのもので、他の人に共有されることはありません。',
        index: 0,
      ),
      _HowToUsePage(
        imagePath: 'assets/images/how_to_use/write_memos_after.png',
        title: 'メモを残そう',
        description: '調べたことや気づいたことをメモに残しましょう。\n\nメモは、公開するか非公開にするか選択できます。',
        index: 1,
      ),
      _HowToUsePage(
        imagePath: 'assets/images/how_to_use/others_log.png',
        title: 'みんなの記録を見よう',
        description: '他の人が公開設定にしているメモを見ることができます。\n\nメモを保存やコメント機能などを開発予定です。',
        index: 2,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: tutorialPages.length,
            itemBuilder: (context, index) {
              return tutorialPages[index];
            },
          ),
          // ページインジケータ
          Positioned(
            bottom: 50,
            left: 25,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    tutorialPages.length,
                    (index) => _buildPageIndicator(index, currentPage),
                  ),
                );
              },
            ),
          ),
          // ボタン (次へ or 終了)
          Positioned(
            bottom: 30,
            right: 20,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, child) {
                final isLastPage = currentPage == tutorialPages.length - 1;
                return isLastPage
                    ? TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // スクリーンを閉じる
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 子ウィジェットの幅に合わせる
                          children: [
                            Icon(
                              Icons.play_arrow, // アイコンを追加
                              color: Colors.black,
                              size: 18.0, // アイコンの大きさを調整
                            ),
                            const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                            Text(
                              'チュートリアル終了',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black, // 色を白に指定
                                fontSize: 18, // 必要ならフォントサイズを変更
                                fontWeight: FontWeight.bold, // 太字に設定
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // 子ウィジェットの幅に合わせる
                          children: [
                            Icon(
                              Icons.play_arrow, // アイコンを追加
                              color: Colors.black,
                              size: 18.0, // アイコンの大きさを調整
                            ),
                            const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                            Text(
                                '次へ',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 18, // 必要ならフォントサイズを変更
                                    fontWeight: FontWeight.bold, // 太字に設定
                                    color: Colors.black, // テキストの色を指定
                                ),
                            ),
                          ],
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, int currentPage) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      width: currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: currentPage == index ? Colors.black : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}

class _HowToUsePage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final int index;

  const _HowToUsePage({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.description,
    this.index = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 0.0, // 左の余白
        top: 20.0, // 上の余白
        right: 0.0, // 右の余白を0に設定
        bottom: 20.0, // 下の余白
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        
        children: [
          // タイトルを上部に大きく表示
          Padding(
            padding: EdgeInsets.fromLTRB(
              20.0,	
              MediaQuery.of(context).size.height * 0.10, // 画面高さの20%
              0.0,	
              0.0,	
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 32, // 大きめのフォントサイズ
                fontWeight: FontWeight.bold,
                color: Colors.black, // 黒文字
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: index == 1
                  ? [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 2),
                              left: BorderSide.none, // 左側のボーダーを無しに
                              bottom: BorderSide(color: Colors.black, width: 2),
                              right: BorderSide(color: Colors.black, width: 2),
                            ),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8.0), // 右上の角を丸く
                              bottomRight: Radius.circular(8.0), // 右下の角を丸く
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8.0), // 左上の角を丸く
                              bottomRight: Radius.circular(8.0), // 左下の角を丸く
                            ),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain, // 高さに合わせて横幅を調整
                              alignment: Alignment.center, // 中央揃え
                            ),
                          ),
                        ),
                      ),

                      // 右側の説明文
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 0.0, // 上の余白
                            left: 20.0, // 左の余白
                            bottom: 200.0, // 下の余白
                            right: 20.0, // 右の余白を適用
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.black, // 黒文字
                              height: 1.5, // 行間を少し広げて読みやすく
                            ),
                          ),
                        ),
                      ),
                    ]
                  : [
                      // 左側の説明文
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 0.0, // 上の余白
                            left: 20.0, // 左の余白を0に設定
                            bottom: 200.0, // 下の余白
                            right: 20.0, // 右の余白を適用
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black, // 黒文字
                              height: 1.5, // 行間を少し広げて読みやすく
                            ),
                          ),
                        ),
                      ),
                      // 右側の画像
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 2),
                              left: BorderSide(color: Colors.black, width: 2),
                              bottom: BorderSide(color: Colors.black, width: 2),
                              right: BorderSide.none, // 右側のボーダーを無しに
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.0), // 左上の角を丸く
                              bottomLeft: Radius.circular(8.0), // 左下の角を丸く
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8.0), // 左上の角を丸く
                              bottomLeft: Radius.circular(8.0), // 左下の角を丸く
                            ),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain, // 高さに合わせて横幅を調整
                              alignment: Alignment.center, // 中央揃え
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
