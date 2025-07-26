import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/settings_service.dart';
import '../../services/llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/connectivity_service.dart';

/// Settings screen for configuring the application
/// Allows users to modify Ollama connection, speech settings, and other preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ollamaUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsService = context.read<SettingsService>();
      _ollamaUrlController.text = settingsService.ollamaUrl ?? '';
    });
  }

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: () => _showResetDialog(),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Connection Settings
            _buildSectionCard(
              title: 'Connection Settings',
              icon: Icons.cloud,
              children: [
                _buildOllamaUrlField(),
                const SizedBox(height: 16),
                _buildConnectionTestButton(),
                const SizedBox(height: 16),
                _buildModelSelector(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // LLM Settings
            _buildSectionCard(
              title: 'AI Model Settings',
              icon: Icons.psychology,
              children: [
                _buildTemperatureSlider(),
                const SizedBox(height: 16),
                _buildTopPSlider(),
                const SizedBox(height: 16),
                _buildTopKSlider(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Speech Settings
            _buildSectionCard(
              title: 'Speech Settings',
              icon: Icons.mic,
              children: [
                _buildSpeechEnabledSwitch(),
                const SizedBox(height: 16),
                _buildAutoSpeechSwitch(),
                const SizedBox(height: 16),
                _buildSpeechLanguageSelector(),
                const SizedBox(height: 16),
                _buildMicrophonePermissionStatus(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // App Settings
            _buildSectionCard(
              title: 'App Settings',
              icon: Icons.settings,
              children: [
                _buildDarkModeSwitch(),
                const SizedBox(height: 16),
                _buildOfflineModeSwitch(),
                const SizedBox(height: 16),
                _buildLoggingLevelSelector(),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Connection Status
            _buildConnectionStatus(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOllamaUrlField() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return TextFormField(
          controller: _ollamaUrlController,
          decoration: const InputDecoration(
            labelText: 'Ollama Server URL',
            hintText: 'http://100.64.0.1:11434',
            helperText: 'Enter your Tailscale IP or server address',
            prefixIcon: Icon(Icons.link),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a URL';
            }
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'Please enter a valid URL';
            }
            return null;
          },
          onChanged: (value) {
            if (_formKey.currentState?.validate() == true) {
              settingsService.setOllamaUrl(value);
            }
          },
        );
      },
    );
  }

  Widget _buildConnectionTestButton() {
    return Consumer2<SettingsService, LLMService>(
      builder: (context, settingsService, llmService, child) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isTestingConnection ? null : () => _testConnection(),
            icon: _isTestingConnection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find),
            label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
          ),
        );
      },
    );
  }

  Widget _buildModelSelector() {
    return Consumer<LLMService>(
      builder: (context, llmService, child) {
        if (llmService.availableModels.isEmpty) {
          return const ListTile(
            leading: Icon(Icons.info),
            title: Text('No models available'),
            subtitle: Text('Connect to Ollama to see available models'),
          );
        }

        return DropdownButtonFormField<String>(
          value: llmService.currentModel,
          decoration: const InputDecoration(
            labelText: 'AI Model',
            prefixIcon: Icon(Icons.psychology),
          ),
          items: llmService.availableModels
              .map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              llmService.setCurrentModel(value);
            }
          },
        );
      },
    );
  }

  Widget _buildTemperatureSlider() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Temperature (Creativity)'),
                Text(settingsService.temperature.toStringAsFixed(2)),
              ],
            ),
            Slider(
              value: settingsService.temperature,
              min: 0.0,
              max: 2.0,
              divisions: 20,
              onChanged: (value) {
                settingsService.setTemperature(value);
              },
            ),
            Text(
              'Lower values = more focused, Higher values = more creative',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopPSlider() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top P (Nucleus Sampling)'),
                Text(settingsService.topP.toStringAsFixed(2)),
              ],
            ),
            Slider(
              value: settingsService.topP,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: (value) {
                settingsService.setTopP(value);
              },
            ),
            Text(
              'Controls diversity of word choices',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopKSlider() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top K (Token Limit)'),
                Text(settingsService.topK.toString()),
              ],
            ),
            Slider(
              value: settingsService.topK.toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              onChanged: (value) {
                settingsService.setTopK(value.round());
              },
            ),
            Text(
              'Limits the number of highest probability tokens',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeechEnabledSwitch() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return SwitchListTile(
          title: const Text('Enable Speech Recognition'),
          subtitle: const Text('Allow voice input for messages'),
          value: settingsService.speechEnabled,
          onChanged: (value) {
            settingsService.setSpeechEnabled(value);
          },
        );
      },
    );
  }

  Widget _buildAutoSpeechSwitch() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return SwitchListTile(
          title: const Text('Auto Speech Recognition'),
          subtitle: const Text('Automatically start listening after responses'),
          value: settingsService.autoSpeech,
          onChanged: settingsService.speechEnabled ? (value) {
            settingsService.setAutoSpeech(value);
          } : null,
        );
      },
    );
  }

  Widget _buildSpeechLanguageSelector() {
    const availableLanguages = [
      {'code': 'en-US', 'name': 'English (US)'},
      {'code': 'en-GB', 'name': 'English (UK)'},
      {'code': 'es-ES', 'name': 'Spanish'},
      {'code': 'fr-FR', 'name': 'French'},
      {'code': 'de-DE', 'name': 'German'},
      {'code': 'it-IT', 'name': 'Italian'},
      {'code': 'pt-BR', 'name': 'Portuguese (Brazil)'},
      {'code': 'ja-JP', 'name': 'Japanese'},
      {'code': 'ko-KR', 'name': 'Korean'},
      {'code': 'zh-CN', 'name': 'Chinese (Simplified)'},
    ];

    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return DropdownButtonFormField<String>(
          value: settingsService.speechLanguage,
          decoration: const InputDecoration(
            labelText: 'Speech Language',
            prefixIcon: Icon(Icons.language),
          ),
          items: availableLanguages
              .map((lang) => DropdownMenuItem(
                    value: lang['code'],
                    child: Text(lang['name']!),
                  ))
              .toList(),
          onChanged: settingsService.speechEnabled ? (value) {
            if (value != null) {
              settingsService.setSpeechLanguage(value);
            }
          } : null,
        );
      },
    );
  }

  Widget _buildMicrophonePermissionStatus() {
    return Consumer<SpeechService>(
      builder: (context, speechService, child) {
        return ListTile(
          leading: Icon(
            speechService.hasMicrophonePermission 
                ? Icons.check_circle 
                : Icons.error,
            color: speechService.hasMicrophonePermission 
                ? Colors.green 
                : Colors.red,
          ),
          title: Text(
            speechService.hasMicrophonePermission 
                ? 'Microphone Permission Granted'
                : 'Microphone Permission Required',
          ),
          subtitle: Text(
            speechService.hasMicrophonePermission 
                ? 'Voice input is available'
                : 'Tap to request permission',
          ),
          onTap: speechService.hasMicrophonePermission 
              ? null 
              : () => speechService.requestMicrophonePermission(),
        );
      },
    );
  }

  Widget _buildDarkModeSwitch() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme (restart required)'),
          value: settingsService.darkMode,
          onChanged: (value) {
            settingsService.setDarkMode(value);
          },
        );
      },
    );
  }

  Widget _buildOfflineModeSwitch() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return SwitchListTile(
          title: const Text('Offline Mode'),
          subtitle: const Text('Disable network features'),
          value: settingsService.offlineMode,
          onChanged: (value) {
            settingsService.setOfflineMode(value);
          },
        );
      },
    );
  }

  Widget _buildLoggingLevelSelector() {
    const loggingLevels = [
      {'value': 'debug', 'name': 'Debug (Verbose)'},
      {'value': 'info', 'name': 'Info (Normal)'},
      {'value': 'warning', 'name': 'Warning (Important only)'},
      {'value': 'error', 'name': 'Error (Critical only)'},
    ];

    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return DropdownButtonFormField<String>(
          value: settingsService.loggingLevel,
          decoration: const InputDecoration(
            labelText: 'Logging Level',
            prefixIcon: Icon(Icons.bug_report),
          ),
          items: loggingLevels
              .map((level) => DropdownMenuItem(
                    value: level['value'],
                    child: Text(level['name']!),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              settingsService.setLoggingLevel(value);
            }
          },
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer2<ConnectivityService, LLMService>(
      builder: (context, connectivityService, llmService, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Network status
                _buildStatusRow(
                  'Network',
                  connectivityService.isConnected 
                      ? connectivityService.connectionType 
                      : 'Disconnected',
                  connectivityService.isConnected,
                ),
                
                // LLM status
                _buildStatusRow(
                  'AI Assistant',
                  llmService.isConnected 
                      ? 'Connected (${llmService.currentModel ?? "No model"})' 
                      : llmService.connectionError ?? 'Disconnected',
                  llmService.isConnected,
                ),
                
                // Speech status
                Consumer<SpeechService>(
                  builder: (context, speechService, child) {
                    return _buildStatusRow(
                      'Speech Recognition',
                      speechService.isAvailable 
                          ? 'Available' 
                          : 'Unavailable',
                      speechService.isAvailable,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value, bool isGood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                isGood ? Icons.check_circle : Icons.error,
                size: 16,
                color: isGood ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isGood ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTestingConnection = true);

    try {
      final llmService = context.read<LLMService>();
      final url = _ollamaUrlController.text.trim();
      
      final success = await llmService.testConnection(url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? 'Connection successful!' 
                  : 'Connection failed. Please check the URL and try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          await context.read<SettingsService>().setOllamaUrl(url);
          llmService.refresh();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection test failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsService>().resetToDefaults();
              _ollamaUrlController.text = context.read<SettingsService>().ollamaUrl ?? '';
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}