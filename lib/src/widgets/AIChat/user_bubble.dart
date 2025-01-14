import 'package:flutter/material.dart';

class UserBubble extends StatelessWidget {
  final String message;
  final String time;

  const UserBubble({
    required this.message,
    required this.time,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end, 
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 時間（左に配置）
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8), // 時間と吹き出しの間の余白
          // 吹き出し（右に配置）
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  // 右上を尖らせる部分
                  Positioned(
                    top: -6,
                    right: -6,
                    child: CustomPaint(
                      size: const Size(12, 12),
                      painter: BubbleTailPainter(Colors.teal.shade50),
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
}

class BubbleTailPainter extends CustomPainter {
  final Color color;

  BubbleTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
