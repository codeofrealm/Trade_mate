import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/app_routes.dart';
import '../../../auth/data/auth_user_store.dart';
import '../../data/home_user_profile_service.dart';
import '../../data/models/home_user_address.dart';

class LocationSetupPage extends StatefulWidget {
  const LocationSetupPage({super.key});

  @override
  State<LocationSetupPage> createState() => _LocationSetupPageState();
}

class _LocationSetupPageState extends State<LocationSetupPage> {
  bool _isLoading = false;
  String _status = 'Allow location to detect your current address automatically.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectAndSaveLocation();
    });
  }

  Future<void> _detectAndSaveLocation() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _status = 'Checking location permission...';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const _LocationSetupException(
          'Please turn on location service and try again.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const _LocationSetupException(
          'Location permission denied. Please allow location to continue.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const _LocationSetupException(
          'Location permission is permanently denied. Open app settings and allow location.',
        );
      }

      setState(() => _status = 'Finding your exact location...');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : null;

      final existingAddress = await HomeUserProfileService.instance.loadAddress();
      final username = AuthUserStore.username?.trim().isNotEmpty == true
          ? AuthUserStore.username!.trim()
          : existingAddress.fullName;
      final phoneNumber = AuthUserStore.phoneNumber?.trim().isNotEmpty == true
          ? AuthUserStore.phoneNumber!.trim()
          : existingAddress.phone;

      final updatedAddress = HomeUserAddress(
        fullName: username,
        phone: phoneNumber,
        line1: _firstNonEmpty([
          _joinNonEmpty([
            place?.subThoroughfare,
            place?.thoroughfare,
          ]),
          place?.street,
          place?.name,
          existingAddress.line1,
        ]),
        line2: _firstNonEmpty([
          _joinNonEmpty([
            place?.subLocality,
            place?.locality,
          ]),
          place?.administrativeArea,
          existingAddress.line2,
        ]),
        city: _firstNonEmpty([
          place?.locality,
          place?.subAdministrativeArea,
          existingAddress.city,
        ]),
        state: _firstNonEmpty([
          place?.administrativeArea,
          existingAddress.state,
        ]),
        postalCode: _firstNonEmpty([
          place?.postalCode,
          existingAddress.postalCode,
        ]),
        country: _firstNonEmpty([
          place?.country,
          existingAddress.country,
          'India',
        ]),
      );

      await HomeUserProfileService.instance.saveAddressWithCoordinates(
        address: updatedAddress,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;
      setState(() => _status = 'Location saved successfully.');
      Navigator.of(context).pushReplacementNamed(AppRoutes.homeProfile);
    } on HomeProfileException catch (error) {
      if (!mounted) return;
      setState(() => _status = error.message);
    } on _LocationSetupException catch (error) {
      if (!mounted) return;
      setState(() => _status = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Unable to detect exact location right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Settings could not open here. Please allow location permission from your phone settings.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open settings right now.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Location Setup'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2FF),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF007AFF),
                      size: 42,
                    ),
                  ),
                  const Text(
                    'Allow Exact Location',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _detectAndSaveLocation,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.location_searching_rounded),
                    label: Text(_isLoading ? 'Detecting...' : 'Allow Location'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _openSettings,
                    child: const Text('Open Settings'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pushReplacementNamed(
                              AppRoutes.homeProfile,
                            ),
                    child: const Text('Skip and Enter Address'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = (value ?? '').trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _joinNonEmpty(List<String?> values) {
    final parts = values
        .map((value) => (value ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return parts.join(' ');
  }
}

class _LocationSetupException implements Exception {
  const _LocationSetupException(this.message);

  final String message;
}
