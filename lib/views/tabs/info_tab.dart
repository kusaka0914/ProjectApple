import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1221),
            Color(0xFF1A1B3F),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: const Color(0xFF1A1B3F),
            title: const Text(
              '情報',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B3F).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Text(
                        'お知らせ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00F7FF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1B3F).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00F7FF),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F7FF).withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: Color(0xFF00F7FF),
                        ),
                        title: Text(
                          '新機能のお知らせ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '新しい機能が追加されました',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
