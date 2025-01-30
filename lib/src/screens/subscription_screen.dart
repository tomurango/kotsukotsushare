import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isPurchasing = false; // 購入処理中フラグ
  bool _isSubscribed = false; // 購読状態

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus(); // 初回起動時に購読状態を取得
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isSubscribed = customerInfo.entitlements.active.containsKey('premium');
      });
    } catch (e) {
      print('Error fetching subscription status: $e');
    }
  }

  Future<void> _handlePurchase() async {
    setState(() {
      _isPurchasing = true; // ローディング表示
    });

    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final package = offerings.current!.availablePackages.first;
        final customerInfo = await Purchases.purchasePackage(package);
        if (customerInfo.entitlements.active.containsKey('premium')) {
          setState(() {
            _isSubscribed = true; // 購読状態を更新
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('購入がキャンセルされました。')),
        );
      }
    } catch (e) {
      print('Purchase failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false; // ローディング解除
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A), // 背景色
      body: Stack(
        children: [
          _buildHeaderImage(),
          _buildContent(),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Positioned(
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: [Colors.white, Colors.transparent],
              stops: [0.7, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: Image.asset(
            'assets/images/premium/premium_header.jpg',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 186), // ヘッダー画像の高さ分のスペース
            _buildPremiumLogo(),
            _buildSubscriptionPlan(),
            SizedBox(height: 24),
            _buildBenefits(),
            SizedBox(height: 24),
            _buildSubscriptionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/images/premium/chokushii.svg',
          width: 60,
          height: 60,
          color: Colors.white,
        ),
        Text(
          "Premium",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSubscriptionPlan() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF295D58),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("月額プラン", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "¥2000",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                TextSpan(
                  text: " /月",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("毎月更新。いつでも解約可能。", style: TextStyle(fontSize: 14, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefits() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Premiumに登録すべき理由", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 16),
        _buildBenefitItem(icon: Icons.smart_toy, title: "AIアドバイス", description: "AIによるカスタマイズされたアドバイスが受け取れます。"),
        _buildBenefitItem(icon: Icons.chat, title: "AIチャット", description: "AIと会話して、アイデアを広げたり深めたりできます。"),
      ],
    );
  }

  Widget _buildSubscriptionButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 64, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        ),
        onPressed: (_isPurchasing || _isSubscribed) ? () {} : _handlePurchase,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isPurchasing
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Icon(Icons.play_arrow),
            SizedBox(width: 8),
            Text(_isSubscribed ? "すでに登録済み" : "Premiumを始める", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 60,
      left: 16,
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildBenefitItem({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(color: Color(0xFF295D58), borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(description, style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
