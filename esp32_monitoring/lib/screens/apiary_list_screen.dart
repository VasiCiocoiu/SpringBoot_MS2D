import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/hierarchy_provider.dart';
import '../models/apiary.dart';
import 'hive_list_screen.dart';

class ApiaryListScreen extends StatefulWidget {
  const ApiaryListScreen({super.key});

  @override
  State<ApiaryListScreen> createState() => _ApiaryListScreenState();
}

class _ApiaryListScreenState extends State<ApiaryListScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Load apiaries when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HierarchyProvider>().loadApiaries();
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
        title: const Text('Mes Ruchers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => context.read<HierarchyProvider>().loadApiaries(),
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
                    onPressed: () => hierarchyProvider.loadApiaries(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final apiaries = hierarchyProvider.apiaries;

          if (apiaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hive,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun rucher',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commencez par créer votre premier rucher',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateApiaryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un rucher'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apiaries.length,
            itemBuilder: (context, index) {
              final apiary = apiaries[index];
              return _buildApiaryCard(context, apiary);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateApiaryDialog(context),
        tooltip: 'Ajouter un rucher',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildApiaryCard(BuildContext context, Apiary apiary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectApiary(context, apiary),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hive,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      apiary.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleApiaryAction(context, apiary, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Modifier'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (apiary.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  apiary.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (apiary.address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        apiary.address,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _selectApiary(BuildContext context, Apiary apiary) {
    // Prevent double-tap navigation
    if (_isNavigating) return;
    _isNavigating = true;

    // Get the current HierarchyProvider instance
    final hierarchyProvider = context.read<HierarchyProvider>();

    // Navigate immediately, then load data in the destination screen
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: hierarchyProvider,
          child: HiveListScreen(selectedApiary: apiary),
        ),
      ),
    )
        .then((_) {
      // Reset navigation flag when returning
      if (mounted) {
        _isNavigating = false;
      }
    });
  }

  void _handleApiaryAction(BuildContext context, Apiary apiary, String action) {
    switch (action) {
      case 'edit':
        _showEditApiaryDialog(context, apiary);
        break;
      case 'delete':
        _showDeleteConfirmation(context, apiary);
        break;
    }
  }

  void _showCreateApiaryDialog(BuildContext context) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: hierarchyProvider,
        child: const ApiaryFormDialog(),
      ),
    );
  }

  void _showEditApiaryDialog(BuildContext context, Apiary apiary) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: hierarchyProvider,
        child: ApiaryFormDialog(apiary: apiary),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Apiary apiary) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le rucher'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le rucher "${apiary.name}" ?\n\n'
          'Cette action supprimera également toutes les ruches et leurs données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              hierarchyProvider.deleteApiary(apiary.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class ApiaryFormDialog extends StatefulWidget {
  final Apiary? apiary;

  const ApiaryFormDialog({super.key, this.apiary});

  @override
  State<ApiaryFormDialog> createState() => _ApiaryFormDialogState();
}

class _ApiaryFormDialogState extends State<ApiaryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.apiary?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.apiary?.description ?? '');
    _addressController =
        TextEditingController(text: widget.apiary?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.apiary != null;

    return AlertDialog(
      title: Text(isEditing ? 'Modifier le rucher' : 'Nouveau rucher'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom du rucher *',
                hintText: 'Mon rucher principal',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est requis';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description de votre rucher...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                hintText: '123 Rue de la Ruche, Ville',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveApiary,
          child: Text(isEditing ? 'Modifier' : 'Créer'),
        ),
      ],
    );
  }

  void _saveApiary() {
    if (!_formKey.currentState!.validate()) return;

    final hierarchyProvider = context.read<HierarchyProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();

    if (widget.apiary != null) {
      // Edit existing apiary
      final updatedApiary = widget.apiary!.copyWith(
        name: name,
        description: description,
        address: address,
        updatedAt: DateTime.now(),
      );
      hierarchyProvider.updateApiary(updatedApiary);
    } else {
      // Create new apiary
      final newApiary = Apiary(
        id: name, // Use name as ID in Firebase structure
        name: name,
        userId: hierarchyProvider.context.userId,
        description: description,
        address: address,
        createdAt: DateTime.now(),
      );
      hierarchyProvider.createApiary(newApiary);
    }

    Navigator.of(context).pop();
  }
}
