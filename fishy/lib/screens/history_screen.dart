import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../widgets/list_cards.dart';

class HistoryScreen extends StatefulWidget {
  final bool showBack;
  const HistoryScreen({super.key, this.showBack = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryRecord>? _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await HistoryService.instance.getAll();
    if (!mounted) return;
    setState(() => _records = records);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection History')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_records == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    }
    if (_records!.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('No detections yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    SizedBox(height: 6),
                    Text(
                      'Scan a fish from the Home tab and your results will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _records!.length,
      itemBuilder: (context, i) => HistoryCard(record: _records![i]),
    );
  }
}
