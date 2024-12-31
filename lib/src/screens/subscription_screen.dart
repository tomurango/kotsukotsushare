import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // 背景色
      body: Stack(
        children: [
          // 背景画像とフェードアウト効果
          Positioned(
            child: SizedBox(
              height: 250, // 画像の高さを指定
              width: double.infinity, // 横幅いっぱい
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    colors: [
                      Colors.white, // 上部はそのまま表示
                      Colors.transparent, // 下部は透明になる
                    ],
                    stops: [0.7, 1.0], // フェードの開始と終了位置
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn, // 透明化を適用
                child: Image.asset(
                  'assets/images/premium/premium_header.jpg', // ヘッダー画像
                  fit: BoxFit.cover, // 全体をカバー
                ),
              ),
            ),
          ),

          // スクロール可能なコンテンツ
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 186), // ヘッダー画像の高さ分のスペース
                  
                  // プレミアムロゴ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        'assets/images/premium/chokushii.svg',
                        width: 60, // 幅を指定
                        height: 60, // 高さを指定
                        color: Colors.white,
                      ),
                      Text(
                        "Premium",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // 月額プランの表示
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF295D58), // プラン背景色
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "月額プラン",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "¥2000",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: " /月",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "毎月更新。いつでも解約可能。",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Premiumの理由
                  Text(
                    "Premiumに登録すべき理由",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),

                  // 理由リスト
                  _buildBenefitItem(
                    icon: Icons.comment,
                    title: "コメントの確認",
                    description: "他のユーザーからのコメントを確認できます。",
                  ),
                  _buildBenefitItem(
                    icon: Icons.smart_toy,
                    title: "AIアドバイス",
                    description: "AIによるカスタマイズされたアドバイスが受け取れます。",
                  ),
                  _buildBenefitItem(
                    icon: Icons.chat,
                    title: "AIチャット",
                    description: "AIと会話して、アイデアを広げたり深めたりできます。",
                  ),
                  SizedBox(height: 24),

                  // Start Free Trialボタン
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // 背景色
                        foregroundColor: Colors.white, // テキスト色
                        padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      onPressed: () async {
                        // ボタン押下時の処理
                        try {
                            final offerings = await Purchases.getOfferings();
                            if (offerings.current != null) {
                            final package = offerings.current!.availablePackages.first;
                            final customerInfo = await Purchases.purchasePackage(package);
                            print('Purchase successful: ${customerInfo.entitlements.active}');
                            } else {
                            print('No offerings available.');
                            }
                        } catch (e) {
                            print('Purchase failed: $e');
                        }
                      },

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text(
                            "Premiumを始める",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 固定された戻るボタン
          Positioned(
            top: 60,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 利益項目を生成するヘルパーメソッド
  Widget _buildBenefitItem({
    IconData icon = Icons.check,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF295D58), // アイテム背景色
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
