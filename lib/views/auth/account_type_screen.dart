import 'package:flutter/material.dart';
import '../../models/account_type.dart';
import 'business_setup_screen.dart';
import 'personal_setup_screen.dart';

class AccountTypeScreen extends StatelessWidget {
  const AccountTypeScreen({super.key});

  void _navigateToSetup(BuildContext context, AccountType type) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => type == AccountType.business
            ? const BusinessSetupScreen()
            : const PersonalSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウントタイプの選択'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'アカウントタイプを選択してください',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _AccountTypeCard(
              type: AccountType.personal,
              icon: Icons.person,
              description: '個人での利用',
              onTap: () => _navigateToSetup(context, AccountType.personal),
            ),
            const SizedBox(height: 16),
            _AccountTypeCard(
              type: AccountType.business,
              icon: Icons.business,
              description: '企業での利用',
              onTap: () => _navigateToSetup(context, AccountType.business),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final AccountType type;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.type,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(icon, size: 48),
              const SizedBox(height: 16),
              Text(
                type.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
