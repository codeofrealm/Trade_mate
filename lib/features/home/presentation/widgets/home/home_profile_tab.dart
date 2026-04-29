import 'package:flutter/material.dart';

import '../../../data/home_user_profile_service.dart';
import '../../../data/models/home_user_address.dart';
import '../profile/home_profile_widgets.dart';
import 'home_tab_scaffold.dart';

class HomeProfileTab extends StatefulWidget {
  const HomeProfileTab({super.key, required this.name, required this.onLogout});

  final String name;
  final VoidCallback onLogout;

  @override
  State<HomeProfileTab> createState() => _HomeProfileTabState();
}

class _HomeProfileTabState extends State<HomeProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController(text: 'India');

  HomeUserAddress _savedAddress = HomeUserAddress.empty;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingAddress = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    try {
      final address = await HomeUserProfileService.instance.loadAddress();
      if (!mounted) return;
      _applyAddress(address);
      setState(() {
        _savedAddress = address;
        _isEditingAddress = !address.isComplete;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyAddress(HomeUserAddress address) {
    _fullNameController.text = address.fullName;
    _phoneController.text = address.phone;
    _line1Controller.text = address.line1;
    _line2Controller.text = address.line2;
    _cityController.text = address.city;
    _stateController.text = address.state;
    _postalCodeController.text = address.postalCode;
    _countryController.text = address.country.isEmpty ? 'India' : address.country;
  }

  Future<void> _saveAddress() async {
    if (!_isEditingAddress || _isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final address = HomeUserAddress(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
      );
      await HomeUserProfileService.instance.saveAddress(address);
      if (!mounted) return;
      setState(() {
        _savedAddress = address;
        _isEditingAddress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully.')),
      );
    } on HomeProfileException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _startEditAddress() {
    if (_isSaving) return;
    setState(() => _isEditingAddress = true);
  }

  void _cancelEditAddress() {
    if (_isSaving || !_savedAddress.isComplete) return;
    _applyAddress(_savedAddress);
    FocusScope.of(context).unfocus();
    setState(() => _isEditingAddress = false);
  }

  @override
  Widget build(BuildContext context) {
    return HomeTabScaffold(
      title: 'Profile',
      subtitle: 'Save full address once, then edit only when needed',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7EBF2)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE7EBF2),
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'T',
                    style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(
                              color: Color(0xFF1A1D26),
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      const Text('Please complete full address for ordering',
                          style: TextStyle(
                              color: Color(0xFF6D7587), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7EBF2)),
                  ),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : Column(
                  children: [
                    if (!_isEditingAddress)
                      HomeSavedAddressCard(
                        address: _savedAddress,
                        onAddOrEdit: _startEditAddress,
                      )
                    else
                      HomeAddressFormCard(
                        formKey: _formKey,
                        isSaving: _isSaving,
                        savedAddress: _savedAddress,
                        onCancel: _cancelEditAddress,
                        onSave: _saveAddress,
                        fullNameController: _fullNameController,
                        phoneController: _phoneController,
                        line1Controller: _line1Controller,
                        line2Controller: _line2Controller,
                        cityController: _cityController,
                        stateController: _stateController,
                        postalCodeController: _postalCodeController,
                        countryController: _countryController,
                        requiredValidator: _required,
                        phoneValidator: _phoneValidator,
                        postalCodeValidator: _postalCodeValidator,
                      ),
                  ],
                ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1D26),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required.';
    return null;
  }

  String? _phoneValidator(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'This field is required.';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) return 'Enter valid phone number.';
    return null;
  }

  String? _postalCodeValidator(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'This field is required.';
    if (!RegExp(r'^\d{6}$').hasMatch(raw)) return 'Enter valid 6-digit PIN code.';
    return null;
  }
}
