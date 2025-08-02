import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedTab = 'first';
  final _configFormKey = GlobalKey<FormState>();
  final _sequenceFormKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _transitionTimeController = TextEditingController();
  final TextEditingController _cyclesController = TextEditingController();
  final TextEditingController _colorCountController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _sequenceCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    await dbService.getActiveDevices();
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'first':
        return _buildConfigTab();
      case 'second':
        return _buildSequenceTab();
      case 'third':
        return _buildListTab();
      default:
        return const Center(child: Text('Invalid tab'));
    }
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _configFormKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('General Configuration', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _colorCountController.text.isEmpty ? null : int.parse(_colorCountController.text),
                      items: [3, 6, 9, 12].map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value colors'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _colorCountController.text = value.toString();
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Number of Colors',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _transitionTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Transition Duration (s)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter duration';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cyclesController,
                      decoration: const InputDecoration(
                        labelText: 'Cycles',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter cycles';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveConfig,
              child: const Text('Save Configuration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSequenceTab() {
    return Consumer<DatabaseService>(
      builder: (context, dbService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _sequenceFormKey,
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('User Sequence',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<User>(
                          value: null,
                          items: dbService.availableUsers.map((user) {
                            return DropdownMenuItem<User>(
                              value: user,
                              child: Text(user.username),
                            );
                          }).toList(),
                          onChanged: (user) {
                            if (user != null) {
                              _userNameController.text = user.username;
                            }
                          },
                          decoration: const InputDecoration(
                            labelText: 'Select User',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sequenceCountController,
                          decoration: const InputDecoration(
                            labelText: 'Sequence Length',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter length';
                            }
                            return null;
                          },
                        ),
                        // Dynamic color selection would go here
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveSequence,
                  child: const Text('Save Sequence'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListTab() {
    return Consumer<StorageService>(
      builder: (context, storage, child) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: storage.savedSequences.length,
                itemBuilder: (context, index) {
                  final sequence = storage.savedSequences[index];
                  return ListTile(
                    title: Text(sequence.username),
                    subtitle: Row(
                      children: sequence.colors.map((color) => Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 4),
                        color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                      )).toList(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editSequence(sequence),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSequence(sequence),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _startSequence,
                child: const Text('Start Test'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _saveConfig() {
    if (_configFormKey.currentState!.validate()) {
      // Save logic
    }
  }

  void _saveSequence() {
    if (_sequenceFormKey.currentState!.validate()) {
      // Save logic
    }
  }

  void _editSequence(UserSequence sequence) {
    setState(() {
      _selectedTab = 'second';
      // Populate form fields
    });
  }

  void _deleteSequence(UserSequence sequence) {
    // Delete logic
  }

  void _startSequence() {
    // Start test logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'first', label: Text('Config')),
              ButtonSegment(value: 'second', label: Text('Sequence')),
              ButtonSegment(value: 'third', label: Text('List')),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() => _selectedTab = newSelection.first);
            },
          ),
        ),
      ),
      body: _buildTabContent(),
    );
  }
}