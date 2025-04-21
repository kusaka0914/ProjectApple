import 'package:flutter/material.dart';

class JobTab extends StatelessWidget {
  const JobTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar(title: Text('仕事'), floating: true),
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.work_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '仕事情報はまだありません',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
