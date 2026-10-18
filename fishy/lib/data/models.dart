import 'package:flutter/material.dart';

enum DiseaseCategory { bacterial, viral, fungal, parasitic }

extension DiseaseCategoryLabel on DiseaseCategory {
  String get label {
    switch (this) {
      case DiseaseCategory.bacterial:
        return 'Bacterial';
      case DiseaseCategory.viral:
        return 'Viral';
      case DiseaseCategory.fungal:
        return 'Fungal';
      case DiseaseCategory.parasitic:
        return 'Parasitic';
    }
  }
}

class DiseaseInfo {
  /// Must exactly match the raw class label the trained model returns
  /// (the folder name used under data/raw/<id>/ during training), so
  /// predictions from the API can be matched back to this entry.
  final String id;
  final String name;
  final DiseaseCategory category;
  final String commonName;
  final String affectedArea;
  final String symptoms;
  final List<String> treatment;
  final IconData icon;
  final Color tint;

  const DiseaseInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.commonName,
    required this.affectedArea,
    required this.symptoms,
    required this.treatment,
    required this.icon,
    required this.tint,
  });
}

class TipItem {
  final String title;
  final String description;
  final IconData icon;

  const TipItem({required this.title, required this.description, required this.icon});
}

/// Normalized result shape returned by both the real API and the demo fallback.
class PredictionResult {
  final String label;
  final double confidence;
  final Map<String, double> allScores;
  final bool isDemo;

  const PredictionResult({
    required this.label,
    required this.confidence,
    required this.allScores,
    this.isDemo = false,
  });

  bool get isHealthy => label.toLowerCase() == 'healthy';
}
