import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobApplyScreen extends StatefulWidget {
  final String jobId;

  const JobApplyScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobApplyScreen> createState() => _JobApplyScreenState();
}

class _JobApplyScreenState extends State<JobApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _showJobDetails = true;
  List<String> _messageTemplates = [];
  String? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _loadMessageTemplates();
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessageTemplates() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final templates = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('messageTemplates')
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      _messageTemplates =
          templates.docs.map((doc) => doc.data()['content'] as String).toList();
    });
  }

  Future<void> _saveMessageTemplate() async {
    if (_messageController.text.isEmpty) return;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('messageTemplates')
        .add({
      'content': _messageController.text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _loadMessageTemplates();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('ユーザーが見つかりません');

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .collection('applications')
          .doc(userId)
          .set({
        'userId': userId,
        'budget': int.parse(_budgetController.text.replaceAll(',', '')),
        'message': _messageController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('応募が完了しました'),
            backgroundColor: Color(0xFF00F7FF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1221),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B3F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00F7FF),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '案件に応募',
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.jobId)
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

            final jobData = snapshot.data?.data() as Map<String, dynamic>?;
            if (jobData == null) {
              return const Center(
                child: Text(
                  '案件が見つかりません',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildJobDetailsSection(jobData),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: '希望金額',
                            child: TextFormField(
                              controller: _budgetController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '¥30,000',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                prefixText: '¥',
                                prefixStyle: const TextStyle(
                                  color: Color(0xFF00F7FF),
                                  fontSize: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00F7FF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00F7FF),
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1A1B3F),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '希望金額を入力してください';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            title: '応募メッセージ',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_messageTemplates.isNotEmpty) ...[
                                  DropdownButtonFormField<String>(
                                    value: _selectedTemplate,
                                    items: [
                                      const DropdownMenuItem(
                                        value: null,
                                        child: Text(
                                          'テンプレートを選択',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                      ..._messageTemplates.map((template) {
                                        return DropdownMenuItem(
                                          value: template,
                                          child: Text(
                                            template,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _messageController.text = value;
                                        });
                                      }
                                    },
                                    decoration: InputDecoration(
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00F7FF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF00F7FF),
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFF1A1B3F),
                                    ),
                                    dropdownColor: const Color(0xFF1A1B3F),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                TextFormField(
                                  controller: _messageController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: '応募メッセージを入力してください',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF00F7FF),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF00F7FF),
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1A1B3F),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '応募メッセージを入力してください';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: _saveMessageTemplate,
                                  icon: const Icon(
                                    Icons.save_outlined,
                                    color: Color(0xFF00F7FF),
                                  ),
                                  label: const Text(
                                    'テンプレートとして保存',
                                    style: TextStyle(
                                      color: Color(0xFF00F7FF),
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
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
            onPressed: _isLoading ? null : _submitApplication,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F7FF),
              foregroundColor: const Color(0xFF1A1B3F),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1B3F),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
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

  Widget _buildJobDetailsSection(Map<String, dynamic> jobData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '案件内容',
              style: TextStyle(
                color: Color(0xFF00F7FF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showJobDetails = !_showJobDetails;
                });
              },
              icon: Icon(
                _showJobDetails
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF00F7FF),
              ),
              label: Text(
                _showJobDetails ? '非表示' : '表示',
                style: const TextStyle(
                  color: Color(0xFF00F7FF),
                ),
              ),
            ),
          ],
        ),
        if (_showJobDetails) ...[
          const SizedBox(height: 12),
          Container(
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
                  jobData['title'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  jobData['description'] as String? ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
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
    );
  }
}
