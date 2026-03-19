import 'package:flutter/material.dart';
import 'package:dreamloop/config/theme.dart';
import 'package:provider/provider.dart';
import 'package:dreamloop/services/auth_service.dart';
import 'package:dreamloop/services/firestore_service.dart';
import 'package:dreamloop/models/user_model.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  int _selectedHair = 0;
  int _selectedOutfit = 0;
  int _selectedAccessory = 0;
  int _selectedColor = 0;

  final List<Map<String, dynamic>> _hairStyles = [
    {'name': 'Short', 'icon': Icons.face},
    {'name': 'Long', 'icon': Icons.face_3},
    {'name': 'Curly', 'icon': Icons.face_4},
    {'name': 'Spiky', 'icon': Icons.face_6},
  ];

  final List<Map<String, dynamic>> _outfits = [
    {'name': 'Explorer', 'icon': Icons.hiking},
    {'name': 'Wizard', 'icon': Icons.auto_fix_high},
    {'name': 'Knight', 'icon': Icons.shield},
    {'name': 'Cozy', 'icon': Icons.checkroom},
  ];

  final List<Map<String, dynamic>> _accessories = [
    {'name': 'None', 'icon': Icons.block},
    {'name': 'Crown', 'icon': Icons.stars},
    {'name': 'Scarf', 'icon': Icons.ac_unit},
    {'name': 'Wings', 'icon': Icons.air},
  ];

  final List<Color> _colors = [
    DreamColors.primary,
    DreamColors.accent,
    DreamColors.cute,
    DreamColors.warning,
    DreamColors.mystery,
    const Color(0xFF00B894),
  ];
  final _firestoreService = FirestoreService();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Your Character')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Character preview
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _colors[_selectedColor],
                        _colors[_selectedColor].withValues(alpha: 0.5),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _colors[_selectedColor].withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _hairStyles[_selectedHair]['icon'] as IconData,
                    size: 72,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Hairstyle
              _buildSection(
                'Hairstyle',
                _hairStyles,
                _selectedHair,
                (i) => setState(() => _selectedHair = i),
              ),

              const SizedBox(height: 24),

              // Outfit
              _buildSection(
                'Outfit',
                _outfits,
                _selectedOutfit,
                (i) => setState(() => _selectedOutfit = i),
              ),

              const SizedBox(height: 24),

              // Accessories
              _buildSection(
                'Accessory',
                _accessories,
                _selectedAccessory,
                (i) => setState(() => _selectedAccessory = i),
              ),

              const SizedBox(height: 24),

              // Color palette
              Text('Color', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  _colors.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _colors[index],
                          border: Border.all(
                            color: _selectedColor == index
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: _selectedColor == index
                              ? [
                                  BoxShadow(
                                    color: _colors[index].withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: DreamColors.error),
                  ),
                ),

              // Create button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCharacterAndContinue,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Character'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCharacterAndContinue() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userId == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final customization = {
      'hair_style': _hairStyles[_selectedHair]['name'],
      'outfit': _outfits[_selectedOutfit]['name'],
      'accessory': _accessories[_selectedAccessory]['name'],
      'color_hex': _colors[_selectedColor].toARGB32().toRadixString(16),
      'hair_icon_code':
          (_hairStyles[_selectedHair]['icon'] as IconData).codePoint,
    };
    authService.setCharacterCustomization(customization);

    final user = UserModel(
      userId: authService.userId!,
      displayName: authService.displayName ?? 'DreamLoop Explorer',
      authProvider: authService.authProvider ?? 'unknown',
      relationshipType: authService.relationshipType,
      characterCustomization: customization,
    );
    try {
      await _firestoreService.updateUser(user);

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save character. Try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSection(
    String title,
    List<Map<String, dynamic>> items,
    int selected,
    ValueChanged<int> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: List.generate(items.length, (index) {
            final isSelected = selected == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? DreamColors.primary.withValues(alpha: 0.2)
                        : DreamColors.backgroundCard,
                    border: Border.all(
                      color: isSelected
                          ? DreamColors.primary
                          : DreamColors.divider,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        items[index]['icon'] as IconData,
                        color: isSelected
                            ? DreamColors.primary
                            : DreamColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        items[index]['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? DreamColors.primary
                              : DreamColors.textMuted,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
