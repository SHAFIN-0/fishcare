import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../widgets/brand_widgets.dart';
import 'analysis_result_screen.dart';

class DetectDiseaseScreen extends StatelessWidget {
  const DetectDiseaseScreen({super.key});

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    // ImageSource.camera opens the OS's native camera UI directly.
    final picked = await picker.pickImage(source: source, maxWidth: 1024, imageQuality: 88);
    if (picked == null || !context.mounted) return;
    // Read as bytes (not a File/path) so this works on web, mobile, and desktop alike.
    final bytes = await picked.readAsBytes();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AnalysisResultScreen(imageBytes: bytes, fileName: picked.name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detect Disease')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _pick(context, ImageSource.camera),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_outlined, size: 30, color: AppColors.teal),
                      ),
                      const SizedBox(height: 14),
                      const Text('Tap to take a photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Text('or upload from gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tips for better results:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              const _TipLine('One fish per photo, filling most of the frame'),
              const _TipLine('Show the affected area (gills, skin, fins, ulcers or red spots) in sharp focus'),
              const _TipLine('Use natural daylight and avoid flash glare'),
              const _TipLine('Best for rui, silver carp and grass carp; other species may give wrong results'),
              const _TipLine('Use your own photos, not screenshots or pictures from the internet'),
              const Spacer(),
              GradientButton(
                label: 'Upload Image',
                icon: Icons.upload_rounded,
                onPressed: () => _pick(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipLine extends StatelessWidget {
  final String text;
  const _TipLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
