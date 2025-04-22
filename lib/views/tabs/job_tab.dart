import 'package:flutter/material.dart';

class JobTab extends StatelessWidget {
  const JobTab({super.key});

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
      child: const CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              '仕事',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            floating: true,
            backgroundColor: Color(0xFF1A1B3F),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_outlined,
                      size: 64,
                      color: Color(0xFF00F7FF),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '仕事情報はまだありません',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
