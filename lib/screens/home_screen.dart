import 'package:flutter/material.dart';
import 'package:myfrontflutter/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:myfrontflutter/services/database_service.dart';
import 'package:myfrontflutter/services/storage_service.dart';
import 'counter_screen.dart'; // Nueva importación
import 'video_iist_screen.dart'; // Nueva importación para videos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Agrega al inicio del state
  User? _selectedUser;
  //List<User> _listUsers = [];
  String _selectedTab = 'first';
  bool _isConfigSaved = false;
  bool _isColorInputsReadonly = false;
  List<dynamic> _usersSequences = [];
  List<dynamic> _listUsers = [];
  List<dynamic> _colorOptions = [];
  final _formKey = GlobalKey<FormState>();
  final _sequenceFormKey = GlobalKey<FormState>();
  int _selectNumber = 0;
  int _counterSequence = 0;
  late DatabaseService _databaseService;
  late StorageService _storageService;
  final TextEditingController _transitionTimeController = TextEditingController();
  final TextEditingController _cyclesController = TextEditingController();
  final TextEditingController _selectedUserNameController = TextEditingController();
  final TextEditingController _idDeviceController = TextEditingController();
  final List<TextEditingController> _colorControllers = [];
  final List<TextEditingController> _sequenceControllers = [];
  bool _isEditingExisting = false;
  final TextEditingController _videoDurationController = TextEditingController();

  // Keys para SharedPreferences
  static const String _configKey = 'app_config';
  static const String _sequencesKey = 'user_sequences';

  @override
  void initState() {
    super.initState();
    _selectedUserNameController.text = "usuarios";
    _idDeviceController.text = "0";
    _loadInitialData();

    // Carga usuarios al iniciar si lo deseas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConnectedUsers();
    });
  }

  @override
  void dispose() {
    _selectedUserNameController.dispose();
    _idDeviceController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseService = Provider.of<DatabaseService>(context);
    _storageService = Provider.of<StorageService>(context);
  }

  Future<void> _loadConnectedUsers() async {
    try {
      // 1. Get active devices from database
      await _databaseService.getActiveDevices();

      // 2. Get current saved sequences
      final savedSequences = await _storageService.getSequences();
      final sequenceUserIds = savedSequences.map((s) => s['iduser']).toList();

      // 3. Filter and update user list
      setState(() {
        _listUsers = _databaseService.availableUsers.where((user) {
          // Only include users not in sequences
          return !sequenceUserIds.contains(user.id);
        }).toList();
      });

      if (_listUsers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay nuevos usuarios conectados'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ${e.toString()}'))
      );
    }
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar configuración
    final configJson = prefs.getString(_configKey);
    if (configJson != null) {
      final config = json.decode(configJson) as Map<String, dynamic>;
      setState(() {
        _isConfigSaved = true;
        _colorOptions = (config['color'] as List).cast<Map<String, dynamic>>();

        // Llenar los campos del formulario
        _transitionTimeController.text = config['transitionTime']?.toString() ?? '';
        _cyclesController.text = config['cicles']?.toString() ?? '';
        _videoDurationController.text = config['videoDuration']?.toString() ?? ''; // New line
        // Configurar los inputs dinámicos de colores
        _selectNumber = _colorOptions.length;
        _colorControllers.clear();
        for (var colorObj in _colorOptions) {
          _colorControllers.add(TextEditingController(text: colorObj['color']));
        }
      });
    }

    // Cargar secuencias (mantén tu código existente)
    final sequencesJson = prefs.getString(_sequencesKey);
    if (sequencesJson != null) {
      setState(() {
        _usersSequences = (json.decode(sequencesJson) as List).cast<Map<String, dynamic>>();
        if (_usersSequences.isNotEmpty) {
          _isColorInputsReadonly = true;
        }
      });
    }
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'first': return _buildConfigTab();
      case 'second': return _buildSequenceTab();
      case 'third': return _buildListTab();
      default: return const Center(child: Text('Invalid tab'));
    }
  }

  Widget _buildConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Configuración general',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: _selectNumber == 0 ? null : _selectNumber,
                      items: [3, 6, 9, 12].map((value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value colores'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && !_isColorInputsReadonly) {
                          setState(() {
                            _selectNumber = value;
                            // Solo limpia si no hay datos cargados
                            if (_colorControllers.length != value) {
                              _colorControllers.clear();
                              for (int i = 0; i < value; i++) {
                                _colorControllers.add(
                                    TextEditingController(
                                        text: i < _colorOptions.length
                                            ? _colorOptions[i]['color']
                                            : ''
                                    )
                                );
                              }
                            }
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Cantidad de colores',
                        border: OutlineInputBorder(),
                      ),
                    ),


                    ..._buildColorInputs(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _transitionTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Duración de transiciones (s)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoDurationController,
                      decoration: const InputDecoration(
                        labelText: 'Duración de video (s)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Duración requerida';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Duración inválida';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cyclesController,
                      decoration: const InputDecoration(
                        labelText: 'Ciclos',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
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
              child: const Text('Guardar Configuración'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildColorInputs() {
    return List.generate(_colorControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: _colorControllers[index],
          decoration: InputDecoration(
            labelText: 'Color #${index + 1}',
            border: const OutlineInputBorder(),
          ),
          readOnly: _isColorInputsReadonly,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Color requerido';
            }
            return null;
          },
        ),
      );
    });
  }

  Widget _buildSequenceTab() {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                            'Usuario-secuencia',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: _databaseService.isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          onPressed: _databaseService.isLoading ? null : () {
                            _loadConnectedUsers(); // Your existing load function
                            _resetSequenceForm();  // Reset the form
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // User selection dropdown only (removed duplicate display)
                    DropdownButtonFormField<User>(
                      value: _selectedUser,
                      hint: const Text('Seleccione usuario'),
                      items: _listUsers.map((user) {
                        return DropdownMenuItem<User>(
                          value: user,
                          child: Text(user.username),
                        );
                      }).toList(),
                      onChanged: (user) {
                        if (user != null) {
                          setState(() {
                            _selectedUser = user;
                            _selectedUserNameController.text = user.username;
                            _idDeviceController.text = user.deviceId;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Usuarios conectados',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Seleccione un usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),


                    // Number of colors in sequence (numeric input)
                    TextFormField(
                      controller: TextEditingController(
                        text: _counterSequence == 0 ? '' : _counterSequence.toString(),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'N° colores en secuencia',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final intValue = int.tryParse(value) ?? 0;
                        //if (intValue > 0 && intValue <= _colorOptions.length) {
                        if (intValue > 0 && intValue <= 1000 ) {
                          _updateSequenceCount(intValue);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un número';
                        }
                        final intValue = int.tryParse(value) ?? 0;
                        if (intValue <= 0) {
                          return 'Debe ser mayor a 0';
                        }
                        /*if (_colorOptions.isNotEmpty && intValue > _colorOptions.length) {
                          return 'Máximo ${_colorOptions.length} colores';
                        }*/
                        return null;
                      },
                    ),


                    // Dynamic sequence inputs
                    if (_colorOptions.isNotEmpty) ..._buildSequenceInputs(),
                    if (_colorOptions.isEmpty)
                      const Text(
                        'Configure los colores en la pestaña Config primero',
                        style: TextStyle(color: Colors.red),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSequence,
              child: const Text('Guardar Secuencia'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSequenceCount(int newCount) {
    setState(() {
      _counterSequence = newCount;

      // Clear existing controllers if count decreased
      if (_sequenceControllers.length > newCount) {
        _sequenceControllers.removeRange(newCount, _sequenceControllers.length);
      }
      // Add new controllers if count increased
      else if (_sequenceControllers.length < newCount) {
        for (int i = _sequenceControllers.length; i < newCount; i++) {
          _sequenceControllers.add(TextEditingController());
        }
      }

      // Preserve existing values when count changes
      if (_usersSequences.isNotEmpty && _selectedUser != null) {
        final userSequence = _usersSequences.firstWhere(
              (seq) => seq['iduser'] == _selectedUser!.id,
          orElse: () => {'sequence': []},
        );

        for (int i = 0; i < _sequenceControllers.length; i++) {
          if (i < userSequence['sequence'].length) {
            _sequenceControllers[i].text = userSequence['sequence'][i]['color'];
          }
        }
      }
    });
  }

  List<Widget> _buildSequenceInputs() {
    return List.generate(_sequenceControllers.length, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: DropdownButtonFormField<String>(
          value: _sequenceControllers[index].text.isEmpty ? null : _sequenceControllers[index].text,
          items: _colorOptions.map((color) {
            return DropdownMenuItem<String>(
              value: color['color'],
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Color(int.parse(color['color'].replaceAll('#', '0xFF'))),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  Text(color['color']),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sequenceControllers[index].text = value;
              });
            }
          },
          decoration: InputDecoration(
            labelText: 'Secuencia #${index + 1}',
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Seleccione un color';
            }
            return null;
          },
        ),
      );
    });
  }

  Widget _buildListTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _usersSequences.length,
            itemBuilder: (context, index) {
              final user = _usersSequences[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(user['username']),
                      ),
                      Expanded(
                        flex: 4,
                        child: Wrap(
                          spacing: 4,
                          children: user['sequence'].map<Widget>((color) {
                            return Container(
                              width: 12,
                              height: 12,
                              color: Color(int.parse(color['color'].replaceAll('#', '0xFF'))),
                            );
                          }).toList(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editUser(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteUser(user),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _startSequence,
            child: const Text('Inicio Test'),
          ),
        ),
      ],
    );
  }

  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Menú de Navegación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.blue),
                title: const Text('Inicio'),
                subtitle: const Text('Volver a la pantalla principal'),
                onTap: () {
                  Navigator.of(context).pop(); // Cerrar el modal
                  // Ya estamos en Home, no necesitamos navegar
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.green),
                title: const Text('Videos Guardados'),
                subtitle: const Text('Ver todos los videos grabados'),
                onTap: () {
                  Navigator.of(context).pop(); // Cerrar el modal
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const VideoListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
  void _startSequence() {
    if (_usersSequences.isNotEmpty) {
      // Crear configuración para la grabación
      final recordingConfig = {
        'date': DateTime.now().toString(),
        'cycles': _cyclesController.text,
        'transitionTime': _transitionTimeController.text,
        'videoDuration': _videoDurationController.text,
        'usersSequences': _usersSequences,
      };

      // Navegar a la pantalla de contador
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CounterScreen(
            recordingConfig: recordingConfig,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay usuarios para enviar secuencia")),
      );
    }
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final output = {
        'transitionTime': _transitionTimeController.text,
        'videoDuration': _videoDurationController.text, // New field
        'cicles': _cyclesController.text,

        'color': List<Map<String, dynamic>>.generate(
          _colorControllers.length,
              (index) => {
            'order': index + 1,
            'color': _colorControllers[index].text,
          },
        ),
      };

      await _storageService.saveConfig(output);

      setState(() {
        _isConfigSaved = true;
        _colorOptions = (output['color'] as List).cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveSequence() async {
    if (_sequenceFormKey.currentState!.validate()) {
      final output = {
        'iduser': _selectedUser?.id ?? '',
        'username': _selectedUserNameController.text,
        'iddevice': _idDeviceController.text,
        'sequence': List.generate(_sequenceControllers.length, (index) {
          return {
            'order': index + 1,
            'color': _sequenceControllers[index].text,
          };
        }),
      };

      // Remove existing sequence if editing
      _usersSequences.removeWhere((seq) => seq['iduser'] == output['iduser']);

      // Add new sequence
      _usersSequences.add(output);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sequencesKey, json.encode(_usersSequences));

      setState(() {
        // Remove user from available list if it exists
        if (_selectedUser != null) {
          _listUsers.removeWhere((user) => user.id == _selectedUser!.id);
        }

        _resetSequenceForm();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Secuencia guardada')),
      );
    }
  }

  void _resetSequenceForm() {
    _sequenceFormKey.currentState?.reset();
    _selectedUser = null;
    _counterSequence = 0;
    _sequenceControllers.clear();
    _isEditingExisting = false;
  }

  void _editUser(Map<String, dynamic> user) {
    // 1. Add user back to available list if not present
    if (!_listUsers.any((u) => u.id == user['iduser'])) {
      _listUsers.add(User(
        id: user['iduser'],
        username: user['username'],
        deviceId: user['iddevice'],
      ));
    }

    // 2. Remove from sequences list and save immediately
    setState(() {
      _usersSequences.removeWhere((seq) => seq['iduser'] == user['iduser']);
    });

    // Save the updated sequences list by:
    // 1. Clearing existing sequences
    // 2. Re-saving all remaining sequences one by one
    _saveAllSequences();

    // 3. Switch to sequence tab and populate form
    setState(() {
      _selectedTab = 'second';
      _selectedUser = _listUsers.firstWhere(
            (u) => u.id == user['iduser'],
      );

      _selectedUserNameController.text = user['username'];
      _idDeviceController.text = user['iddevice'];
      _counterSequence = user['sequence'].length;

      _sequenceControllers.clear();
      for (final color in user['sequence']) {
        _sequenceControllers.add(TextEditingController(text: color['color']));
      }
    });
  }

  Future<void> _saveAllSequences() async {
    // Clear all existing sequences first
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sequencesKey);

    // Save each sequence individually
    for (final sequence in _usersSequences) {
      await _storageService.saveSequence(sequence);
    }
  }


  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedSequences = _usersSequences.where((u) => u['iduser'] != user['iduser']).toList();
    await prefs.setString(_sequencesKey, json.encode(updatedSequences));

    setState(() {
      _usersSequences = updatedSequences;

      // Add user back to available list if not already there
      if (!_listUsers.any((u) => u.id == user['iduser'])) {
        _listUsers.add(User(
          id: user['iduser'],
          username: user['username'],
          deviceId: user['iddevice'],
        ));
      }

      if (_usersSequences.isEmpty) {
        _isColorInputsReadonly = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _showMenuOptions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SegmentedButton<String>(
            segments: [
              const ButtonSegment(value: 'first', label: Text('Config')),
              ButtonSegment(
                value: 'second',
                label: const Text('Secuen.'),
                enabled: _isConfigSaved,
              ),
              ButtonSegment(
                value: 'third',
                label: const Text('Lista'),
                enabled: _isConfigSaved,
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (Set<String> newSelection) {
              if (_isConfigSaved || newSelection.first == 'first') {
                setState(() => _selectedTab = newSelection.first);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guarda la configuración primero')),
                );
              }
            },
          ),
        ),
      ),
      body: _buildTabContent(),
    );
  }
}