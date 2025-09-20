import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/hierarchy_provider.dart';
import '../models/hive.dart';
import '../models/apiary.dart';
import '../auth/home_screen.dart';

class HiveListScreen extends StatefulWidget {
  final Apiary? selectedApiary;

  const HiveListScreen({super.key, this.selectedApiary});

  @override
  State<HiveListScreen> createState() => _HiveListScreenState();
}

class _HiveListScreenState extends State<HiveListScreen> {
  @override
  void initState() {
    super.initState();
    // Load apiary and hives when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.selectedApiary != null) {
        final hierarchyProvider = context.read<HierarchyProvider>();
        hierarchyProvider.selectApiary(widget.selectedApiary!).then((_) {
          // Data loading is handled in selectApiary method
        });
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Clear the hierarchy provider state
    if (mounted) {
      final hierarchyProvider = context.read<HierarchyProvider>();
      hierarchyProvider.clearSelection();

      // Navigate to login and clear all navigation history
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/', // This will go back to the AuthWrapper which will show LoginScreen
        (route) => false, // Remove all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<HierarchyProvider>(
          builder: (context, hierarchyProvider, child) {
            final apiaryName =
                hierarchyProvider.selectedApiary?.name ?? 'Rucher';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ruches', style: TextStyle(fontSize: 20)),
                Text(
                  apiaryName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => context.read<HierarchyProvider>().loadHives(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      body: Consumer<HierarchyProvider>(
        builder: (context, hierarchyProvider, child) {
          if (hierarchyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hierarchyProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hierarchyProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => hierarchyProvider.loadHives(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final hives = hierarchyProvider.hives;

          if (hives.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune ruche',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez votre première ruche dans ce rucher',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateHiveDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ruche'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hives.length,
            itemBuilder: (context, index) {
              final hive = hives[index];
              return _buildHiveCard(context, hive);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateHiveDialog(context),
        tooltip: 'Ajouter une ruche',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHiveCard(BuildContext context, Hive hive) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectHive(context, hive),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hive.name,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Supprimer la ruche',
                    onPressed: () => _showDeleteConfirmation(context, hive),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _selectHive(BuildContext context, Hive hive) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    hierarchyProvider.selectHive(hive);

    // Check if widget is still mounted before navigation
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider.value(
            value: hierarchyProvider,
            child: const HomeScreen(),
          ),
        ),
      );
    }
  }

  void _showCreateHiveDialog(BuildContext context) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: hierarchyProvider,
        child: const HiveFormDialog(),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Hive hive) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la ruche'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la ruche "${hive.name}" ?\n\n'
          'Cette action supprimera toutes les données de mesure associées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              hierarchyProvider.deleteHive(hive.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class HiveFormDialog extends StatefulWidget {
  final Hive? hive;

  const HiveFormDialog({super.key, this.hive});

  @override
  State<HiveFormDialog> createState() => _HiveFormDialogState();
}

class _HiveFormDialogState extends State<HiveFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _humidityController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _intervalController;
  bool _notifyEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.hive?.name ?? '');
    // Initialize with sensible defaults
    _humidityController = TextEditingController(text: '80.0');
    _temperatureController = TextEditingController(text: '30.0');
    _intervalController =
        TextEditingController(text: '60000'); // 60 seconds in ms
  }

  @override
  void dispose() {
    _nameController.dispose();
    _humidityController.dispose();
    _temperatureController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.hive != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier la ruche' : 'Nouvelle ruche'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la ruche *',
                  hintText: 'Ruche 01',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Configuration des seuils',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _humidityController,
                decoration: const InputDecoration(
                  labelText: 'Seuil d\'humidité *',
                  hintText: '80.0',
                  suffixText: '%',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le seuil d\'humidité est requis';
                  }
                  final humidity = double.tryParse(value);
                  if (humidity == null || humidity < 0 || humidity > 100) {
                    return 'Valeur entre 0 et 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _temperatureController,
                decoration: const InputDecoration(
                  labelText: 'Seuil de température *',
                  hintText: '30.0',
                  suffixText: '°C',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le seuil de température est requis';
                  }
                  final temperature = double.tryParse(value);
                  if (temperature == null ||
                      temperature < -50 ||
                      temperature > 100) {
                    return 'Valeur entre -50 et 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intervalController,
                decoration: const InputDecoration(
                  labelText: 'Intervalle de mesure *',
                  hintText: '60000',
                  suffixText: 'ms',
                  helperText: '60000ms = 1 minute',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'intervalle est requis';
                  }
                  final interval = int.tryParse(value);
                  if (interval == null || interval < 1000) {
                    return 'Minimum 1000ms (1 seconde)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Notifications activées'),
                subtitle: const Text(
                    'Recevoir des alertes lors de l\'ouverture de la ruche'),
                value: _notifyEnabled,
                onChanged: (value) {
                  setState(() {
                    _notifyEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveHive,
          child: Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  void _saveHive() {
    if (!_formKey.currentState!.validate()) return;

    final hierarchyProvider = context.read<HierarchyProvider>();
    final name = _nameController.text.trim();

    if (widget.hive != null) {
      // Edit existing hive (future implementation)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modification non implémentée')),
      );
    } else {
      // Create new hive with constants
      final newHive = Hive(
        id: name, // Use name as ID in Firebase structure
        name: name,
        apiaryId: hierarchyProvider.context.selectedApiaryId!,
        userId: hierarchyProvider.context.userId,
        createdAt: DateTime.now(),
      );

      // Parse the constants from form
      final constants = {
        'humidity': double.parse(_humidityController.text),
        'temperature': double.parse(_temperatureController.text),
        'notify': _notifyEnabled,
        'interval': int.parse(_intervalController.text),
      };

      hierarchyProvider.createHiveWithConstants(newHive, constants);
    }

    Navigator.of(context).pop();
  }
}
