import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';

class HistoryCard extends StatelessWidget {
  final HistoryRecord record;
  const HistoryCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final displayName = record.isUncertain
        ? 'Uncertain'
        : (record.isHealthy ? 'No Disease Signs' : MockData.resultName(record.label));
    final tint = record.isUncertain
        ? AppColors.warning
        : (record.isHealthy ? AppColors.warning : AppColors.danger);
    final confidenceLabel = record.confidence >= 0.85
        ? 'High Confidence'
        : record.confidence >= 0.6
            ? 'Medium Confidence'
            : 'Low Confidence';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: record.thumbnailBase64 != null
                ? Image.memory(
                    base64Decode(record.thumbnailBase64!),
                    width: 52, height: 52, fit: BoxFit.cover,
                  )
                : Container(
                    width: 52, height: 52,
                    color: tint.withValues(alpha: 0.15),
                    child: Icon(
                      record.isUncertain
                          ? Icons.help_outline_rounded
                          : (record.isHealthy ? Icons.info_outline_rounded : Icons.coronavirus_rounded),
                      color: tint,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      record.isUncertain
                          ? 'Not confidently matched'
                          : (record.isHealthy ? 'Not a health guarantee' : confidenceLabel),
                      style: TextStyle(fontSize: 12, color: tint, fontWeight: FontWeight.w600),
                    ),
                    if (!record.isHealthy) ...[
                      const Text(' · ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text('${(record.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(DateFormat('MMM d, yyyy \u2022 h:mm a').format(record.date),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiseaseGuideCard extends StatelessWidget {
  final DiseaseInfo disease;
  final VoidCallback onTap;
  const DiseaseGuideCard({super.key, required this.disease, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: disease.tint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(disease.icon, color: disease.tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disease.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(disease.category.label,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
