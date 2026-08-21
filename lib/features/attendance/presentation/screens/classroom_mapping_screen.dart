import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trackx/features/attendance/domain/models/classroom_location_model.dart';
import 'package:trackx/shared/widgets/app_background.dart';
import 'package:trackx/shared/widgets/glass_container.dart';
import 'package:trackx/shared/widgets/glass_primary_button.dart';
import 'package:trackx/shared/widgets/glass_text_field.dart';

final classroomLocationsProvider =
    StateNotifierProvider<ClassroomLocationsNotifier, List<ClassroomLocation>>((
      ref,
    ) {
      return ClassroomLocationsNotifier();
    });

class ClassroomLocationsNotifier
    extends StateNotifier<List<ClassroomLocation>> {
  ClassroomLocationsNotifier() : super([]);

  void addLocation(ClassroomLocation location) {
    state = [...state, location];
  }

  void deleteLocation(String id) {
    state = state.where((loc) => loc.id != id).toList();
  }
}

class ClassroomMappingScreen extends ConsumerStatefulWidget {
  const ClassroomMappingScreen({super.key});

  @override
  ConsumerState<ClassroomMappingScreen> createState() =>
      _ClassroomMappingScreenState();
}

class _ClassroomMappingScreenState
    extends ConsumerState<ClassroomMappingScreen> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _radiusController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(classroomLocationsProvider);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text(
            'Classroom Geofences',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              'Add classrooms geofences. During class timings, you will receive intelligent attendance reminders when you enter the boundary.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GlassContainer(
              child: Column(
                children: [
                  GlassTextField(
                    controller: _nameController,
                    labelText: 'Classroom Name',
                    hintText: 'e.g. DBMS Lab',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          controller: _latController,
                          labelText: 'Latitude',
                          hintText: 'e.g. 12.9716',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassTextField(
                          controller: _lonController,
                          labelText: 'Longitude',
                          hintText: 'e.g. 77.5946',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    controller: _radiusController,
                    labelText: 'Radius (Meters)',
                    hintText: 'e.g. 50.0',
                  ),
                  const SizedBox(height: 16),
                  GlassPrimaryButton(
                    text: 'Add Geofence',
                    onPressed: () {
                      final name = _nameController.text.trim();
                      final lat =
                          double.tryParse(_latController.text.trim()) ?? 0.0;
                      final lon =
                          double.tryParse(_lonController.text.trim()) ?? 0.0;
                      final rad =
                          double.tryParse(_radiusController.text.trim()) ??
                          50.0;

                      if (name.isNotEmpty) {
                        final loc = ClassroomLocation(
                          id: 'loc-${DateTime.now().millisecondsSinceEpoch}',
                          userId: 'user-1',
                          semesterId: 'sem-1',
                          name: name,
                          latitude: lat,
                          longitude: lon,
                          radiusMeters: rad,
                          isEnabled: true,
                          createdAt: DateTime.now().millisecondsSinceEpoch,
                          updatedAt: DateTime.now().millisecondsSinceEpoch,
                        );

                        ref
                            .read(classroomLocationsProvider.notifier)
                            .addLocation(loc);
                        _nameController.clear();
                        _latController.clear();
                        _lonController.clear();
                        _radiusController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Active Classroom Locations',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (locations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: const Center(
                    child: Text(
                      'No classroom locations mapped yet.\nAdd a geofence above to verify attendance locations.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              ...locations.map((loc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    child: ListTile(
                      title: Text(
                        loc.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Lat: ${loc.latitude}, Lon: ${loc.longitude} | Radius: ${loc.radiusMeters}m',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          ref
                              .read(classroomLocationsProvider.notifier)
                              .deleteLocation(loc.id);
                        },
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
