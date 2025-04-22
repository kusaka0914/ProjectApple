import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'job_apply_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
  });

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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .doc(jobId)
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

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  '案件が見つかりません',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final jobData = snapshot.data!.data() as Map<String, dynamic>;
            final createdAt = (jobData['createdAt'] as Timestamp).toDate();
            final timeAgo = timeago.format(createdAt, locale: 'ja');

            return CustomScrollView(
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
                    '案件詳細',
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
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (jobData['imageUrl'] != null)
                        Image.network(
                          jobData['imageUrl'] as String,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jobData['title'] as String? ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '¥${(jobData['budget'] as int? ?? 0).toString().replaceAllMapped(
                                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                    (Match m) => '${m[1]},',
                                  )}',
                              style: const TextStyle(
                                color: Color(0xFF00F7FF),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSection(
                              title: '案件詳細',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    jobData['details'] as String? ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.people,
                                        label:
                                            '契約: ${jobData['contractCount'] as int? ?? 0}/${jobData['numberOfPeople'] as int? ?? 1}人',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _buildInfoChip(
                                        icon: Icons.timer,
                                        label:
                                            '応募期限まで: ${(jobData['deadline'] as Timestamp).toDate().difference(DateTime.now()).inDays}日',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: '応募状況',
                              child: Text(
                                '応募者数: ${jobData['applicantsCount'] as int? ?? 0}人',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'クライアント情報',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                              color: const Color(0xFF00F7FF)
                                                  .withOpacity(0.2),
                                              blurRadius: 8,
                                              spreadRadius: -2,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              const Color(0xFF1A1B3F),
                                          backgroundImage:
                                              jobData['userPhotoUrl'] != null
                                                  ? NetworkImage(
                                                      jobData['userPhotoUrl']
                                                          as String)
                                                  : null,
                                          child: jobData['userPhotoUrl'] == null
                                              ? const Icon(
                                                  Icons.person,
                                                  color: Color(0xFF00F7FF),
                                                )
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              jobData['userName'] as String? ??
                                                  '名無しさん',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (jobData['userBio'] != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                jobData['userBio'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSection(
                              title: 'クライアントの評価',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFF00F7FF),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(jobData['companyRating'] as num? ?? 0.0).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${jobData['companyReviewsCount'] as int? ?? 0}件の評価)',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B3F),
          border: const Border(
            top: BorderSide(
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
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobApplyScreen(jobId: jobId),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F7FF),
              foregroundColor: const Color(0xFF1A1B3F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              '応募する',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00F7FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
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
