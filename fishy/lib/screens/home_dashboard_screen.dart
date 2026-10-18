import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_widgets.dart';
import 'detect_disease_screen.dart';
import 'history_screen.dart';
import 'disease_guide_screen.dart';
import 'tips_care_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  ({int total, int healthy, int needsAttention}) _stats = (total: 0, healthy: 0, needsAttention: 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await HistoryService.instance.getStats();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<void> _openDetect() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DetectDiseaseScreen()));
    _loadStats(); // refresh stats in case a new detection was saved
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Farmer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Keep your fish healthy!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  StatCard(label: 'Total Scans', value: '${_stats.total}'),
                  const SizedBox(width: 10),
                  StatCard(label: 'No Signs', value: '${_stats.healthy}'),
                  const SizedBox(width: 10),
                  StatCard(label: 'Needs Attention', value: '${_stats.needsAttention}', valueColor: AppColors.danger),
                ],
              ),
              if (_stats.total == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Stats are based on your scans on this device. Scan a fish to get started.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ),
              const SizedBox(height: 24),
              QuickActionTile(
                icon: Icons.camera_alt_rounded,
                title: 'Detect Disease',
                subtitle: 'Take or upload a photo for instant analysis',
                highlighted: true,
                onTap: _openDetect,
              ),
              QuickActionTile(
                icon: Icons.history_rounded,
                title: 'History',
                subtitle: 'View past detections on this device',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen(showBack: true))),
              ),
              QuickActionTile(
                icon: Icons.menu_book_rounded,
                title: 'Disease Guide',
                subtitle: 'Learn about common diseases',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiseaseGuideScreen(showBack: true))),
              ),
              QuickActionTile(
                icon: Icons.favorite_rounded,
                title: 'Tips & Care',
                subtitle: 'Best practices for healthy fish',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TipsCareScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
