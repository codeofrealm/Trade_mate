import 'package:flutter/material.dart';
import '../../../data/models/home_user_address.dart';

class HomeSavedAddressCard extends StatelessWidget {
  const HomeSavedAddressCard(
      {super.key, required this.address, required this.onAddOrEdit});
  final HomeUserAddress address;
  final VoidCallback onAddOrEdit;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.isComplete;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF0F172A)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Delivery Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              ),
              FilledButton.tonalIcon(
                onPressed: onAddOrEdit,
                icon: Icon(hasAddress ? Icons.edit_outlined : Icons.add_location_alt),
                label: Text(hasAddress ? 'Edit' : 'Add Location'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasAddress)
            const Text(
              'No address saved yet. Tap "Add Location" to enter full details.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeAddressLine(icon: Icons.person_outline, label: 'Name', value: address.fullName),
                const SizedBox(height: 8),
                HomeAddressLine(icon: Icons.phone_outlined, label: 'Phone', value: address.phone),
                const SizedBox(height: 8),
                HomeAddressLine(
                  icon: Icons.home_outlined,
                  label: 'Address',
                  value: '${address.line1}${address.line2.trim().isEmpty ? '' : ', ${address.line2}'}',
                ),
                const SizedBox(height: 8),
                HomeAddressLine(
                  icon: Icons.location_city_outlined,
                  label: 'City/State',
                  value: '${address.city}, ${address.state} - ${address.postalCode}',
                ),
                const SizedBox(height: 8),
                HomeAddressLine(icon: Icons.public_outlined, label: 'Country', value: address.country),
              ],
            ),
        ],
      ),
    );
  }
}

class HomeAddressLine extends StatelessWidget {
  const HomeAddressLine(
      {super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class HomeAddressFormCard extends StatelessWidget {
  const HomeAddressFormCard({
    super.key,
    required this.formKey,
    required this.isSaving,
    required this.savedAddress,
    required this.onCancel,
    required this.onSave,
    required this.fullNameController,
    required this.phoneController,
    required this.line1Controller,
    required this.line2Controller,
    required this.cityController,
    required this.stateController,
    required this.postalCodeController,
    required this.countryController,
    required this.requiredValidator,
    required this.phoneValidator,
    required this.postalCodeValidator,
  });

  final GlobalKey<FormState> formKey;
  final bool isSaving;
  final HomeUserAddress savedAddress;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final TextEditingController line1Controller;
  final TextEditingController line2Controller;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController postalCodeController;
  final TextEditingController countryController;
  final String? Function(String?) requiredValidator;
  final String? Function(String?) phoneValidator;
  final String? Function(String?) postalCodeValidator;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.add_location_alt_outlined, color: Color(0xFF0F172A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Add Location Details',
                      style: TextStyle(
                          color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: phoneValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: line1Controller,
              decoration: const InputDecoration(labelText: 'Address Line 1'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: line2Controller,
              decoration:
                  const InputDecoration(labelText: 'Address Line 2 (optional)'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'City'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: stateController,
              decoration: const InputDecoration(labelText: 'State'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: postalCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'PIN / Postal Code'),
              validator: postalCodeValidator,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: countryController,
              decoration: const InputDecoration(labelText: 'Country'),
              validator: requiredValidator,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (savedAddress.isComplete) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSaving ? null : onCancel,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isSaving ? null : onSave,
                    icon: isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(savedAddress.isComplete
                        ? 'Save Changes'
                        : 'Save Address'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
