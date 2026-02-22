import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/review_model.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final String serviceId;
  
  const CreateReviewScreen({super.key, required this.serviceId});

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _commentController = TextEditingController();
  final Map<String, int> _abcdScore = {'a': 5, 'b': 5, 'c': 5, 'd': 5};
  final List<Uint8List> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImages.add(bytes);
      });
    }
  }

  Future<void> _submitReview() async {
    // Rating is mandatory (min 1.0), initialized to 5.0 so always valid.
    // Comment and Photos are optional.

    setState(() => _isSubmitting = true);

    try {
      final firebaseService = ref.read(firebaseServiceProvider);
      final user = ref.read(currentUserProvider).value!;

      // 1. Upload Images
      final List<String> photoUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final path = 'reviews/${widget.serviceId}/${user.uid}_$i.jpg';
        final url = await firebaseService.uploadImage(_selectedImages[i], path);
        if (url != null) photoUrls.add(url);
      }

      // 2. Create Review Object
      final review = Review(
        id: "rev_${DateTime.now().millisecondsSinceEpoch}", // Temp ID
        serviceId: widget.serviceId,
        clientId: user.uid,
        clientName: user.telegramId.toString(), // Or fetch generic name
        abcdScore: Map.from(_abcdScore),
        isVerifiedPurchase: false, // Default until verified by deals
        comment: _commentController.text,
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      // 3. Submit
      await firebaseService.submitReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review Submitted!")));
        context.pop(); // Close Review Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Write a Review")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Assessment ABCD", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(16),
            _buildABCDSlider("A (Able)", "a", "Competence & Quality"),
            _buildABCDSlider("B (Believable)", "b", "Price & Honesty"),
            _buildABCDSlider("C (Connected)", "c", "Service & Comfort"),
            _buildABCDSlider("D (Dependable)", "d", "Deadlines & Reliability"),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Add Photos (Max 3)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${_selectedImages.length}/3", style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _selectedImages.length < 3 
                      ? GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.add_a_photo, color: Colors.white60),
                          ),
                        )
                      : const SizedBox();
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_selectedImages[index], width: 100, height: 100, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const Gap(24),
            const Text("Your Review", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(8),
            TextField(
              controller: _commentController,
              maxLength: 360,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Share your experience...",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.cardColor,
              ),
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text("Submit Review", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildABCDSlider(String label, String key, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Text(
              _abcdScore[key].toString(),
              style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        Slider(
          value: _abcdScore[key]!.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: AppTheme.primaryGold,
          inactiveColor: Colors.white12,
          onChanged: (val) => setState(() => _abcdScore[key] = val.toInt()),
        ),
        const Gap(8),
      ],
    );
  }
}
