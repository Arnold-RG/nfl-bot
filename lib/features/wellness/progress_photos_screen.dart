import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../shared/nf_design.dart';

/// Progress photo notes with optional camera / gallery image.
class ProgressPhotosScreen extends StatelessWidget {
  const ProgressPhotosScreen({super.key});

  Future<void> _add(BuildContext context, {required bool withPhoto}) async {
    HapticFeedback.mediumImpact();
    final state = context.read<AppState>();
    if (!withPhoto) {
      state.addProgressPhotoNote();
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.labCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.bronze),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.bronze),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      state.addProgressPhotoNote(
        imagePath: file.path,
        imageBytes: bytes,
      );
    } catch (_) {
      state.addProgressPhotoNote();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo unavailable — saved a check-in note instead.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pad = NfLayout.pagePad(context);
    final photos = state.progressPhotoNotes;

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(
        title: const Text('Progress photos'),
        actions: [
          TextButton(
            onPressed: () => _add(context, withPhoto: false),
            child: const Text('Note only'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, withPhoto: true),
        backgroundColor: AppTheme.bronze,
        foregroundColor: AppTheme.labBg,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add photo'),
      ),
      body: photos.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Text(
                  'No progress check-ins yet.\nAdd a real photo or a dated note — nothing is pre-filled.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 100),
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = photos[i];
                return NfGlassCard(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: p.imageBytes != null && p.imageBytes!.isNotEmpty
                              ? Image.memory(p.imageBytes!, fit: BoxFit.cover)
                              : Container(
                                  color: AppTheme.labLift,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.photo_outlined,
                                      color: AppTheme.bronze),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.label,
                                style: Theme.of(context).textTheme.titleSmall),
                            Text(p.whenLabel,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
