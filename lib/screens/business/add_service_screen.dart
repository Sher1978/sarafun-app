import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/service_card_model.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Other';
  
  // Future expansion: Image Picker
  // File? _selectedImage; 

  bool _isLoading = false;

  final List<String> _categories = ['Cars', 'Health', 'Beauty', 'Events', 'Other'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final int? price = int.tryParse(_priceController.text);
      if (price == null) throw Exception("Invalid price");

      final newService = ServiceCard(
        masterId: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priceStars: price,
        category: _selectedCategory,
        mediaUrls: [], // TODO: Add Image upload logic
        isActive: true,
      );

      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.createServiceCard(newService);

      if (mounted) {
        context.pop(); // Go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service Created Successfully!", style: TextStyle(color: Colors.black)), backgroundColor: AppTheme.primaryGold),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text("NEW SERVICE", style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePlaceholder(),
              const Gap(32),
              
              _buildLabel("SERVICE TITLE"),
              _buildTextField(controller: _titleController, hint: "Ex: Luxury Car Rental", icon: Icons.title),
              
              const Gap(24),
              _buildLabel("CATEGORY"),
              _buildCategoryDropdown(),
              
              const Gap(24),
              _buildLabel("PRICE (STARS)"),
              _buildTextField(controller: _priceController, hint: "Ex: 500", icon: Icons.star, isNumber: true),
              
              const Gap(24),
              _buildLabel("DESCRIPTION"),
              _buildTextField(controller: _descController, hint: "Describe your exclusive service...", maxLines: 4),

              const Gap(40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("PUBLISH SERVICE", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: () {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image Upload Coming Soon")));
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3), width: 1, style: BorderStyle.solid), // Dashed effect hard in basic container, consistent solid fine
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryGold)),
              child: const Icon(Icons.add_a_photo, color: AppTheme.primaryGold, size: 32),
            ),
            const Gap(16),
            const Text("Upload Cover Image", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, IconData? icon, bool isNumber = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (val) => val == null || val.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white38) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          dropdownColor: AppTheme.cardColor,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryGold),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: _categories.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(c),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCategory = val);
          },
        ),
      ),
    );
  }
}
