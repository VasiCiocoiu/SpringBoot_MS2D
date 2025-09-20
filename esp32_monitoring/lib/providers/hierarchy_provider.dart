import 'package:flutter/foundation.dart';
import '../models/hierarchy_context.dart';
import '../models/apiary.dart';
import '../models/hive.dart';
import '../services/firebase_service.dart';

class HierarchyProvider extends ChangeNotifier {
  final FirebaseService _firebaseService;

  HierarchyContext _context;
  List<Apiary> _apiaries = [];
  List<Hive> _hives = [];
  bool _isLoading = false;
  String? _error;

  HierarchyProvider(
      {required String userId, required FirebaseService firebaseService})
      : _firebaseService = firebaseService,
        _context = HierarchyContext(userId: userId);

  // Getters
  HierarchyContext get context => _context;
  List<Apiary> get apiaries => _apiaries;
  List<Hive> get hives => _hives;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasSelectedApiary => _context.hasSelectedApiary;
  bool get hasSelectedHive => _context.hasSelectedHive;
  bool get isComplete => _context.isComplete;

  Apiary? get selectedApiary => _context.selectedApiary;
  Hive? get selectedHive => _context.selectedHive;

  // Navigation helpers
  bool get canNavigateToHives => hasSelectedApiary;
  bool get canNavigateToMeasurements => isComplete;

  /// Loads all apiaries for the current user
  Future<void> loadApiaries() async {
    _setLoading(true);
    _clearError();

    try {
      _apiaries = await _firebaseService.fetchUserApiaries();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load apiaries: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads all hives for the currently selected apiary
  Future<void> loadHives() async {
    if (!hasSelectedApiary) {
      _setError('No apiary selected');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _hives =
          await _firebaseService.fetchApiaryHives(_context.selectedApiaryId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load hives: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Selects an apiary and loads its hives
  Future<void> selectApiary(Apiary apiary) async {
    _context = _context.selectApiary(apiary);
    _hives.clear(); // Clear previous hives
    notifyListeners();

    // Automatically load hives for the selected apiary
    await loadHives();
  }

  /// Selects a hive
  void selectHive(Hive hive) {
    _context = _context.selectHive(hive);
    notifyListeners();
  }

  /// Clears all selections and returns to apiary list
  void clearSelection() {
    _context = _context.clearSelection();
    _hives.clear();
    _clearError();
    notifyListeners();
  }

  /// Clears hive selection and returns to hive list
  void clearHiveSelection() {
    _context = _context.clearHiveSelection();
    _clearError();
    notifyListeners();
  }

  /// Refreshes the current view based on current context
  Future<void> refresh() async {
    if (!hasSelectedApiary) {
      await loadApiaries();
    } else if (!hasSelectedHive) {
      await loadHives();
    }
    // If complete context, the calling screen should handle measurement refresh
  }

  /// Creates a new apiary
  Future<void> createApiary(Apiary apiary) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.createApiary(apiary);
      await loadApiaries(); // Refresh the list
    } catch (e) {
      _setError('Failed to create apiary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing apiary
  Future<void> updateApiary(Apiary apiary) async {
    _setLoading(true);
    _clearError();

    try {
      final oldApiaryId = apiary.id;
      final newApiaryId = apiary.name; // New ID is the new name

      await _firebaseService.updateApiary(apiary);

      // If the currently selected apiary was updated and its ID changed, update the context
      if (_context.selectedApiaryId == oldApiaryId &&
          oldApiaryId != newApiaryId) {
        // Update the context with the new apiary ID
        final updatedApiary = apiary.copyWith(id: newApiaryId);
        _context = _context.selectApiary(updatedApiary);
      }

      await loadApiaries(); // Refresh the list
    } catch (e) {
      _setError('Failed to update apiary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes an apiary
  Future<void> deleteApiary(String apiaryId) async {
    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.deleteApiary(apiaryId);

      // If we deleted the currently selected apiary, clear selection
      if (_context.selectedApiaryId == apiaryId) {
        clearSelection();
      }

      await loadApiaries(); // Refresh the list
    } catch (e) {
      _setError('Failed to delete apiary: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new hive in the current apiary
  Future<void> createHive(Hive hive) async {
    if (!hasSelectedApiary) {
      _setError('No apiary selected');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.createHive(_context.selectedApiaryId!, hive);
      await loadHives(); // Refresh the list
    } catch (e) {
      _setError('Failed to create hive: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new hive with custom constants in the current apiary
  Future<void> createHiveWithConstants(
      Hive hive, Map<String, dynamic> constants) async {
    if (!hasSelectedApiary) {
      _setError('No apiary selected');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.createHiveWithConstants(
          _context.selectedApiaryId!, hive, constants);
      await loadHives(); // Refresh the list
    } catch (e) {
      _setError('Failed to create hive: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a hive
  Future<void> deleteHive(String hiveId) async {
    if (!hasSelectedApiary) {
      _setError('No apiary selected');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _firebaseService.deleteHive(_context.selectedApiaryId!, hiveId);

      // If we deleted the currently selected hive, clear hive selection
      if (_context.selectedHiveId == hiveId) {
        clearHiveSelection();
      }

      await loadHives(); // Refresh the list
    } catch (e) {
      _setError('Failed to delete hive: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
}
