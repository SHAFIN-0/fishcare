import 'package:flutter/material.dart';
import 'models.dart';

/// Disease reference data. `id` values must match the class labels in assets/labels.txt
/// (one label per line, written by fish_training.ipynb). The current model predicts:
/// bacterial_gill_disease, bacterial_red_disease, eus, healthy.
/// The older entries (aeromoniasis, saprolegniasis, parasitic, white tail) are kept so the
/// disease guide and previously saved history records still display correctly.
class MockData {
  MockData._();

  static const List<DiseaseInfo> diseases = [
    DiseaseInfo(
      id: 'bacterial_red_disease',
      name: 'Bacterial Red Disease',
      category: DiseaseCategory.bacterial,
      commonName: 'Red Disease / Hemorrhagic Septicemia',
      affectedArea: 'Skin, Fins, Body',
      symptoms: 'Red or hemorrhagic patches on the body and fins, ulcers, lethargy',
      treatment: ['Improve pond water quality and reduce stocking density', 'Apply antibacterial treatment as advised by a fisheries expert', 'Isolate affected fish'],
      icon: Icons.water_drop_rounded,
      tint: Color(0xFFE0483F),
    ),
    DiseaseInfo(
      id: 'bacterial_aeromoniasis',
      name: 'Aeromoniasis',
      category: DiseaseCategory.bacterial,
      commonName: 'Motile Aeromonas Septicemia',
      affectedArea: 'Skin, Internal organs',
      symptoms: 'Skin ulcers, swollen abdomen, hemorrhaging, fin rot',
      treatment: ['Improve water quality and reduce organic load', 'Antibiotic treatment under professional guidance', 'Reduce handling stress and overcrowding'],
      icon: Icons.warning_amber_rounded,
      tint: Color(0xFFE0483F),
    ),
    DiseaseInfo(
      id: 'bacterial_gill_disease',
      name: 'Bacterial Gill Disease',
      category: DiseaseCategory.bacterial,
      commonName: 'Bacterial Gill Disease',
      affectedArea: 'Gills',
      symptoms: 'Swollen, pale, or mucus-covered gills, labored breathing, gasping at the surface',
      treatment: ['Improve aeration and water quality', 'Reduce ammonia levels', 'Antibacterial treatment as prescribed'],
      icon: Icons.air_rounded,
      tint: Color(0xFFE0483F),
    ),
    DiseaseInfo(
      id: 'fungal_saprolegniasis',
      name: 'Fungal Disease',
      category: DiseaseCategory.fungal,
      commonName: 'Saprolegniasis (Cotton Wool Disease)',
      affectedArea: 'Skin, Wounds, Eggs',
      symptoms: 'Cotton-like white or grey growths on skin or fins, lethargy',
      treatment: ['Improve water quality and reduce organic debris', 'Use antifungal treatment', 'Remove and treat affected individuals promptly'],
      icon: Icons.eco_rounded,
      tint: Color(0xFF2ECC8F),
    ),
    DiseaseInfo(
      id: 'parasitic_diseases',
      name: 'Parasitic Disease',
      category: DiseaseCategory.parasitic,
      commonName: 'Parasitic Infection',
      affectedArea: 'Skin, Gills, Fins',
      symptoms: 'Flashing/scratching against surfaces, visible spots or cysts, rapid gill movement',
      treatment: ['Use an appropriate anti-parasitic treatment', 'Improve water quality and filtration', 'Quarantine new fish before introducing them to the pond'],
      icon: Icons.grain_rounded,
      tint: Color(0xFF3E7BE0),
    ),
    DiseaseInfo(
      id: 'viral_white_tail_disease',
      name: 'Viral White Tail Disease',
      category: DiseaseCategory.viral,
      commonName: 'White Tail Disease',
      affectedArea: 'Tail, Muscle tissue',
      symptoms: 'Whitish, opaque discoloration of the tail or muscle tissue, lethargy, elevated mortality in young fish',
      treatment: ['No direct cure — remove and isolate affected fish immediately', 'Disinfect equipment and pond thoroughly', 'Consult a fisheries/aquaculture health expert'],
      icon: Icons.coronavirus_rounded,
      tint: Color(0xFFB84FE0),
    ),
    DiseaseInfo(
      id: 'eus',
      name: 'Epizootic Ulcerative Syndrome (EUS)',
      category: DiseaseCategory.fungal,
      commonName: 'EUS / Red Spot Disease',
      affectedArea: 'Skin, Muscle (open ulcers)',
      symptoms: 'Red spots or patches that develop into deep, open ulcers on the head, body or tail; lethargy; fish may hang near the surface. Outbreaks are most common in cooler, wet weather.',
      treatment: [
        'Contact your local fisheries officer or an aquaculture health expert early - EUS spreads quickly between ponds',
        'Remove and safely bury dead or badly affected fish; do not move fish or equipment from an affected pond to others',
        'Improve water quality and reduce stress; ask an expert which pond treatment (for example lime) suits your situation',
        'Treating established EUS is difficult, so prevention (pond preparation, clean water, avoiding stress) matters most',
      ],
      icon: Icons.healing_rounded,
      tint: Color(0xFFE08A2F),
    ),
  ];

