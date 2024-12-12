import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import 'create_card_screen.dart';
import 'card_memo_screen.dart';

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
            color: Color(0xFF008080),
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '大切なこと',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  cardsAsyncValue.when(
                    data: (cards) {
                      final category1Cards = cards
                          .where((card) => card.category == 'important')
                          .toList();

                      return Column(
                        children: [
                          ...category1Cards.map((card) => CardItem(
                                title: card.title,
                                cardId: card.id,
                                description: card.description,
                              )),
                          if (category1Cards.length < 5)
                            AddCardSkeleton(
                              title: 'Important',
                              category: 'important',
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
                    '大切ではないこと',
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onBackground, // テーマに基づいた色
                    ),
                  ),
                  SizedBox(height: 8),
                  cardsAsyncValue.when(
                    data: (cards) {
                      final category2Cards = cards
                          .where((card) => card.category == 'unimportant')
                          .toList();

                      return Column(
                        children: [
                          ...category2Cards.map((card) => CardItem(
                                title: card.title,
                                cardId: card.id,
                                description: card.description,
                              )),
                          AddCardSkeleton( 
                            title: 'Unimportant',
                            category: 'unimportant',
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
  final String cardId; // カードIDを追加
  final String description;

  CardItem({required this.title, required this.cardId, required this.description/*, required this.onTap*/});

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardMemoScreen(cardId: cardId, title: title, description: description),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground, // テーマに基づいた色
                  ),
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
  final String title;
  final String category;
  final VoidCallback onTap;

  AddCardSkeleton({required this.title, required this.category, required this.onTap});

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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateCardScreen(
                  title: title,
                  category: category,
                )),
              );
            },
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
