import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import 'history_screen.dart';
import 'disease_guide_screen.dart';
import 'tips_care_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear Detection History?'),
        content: const Text('This removes all saved scans on this device. This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.instance.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detection history cleared.')),
        );
      }
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature isn\'t available yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Farmer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('All data stays on this device', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _MenuTile(
            icon: Icons.history_rounded,
            label: 'Detection History',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen(showBack: true))),
          ),
          _MenuTile(
            icon: Icons.menu_book_rounded,
            label: 'Disease Guide',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiseaseGuideScreen(showBack: true))),
          ),
          _MenuTile(
            icon: Icons.favorite_rounded,
            label: 'Tips & Care',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TipsCareScreen())),
          ),
          _MenuTile(
            icon: Icons.delete_outline_rounded,
            label: 'Clear Detection History',
            onTap: () => _confirmClearHistory(context),
          ),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
            onTap: () => _comingSoon(context, 'Help & Support'),
          ),
          _MenuTile(
            icon: Icons.info_outline_rounded,
            label: 'About',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'FishCare',
              applicationVersion: '1.0.0',
              children: const [
                Text('AI-powered fish disease detection, running fully on-device. No account or internet connection required.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: AppColors.surface,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: Icon(icon, color: AppColors.teal, size: 21),
          title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}
