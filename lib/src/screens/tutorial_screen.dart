import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// ページごとにオーバーレイの状態を管理する StateProvider
final overlayVisibilityProviderFamily = StateProvider.family<bool, int>((ref, pageIndex) => false);

class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  _TutorialScreenState createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final tutorialPages = [
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: '自分にとって\n大切なことを見つける',
        description: 'このアプリでは、あなたが「大切」と感じることを5つまで考えることから始めます。\n\n上限を設けることで、大切なものとそうでないものを明確に区別し、重要でないものに振り回されることを減らせます。',
        pageIndex: 0,
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: '日々の気付きを\nメモに残す',
        description: '大切なことについての気付きをメモに残しましょう。\n\n重要なことから、些細なことでも大丈夫です。\n\n書き留めることで、気持ちが整理され、次の行動に活かせるようになります。',
        pageIndex: 1,
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: 'ふとした時に\n思い出す',
        description: 'ついダラダラと過ごしてしまう時や、やるべきことに集中できない時も、まずはそんな自分を認めることが大切です。\n\nそして、「本当に大切なこと」を思い出せるようにしましょう。\n\n自分にとって大切なことを思い出すことで、忙しい毎日でも自分らしさを少しずつ取り戻せます。',
        pageIndex: 2,
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: 'みんなの価値観や\n知識を知る',
        description: '他のユーザーがどのように考え、大切にしていることを知り、自分の考えを見直してみましょう。\n\n視点を広げ、新たなアイデアや気付きが得られることは、日常のコミュニケーションや成長にも役立ちます。\n\nAIチャット機能も開発中です。ご期待ください。',
        pageIndex: 3,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: tutorialPages.length, // ページ数
            onPageChanged: (index) {
              // 現在のページ状態を初期化
              ref.read(overlayVisibilityProviderFamily(_currentPage).notifier).state = false;
              setState(() {
                _currentPage = index; // 現在のページを更新
              });
            },
            itemBuilder: (context, index) {
              return tutorialPages[index];
            },
          ),
          Positioned(
            bottom: 50,
            left: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                tutorialPages.length,
                (index) => Consumer(
                  builder: (context, ref, child) {
                    final isOverlayVisible = ref.watch(overlayVisibilityProviderFamily(index));
                    return _buildPageIndicator(index, isOverlayVisible);
                  },
                ),
              ),
            ),
          ),
          // ボタン (次へ or 終了)
          Positioned(
            bottom: 30,
            right: 20,
            child: _currentPage == tutorialPages.length - 1
                ? TextButton(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // チュートリアル完了フラグを更新
                        final userDoc = FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid);
                        await userDoc.update({'tutorialCompleted': true});
                      }
                      Navigator.of(context).pop(); // スクリーンを閉じる
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // 子ウィジェットの幅に合わせる
                      children: [
                        Icon(
                          Icons.play_arrow, // アイコンを追加
                          color: Colors.white,
                          size: 18.0, // アイコンの大きさを調整
                        ),
                        const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                        Text(
                          'チュートリアル終了',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white, // 色を白に指定
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
                          color: Colors.white,
                          size: 18.0, // アイコンの大きさを調整
                        ),
                        const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                        Text(
                            '次へ',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 18, // 必要ならフォントサイズを変更
                                fontWeight: FontWeight.bold, // 太字に設定
                                color: Colors.white, // テキストの色を指定
                            ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, bool isOverlayVisible) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      //width: 12.0,
      width: _currentPage == index ? 12.0 : 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: (_currentPage == index && isOverlayVisible)
            ? const Color(0xFF008080) // アクティブ状態
            : (_currentPage == index ? Colors.white : Colors.grey),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
}


class _TutorialPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;
  final int pageIndex; // ページ番号を追加

  const _TutorialPage({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.description,
    required this.pageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isOverlayVisible = ref.watch(overlayVisibilityProviderFamily(pageIndex)); // ページごとの状態を参照

        return Stack(
          fit: StackFit.expand,
          children: [
            // 背景画像
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            // メインコンテンツ
            if (!isOverlayVisible)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.55,
                left: 10.0,

                child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                TextButton(
                    onPressed: () {
                        ref.read(overlayVisibilityProviderFamily(pageIndex).notifier).state = true; // 詳細表示
                    },
                    child: Row(
                    mainAxisSize: MainAxisSize.min, // 必要なサイズに縮小
                    children: [
                        Icon(
                        Icons.play_arrow, // Google Material Icons のアイコン
                        color: Colors.white,
                        size: 36,
                        ),
                        const SizedBox(width: 4), // アイコンとテキストの間の余白
                        Flexible(
                            child: Text(
                                title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    ),
                                overflow: TextOverflow.ellipsis,
                            ),
                        ),
                    ],
                    ),
                ),
                ],
                ),
              ),

            // 詳細表示オーバーレイ
            if (isOverlayVisible)
              GestureDetector(
                onTap: () {
                  ref.read(overlayVisibilityProviderFamily(pageIndex).notifier).state = false; // 詳細非表示
                },
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        16.0,	
                        MediaQuery.of(context).size.height * 0.1, // 画面高さの20%を余白として設定	
                        16.0,	
                        16.0,	
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            title,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 30, // 必要ならフォントサイズを変更
                                color: Colors.white, // テキストの色を指定
                            ),
                            textAlign: TextAlign.left, // 左寄せ
                        ),
                        const SizedBox(height: 24),
                        Text(
                          description,
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}