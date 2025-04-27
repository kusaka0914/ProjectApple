import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../jobs/job_detail_screen.dart';

class JobTab extends StatelessWidget {
  const JobTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        title: const Text(
          '案件一覧',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1221),
              Color(0xFF1A1B3F),
              Color(0xFF0B1221),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'エラーが発生しました',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F7FF),
                ),
              );
            }

            final jobs = snapshot.data?.docs ?? [];

            if (jobs.isEmpty) {
              return const Center(
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
                      '現在募集中の案件はありません',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index].data() as Map<String, dynamic>;
                final jobId = jobs[index].id;
                final createdAt = (job['createdAt'] as Timestamp).toDate();
                final timeAgo = timeago.format(createdAt, locale: 'ja');
                final deadline = (job['deadline'] as Timestamp).toDate();
                final daysUntilDeadline =
                    deadline.difference(DateTime.now()).inDays;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildJobCard(
                    context,
                    jobId: jobId,
                    title: job['title'] as String? ?? '',
                    budget: job['budget'] as int? ?? 0,
                    imageUrl: job['imageUrl'] as String?,
                    userName: job['userName'] as String? ?? '名無しさん',
                    userPhotoUrl: job['userPhotoUrl'] as String?,
                    timeAgo: timeAgo,
                    contractCount: job['contractCount'] as int? ?? 0,
                    numberOfPeople: job['numberOfPeople'] as int? ?? 1,
                    daysUntilDeadline: daysUntilDeadline,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context, {
    required String jobId,
    required String title,
    required int budget,
    String? imageUrl,
    required String userName,
    String? userPhotoUrl,
    required String timeAgo,
    required int contractCount,
    required int numberOfPeople,
    required int daysUntilDeadline,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailScreen(jobId: jobId),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Image.network(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
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
                    '¥${budget.toString().replaceAllMapped(
                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                          (Match m) => '${m[1]},',
                        )}',
                    style: const TextStyle(
                      color: Color(0xFF00F7FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.people,
                        label: '契約: $contractCount/$numberOfPeople人',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.timer,
                        label: '応募期限まで: ${daysUntilDeadline}日',
                        color:
                            daysUntilDeadline <= 3 ? Colors.red.shade300 : null,
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
                          backgroundImage: userPhotoUrl != null
                              ? NetworkImage(userPhotoUrl)
                              : null,
                          child: userPhotoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF00F7FF),
                                  size: 16,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          userName,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B3F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color ?? const Color(0xFF00F7FF),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color ?? const Color(0xFF00F7FF),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? const Color(0xFF00F7FF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
