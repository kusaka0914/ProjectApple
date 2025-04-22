import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'part_time_job_detail_screen.dart';

class PartTimeJobListScreen extends StatelessWidget {
  const PartTimeJobListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
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
              backgroundColor: const Color(0xFF1A1B3F),
              pinned: true,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF00F7FF),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'アルバイト一覧',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  border: const Border(
                    bottom: BorderSide(
                      color: Color(0xFF00F7FF),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00F7FF).withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -5,
                    ),
                  ],
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('partTimeJobs')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'エラーが発生しました',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00F7FF),
                      ),
                    ),
                  );
                }

                final jobs = snapshot.data?.docs ?? [];

                if (jobs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 48,
                            color: Color(0xFF00F7FF),
                          ),
                          SizedBox(height: 16),
                          Text(
                            '現在募集中のアルバイトはありません',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final job = jobs[index].data() as Map<String, dynamic>;
                        final jobId = jobs[index].id;
                        final createdAt =
                            (job['createdAt'] as Timestamp).toDate();
                        final timeAgo = timeago.format(createdAt, locale: 'ja');

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildJobCard(
                            context,
                            jobId: jobId,
                            title: job['title'] as String? ?? '',
                            hourlyWage: job['hourlyWage'] as int? ?? 0,
                            location: job['location'] as String? ?? '',
                            workingHours: job['workingHours'] as String? ?? '',
                            companyName: job['companyName'] as String? ?? '',
                            companyIconUrl: job['companyIconUrl'] as String?,
                            timeAgo: timeAgo,
                          ),
                        );
                      },
                      childCount: jobs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context, {
    required String jobId,
    required String title,
    required int hourlyWage,
    required String location,
    required String workingHours,
    required String companyName,
    String? companyIconUrl,
    required String timeAgo,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PartTimeJobDetailScreen(jobId: jobId),
          ),
        );
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '時給 ¥${hourlyWage.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    )}',
                style: const TextStyle(
                  color: Color(0xFF00F7FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF00F7FF),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF00F7FF),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    workingHours,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00F7FF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F7FF).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1A1B3F),
                      backgroundImage: companyIconUrl != null
                          ? NetworkImage(companyIconUrl)
                          : null,
                      child: companyIconUrl == null
                          ? const Icon(
                              Icons.business,
                              color: Color(0xFF00F7FF),
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
