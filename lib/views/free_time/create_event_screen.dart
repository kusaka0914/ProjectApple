import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class CreateEventScreen extends StatefulWidget {
  final File imageFile;
  final VoidCallback onEventCreated;

  const CreateEventScreen({
    Key? key,
    required this.imageFile,
    required this.onEventCreated,
  }) : super(key: key);

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedType = '食事';

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが認証されていません');
      }

      // 画像をアップロード
      final String fileName = path.basename(widget.imageFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('free_time_event_images')
          .child(DateTime.now().toString() + '_' + fileName);

      await ref.putFile(widget.imageFile);
      final imageUrl = await ref.getDownloadURL();

      // イベントをFirestoreに保存
      final eventDoc =
          await FirebaseFirestore.instance.collection('free_time_events').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'budget': int.parse(_budgetController.text),
        'maxParticipants': int.parse(_maxParticipantsController.text),
        'date': Timestamp.fromDate(_selectedDate),
        'type': _selectedType,
        'createdBy': user.uid,
        'participants': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });

      // チャットルームを作成
      await FirebaseFirestore.instance.collection('group_chats').add({
        'eventId': eventDoc.id,
        'title': _titleController.text,
        'members': [user.uid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageTime': null,
      });

      widget.onEventCreated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今暇イベントを作成')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(widget.imageFile, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'タイトル'),
                      validator: (value) =>
                          value?.isEmpty == true ? 'タイトルを入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: '説明'),
                      maxLines: 3,
                      validator: (value) =>
                          value?.isEmpty == true ? '説明を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: '場所'),
                      validator: (value) =>
                          value?.isEmpty == true ? '場所を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _budgetController,
                      decoration: const InputDecoration(labelText: '予算'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return '予算を入力してください';
                        if (int.tryParse(value!) == null) return '数値を入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maxParticipantsController,
                      decoration: const InputDecoration(labelText: '最大参加人数'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return '最大参加人数を入力してください';
                        if (int.tryParse(value!) == null) return '数値を入力してください';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('日時'),
                      subtitle: Text(_selectedDate.toString()),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: 'タイプ'),
                      items: ['食事', 'カフェ', 'スポーツ', '勉強', 'ゲーム', 'その他']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createEvent,
                        child: const Text('イベントを作成'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
