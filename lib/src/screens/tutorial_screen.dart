import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final tutorialPages = [
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: '自分にとって\n大切なことを見つける',
        description: 'このアプリでは、あなたが「大切」と感じることを5つまで考えることから始めます。\n\n上限を設けることで、大切なものとそうでないものを明確に区別し、重要でないものに振り回されることを減らせます。',
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: '気付きを\nメモに残す',
        description: '気付いた大切なことをメモに残しましょう。\n短い文章でも大丈夫です。\n\n書き留めることで、気持ちが整理され、次の行動に活かせるようになります。',
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: 'ふとした時に\n思い出す',
        description: 'ついダラダラと過ごしてしまう時や、やるべきことに集中できない時も、まずはそんな自分を認めることが大切です。\n\nそして、「本当に大切なこと」を思い出せるようにしましょう。\n\n自分にとって大切なことを思い出すことで、忙しい毎日でも自分らしさを少しずつ取り戻せます。',
      ),
      _TutorialPage(
        imagePath: 'assets/images/DSC_0021.JPG',
        title: 'みんなの価値観や\n知識を知る',
        description: '他のユーザーがどのように考え、大切にしていることを知り、自分の考えを見直してみましょう。\n\n視点を広げ、新たなアイデアや気付きが得られることは、日常のコミュニケーションや成長にも役立ちます。\n\nAIチャット機能も開発中です。ご期待ください。',
      ),
    ];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ページビュー (背景のチュートリアル画像を切り替える)
          PageView.builder(
            controller: _pageController,
            itemCount: tutorialPages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return tutorialPages[index];
            },
          ),
          // ページインジケーター
          Positioned(
            bottom: 50,
            left: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                tutorialPages.length,
                (index) => _buildPageIndicator(index),
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
                    /*style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5), // 半透明背景
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),*/
                    child: Row(
                        mainAxisSize: MainAxisSize.min, // 子ウィジェットの幅に合わせる
                        children: [
                            Icon(
                                Icons.play_arrow, // アイコンを追加
                                color: Colors.white,
                                size: 20.0, // アイコンの大きさを調整
                            ),
                            const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                            Text(
                                'チュートリアルを終了する',
                                style: Theme.of(context).textTheme.apply(
                                    fontFamily: 'ZenKakuGothicNew', // フォントを指定
                                    ).bodyLarge?.copyWith(
                                    color: Colors.white, // 色を白に指定
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
                                size: 20.0, // アイコンの大きさを調整
                            ),
                            const SizedBox(width: 4), // アイコンとテキストの間にスペースを追加
                            Text(
                                '次へ',
                                style: Theme.of(context).textTheme.apply(
                                    fontFamily: 'ZenKakuGothicNew', // フォントを指定
                                    ).bodyLarge?.copyWith(
                                    color: Colors.white, // 色を白に指定
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

  
  Widget _buildPageIndicator(int index) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        width: _currentPage == index ? 12.0 : 8.0,
        height: 8.0,
        decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFF008080) : Colors.grey,
        // color: _currentPage == index ? Colors.white : Colors.grey,
        borderRadius: BorderRadius.circular(4.0),
        ),
    );
  }
}

class _TutorialPage extends StatefulWidget {
  final String imagePath;
  final String title;
  final String description;

  const _TutorialPage({
    Key? key,
    required this.imagePath,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  __TutorialPageState createState() => __TutorialPageState();
}

class __TutorialPageState extends State<_TutorialPage> {
  bool _isOverlayVisible = false; // 薄黒いスクリーンの表示状態

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景画像
        Image.asset(
          widget.imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),

        // メインコンテンツ
        if (!_isOverlayVisible) // 薄黒いスクリーンが表示されていないときだけ表示
        Stack(
          children: [
            // 他のウィジェット（例えば背景画像など）はここに追加可能
            Positioned(
            top: MediaQuery.of(context).size.height * 0.55, // 画面全体の55%の高さ
            left: 10,    // 左側の余白
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                TextButton(
                    onPressed: () {
                    setState(() {
                        _isOverlayVisible = true; // オーバーレイを表示
                    });
                    },
                    child: Row(
                    mainAxisSize: MainAxisSize.min, // 必要なサイズに縮小
                    children: [
                        Icon(
                        Icons.play_arrow, // Google Material Icons のアイコン
                        color: Colors.white,
                        size: 28,
                        ),
                        const SizedBox(width: 4), // アイコンとテキストの間の余白
                        Flexible(
                            child: Text(
                                widget.title,
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
          ],
        ),


        // オーバーレイ (薄黒いスクリーン)
        if (_isOverlayVisible)
          GestureDetector(
            onTap: () {
              setState(() {
                _isOverlayVisible = false; // オーバーレイを閉じる
              });
            },
            child: Container(
                color: Colors.black.withOpacity(0.8), // 半透明の黒
                child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        16.0,
                        MediaQuery.of(context).size.height * 0.1, // 画面高さの20%を余白として設定
                        16.0,
                        16.0,
                    ),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, // 左寄せ
                    children: [
                        Text(
                        widget.title,
                        style: Theme.of(context).textTheme.apply(
                                fontFamily: 'ZenKakuGothicNew', // フォントをZenKakuGothicNewに変更
                            ).bodyLarge?.copyWith(
                                fontSize: 30, // フォントサイズを指定
                                color: Colors.white, // テキストの色を白に設定
                            ),
                        textAlign: TextAlign.left, // 左寄せ
                        ),
                        const SizedBox(height: 24),
                        Text(
                        widget.description,
                        style: Theme.of(context).textTheme.apply(
                                fontFamily: 'ZenKakuGothicNew', // フォントをZenKakuGothicNewに変更
                            ).bodyLarge?.copyWith(
                                fontSize: 20, // フォントサイズを指定
                                color: Colors.white, // テキストの色を白に設定
                            ),
                        textAlign: TextAlign.left, // 左寄せ
                        ),
                    ],
                    ),
                ),
            ),
          ),
      ],
    );
  }
}
