import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class MypageScreen extends ConsumerWidget {
  final Function(int) onNavigate;

  MypageScreen({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    final cardsAsyncValue = ref.watch(cardsProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Category 1
          Container(
            color: Color(0xffff9900),
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category 1',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  cardsAsyncValue.when(
                    data: (cards) {
                      final category1Cards = cards
                          .where((card) => card.category == 'Category 1')
                          .toList();

                      return Column(
                        children: [
                          ...category1Cards.map((card) => CardItem(
                                title: card.title,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        title: card.title,
                                        initialText: card.description,
                                      ),
                                    ),
                                  );
                                },
                              )),
                          if (category1Cards.length < 5)
                            AddCardSkeleton(
                              onTap: () {
                                // カード追加処理
                              },
                            ),
                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  ),
                ],
              ),
            ),
          ),
          // Category 2
          Container(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category 2',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  cardsAsyncValue.when(
                    data: (cards) {
                      final category2Cards = cards
                          .where((card) => card.category == 'Category 2')
                          .toList();

                      return Column(
                        children: [
                          ...category2Cards.map((card) => CardItem(
                                title: card.title,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailScreen(
                                        title: card.title,
                                        initialText: card.description,
                                      ),
                                    ),
                                  );
                                },
                              )),
                          AddCardSkeleton(
                            onTap: () {
                              // カード追加処理
                            },
                          ),
                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
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

class CardItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  CardItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Card(
          elevation: 4.0,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddCardSkeleton extends StatelessWidget {
  final VoidCallback onTap;

  AddCardSkeleton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Card(
          elevation: 2.0,
          color: Colors.grey[300],
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Icon(Icons.add, size: 40, color: Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String title;
  final String initialText;

  DetailScreen({required this.title, required this.initialText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Screen',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Input Field',
                hintText: initialText,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