  // ---- Result wording shared by the result screen, the report and the history list ----

  /// Red disease and EUS look alike in photos. On held-out fish the model called 11 of 14 EUS fish
  /// "red disease", so the app shows them as ONE look-alike group instead of pretending to know which.
  static const List<String> redLesionGroup = ['bacterial_red_disease', 'eus'];

  static bool isRedLesionGroup(String id) => redLesionGroup.contains(id);

  /// Combined probability the model gives to the red-lesion group (red disease + EUS).
  static double redLesionScore(Map<String, double> scores) =>
      redLesionGroup.fold(0.0, (sum, id) => sum + (scores[id] ?? 0.0));

  /// The v2 model's catch-all class: aeromoniasis, saprolegniasis, parasitic and white-tail photos from the web set were
  /// merged into one "sick, but not identified" answer so unfamiliar sick fish don't fall into "healthy".
  static const String otherDiseaseId = 'other_disease';

  static const String otherDiseaseNote =
      'The model sees signs of disease but cannot tell which one. This answer covers several diseases that look different '
      'from the ones it identifies well (for example bacterial septicemia, fungal or parasitic infections, and tail or fin damage). '
      'Ask a fisheries expert to examine the fish.';

  /// Name to show for a non-healthy model label.
  static String resultName(String label) {
    if (label == otherDiseaseId) return 'Other Disease Signs';
    if (isRedLesionGroup(label)) return 'Red Disease or EUS';
    return byId(label)?.name ?? label;
  }

  static const String lookAlikeNote =
      'Red disease and EUS look alike in photos, and in testing the model often mistook EUS for red disease. '
      'Treat this as a red-lesion disease and ask a fisheries expert to confirm which one it is.';

  static const String healthyNote =
      'This does not guarantee the fish is healthy. The model only looks at this one photo and can miss diseases. '
      'If the fish looks sick or acts strangely, ask a fisheries expert.';

  static const String scopeNote =
      'Automated estimate from a single photo, not a diagnosis. The model was trained on farm photos of rui, '
      'silver carp and grass carp from Bangladesh; other species or very different photos can give wrong results. '
      'If a fish looks sick, ask a fisheries expert.';

  /// Look up full disease info by the model's raw class id. Returns null
  /// for 'healthy' (not a disease) or an unrecognized id.
  static DiseaseInfo? byId(String id) {
    for (final d in diseases) {
      if (d.id == id) return d;
    }
    return null;
  }

  static const List<TipItem> tips = [
    TipItem(
      title: 'Maintain Water Quality',
      description: 'Keep ammonia, nitrite and nitrate levels in check.',
      icon: Icons.water_drop_rounded,
    ),
    TipItem(
      title: 'Proper Feeding',
      description: 'Avoid overfeeding and use high-quality feed.',
      icon: Icons.restaurant_rounded,
    ),
    TipItem(
      title: 'Regular Observation',
      description: 'Check fish behavior and look for early signs of disease.',
      icon: Icons.remove_red_eye_rounded,
    ),
    TipItem(
      title: 'Quarantine New Fish',
      description: 'Keep new fish separate for at least 7-14 days.',
      icon: Icons.shield_rounded,
    ),
    TipItem(
      title: 'Clean Your Pond/Tank',
      description: 'Remove waste and keep the environment clean.',
      icon: Icons.cleaning_services_rounded,
    ),
  ];
}
