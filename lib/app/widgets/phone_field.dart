import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
const List<Map<String, String>> _countries = [
  {'name': 'Bangladesh', 'code': '+880', 'flag': '🇧🇩'},
  {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
  {'name': 'Pakistan', 'code': '+92', 'flag': '🇵🇰'},
  {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
  {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
  {'name': 'Saudi Arabia', 'code': '+966', 'flag': '🇸🇦'},
  {'name': 'UAE', 'code': '+971', 'flag': '🇦🇪'},
  {'name': 'Qatar', 'code': '+974', 'flag': '🇶🇦'},
  {'name': 'Kuwait', 'code': '+965', 'flag': '🇰🇼'},
  {'name': 'Malaysia', 'code': '+60', 'flag': '🇲🇾'},
  {'name': 'Singapore', 'code': '+65', 'flag': '🇸🇬'},
  {'name': 'Australia', 'code': '+61', 'flag': '🇦🇺'},
  {'name': 'Canada', 'code': '+1', 'flag': '🇨🇦'},
  {'name': 'Germany', 'code': '+49', 'flag': '🇩🇪'},
  {'name': 'France', 'code': '+33', 'flag': '🇫🇷'},
  {'name': 'Turkey', 'code': '+90', 'flag': '🇹🇷'},
  {'name': 'Indonesia', 'code': '+62', 'flag': '🇮🇩'},
  {'name': 'China', 'code': '+86', 'flag': '🇨🇳'},
  {'name': 'Japan', 'code': '+81', 'flag': '🇯🇵'},
  {'name': 'South Korea', 'code': '+82', 'flag': '🇰🇷'},
];
class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String initialDialCode;
  final void Function(String dialCode)? onDialCodeChanged;
  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.initialDialCode = '+880',
    this.onDialCodeChanged,
  });
  static String combine(String dialCode, String number) {
    final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
    return '$dialCode$digits';
  }
  static MapEntry<String, String> parse(String fullNumber) {
    for (final c in _countries) {
      if (fullNumber.startsWith(c['code']!)) {
        return MapEntry(c['code']!, fullNumber.substring(c['code']!.length));
      }
    }
    return MapEntry('+880', fullNumber);
  }
  @override
  State<PhoneField> createState() => _PhoneFieldState();
}
class _PhoneFieldState extends State<PhoneField> {
  late Map<String, String> _selected;
  final _searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _selected = _countries.firstWhere(
      (c) => c['code'] == widget.initialDialCode,
      orElse: () => _countries.first,
    );
  }
  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  void _showPicker(BuildContext context) {
    _searchCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setModal(() {}),
                ),
              ),
              Expanded(
                child: ListView(
                  children: _countries
                      .where((c) =>
                          c['name']!.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
                          c['code']!.contains(_searchCtrl.text))
                      .map((c) => ListTile(
                            leading: Text(c['flag']!, style: const TextStyle(fontSize: 24)),
                            title: Text(c['name']!),
                            trailing: Text(c['code']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            selected: _selected['name'] == c['name'],
                            selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                            onTap: () {
                              setState(() => _selected = c);
                              widget.onDialCodeChanged?.call(c['code']!);
                              Navigator.pop(ctx);
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: 'e.g. 01712345678',
        prefixIcon: GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selected['flag']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Text(_selected['code']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
