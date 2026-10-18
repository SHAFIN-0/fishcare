import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme/app_colors.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final DiseaseInfo disease;
  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(disease.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: disease.tint.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(disease.icon, color: disease.tint, size: 42),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                child: Text(disease.category.label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _Block(label: 'Common Name', value: disease.commonName)),
                  const SizedBox(width: 16),
                  Expanded(child: _Block(label: 'Affected Area', value: disease.affectedArea)),
                ],
              ),
              const SizedBox(height: 14),
              _Block(label: 'Symptoms', value: disease.symptoms),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Treatment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 10),
                    ...disease.treatment.map((t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(t, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String label;
  final String value;
  const _Block({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
