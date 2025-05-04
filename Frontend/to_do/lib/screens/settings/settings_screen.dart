import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/providers/language_provider.dart';
import 'package:to_do/providers/theme_provider.dart';
import 'package:to_do/screens/onboarding/language_selection_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/utils/ui_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationTrackingEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedTheme = 'System Default';
  String _selectedDistance = 'Kilometers';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _locationTrackingEnabled =
          prefs.getBool('locationTrackingEnabled') ?? true;
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
      _selectedTheme = prefs.getString('selectedTheme') ?? 'System Default';
      _selectedDistance = prefs.getString('selectedDistance') ?? 'Kilometers';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('locationTrackingEnabled', _locationTrackingEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    await prefs.setString('selectedTheme', _selectedTheme);
    await prefs.setString('selectedDistance', _selectedDistance);
  }

  void _showLanguageSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LanguageSelectionScreen(isOnboarding: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentLanguage =
        LanguageProvider.getLanguageName(languageProvider.currentLocale);
    final userRole = Provider.of<AuthProvider>(context).userRole;

    return Scaffold(
      appBar: AppBar(
        title: Text(UIStrings.settings),
      ),
      body: ListView(
        children: [
          _buildSection(
            title: _getGeneralText(l10n),
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(_getLanguageText(l10n)),
                subtitle: Text(currentLanguage),
                onTap: _showLanguageSettings,
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: Text(_getThemeText(l10n)),
                subtitle: Text(_selectedTheme),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: Text(_getSelectThemeText(l10n)),
                      children: [
                        RadioListTile<String>(
                          title: const Text('System Default'),
                          value: 'System Default',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() {
                              _selectedTheme = value!;
                              _saveSettings();
                            });
                            themeProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Light'),
                          value: 'Light',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() {
                              _selectedTheme = value!;
                              _saveSettings();
                            });
                            themeProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Dark'),
                          value: 'Dark',
                          groupValue: _selectedTheme,
                          onChanged: (value) {
                            setState(() {
                              _selectedTheme = value!;
                              _saveSettings();
                            });
                            themeProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                    _saveSettings();
                  });
                  themeProvider.setDarkMode(value);
                },
              ),
            ],
          ),
          _buildSection(
            title: _getNotificationsText(l10n),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications),
                title: Text(_getNotificationsText(l10n)),
                subtitle: Text(_getNotificationsDescriptionText(l10n)),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                    _saveSettings();
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: _getPrivacyText(l10n),
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.location_on),
                title: Text(_getLocationTrackingText(l10n)),
                subtitle: Text(_getLocationTrackingDescriptionText(l10n)),
                value: _locationTrackingEnabled,
                onChanged: (value) {
                  setState(() {
                    _locationTrackingEnabled = value;
                    _saveSettings();
                  });
                },
              ),
            ],
          ),
          _buildSection(
            title: _getUnitsText(l10n),
            children: [
              ListTile(
                leading: const Icon(Icons.straighten),
                title: Text(_getDistanceUnitText(l10n)),
                subtitle: Text(_selectedDistance),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: Text(_getSelectDistanceUnitText(l10n)),
                      children: [
                        RadioListTile<String>(
                          title: const Text('Kilometers'),
                          value: 'Kilometers',
                          groupValue: _selectedDistance,
                          onChanged: (value) {
                            setState(() {
                              _selectedDistance = value!;
                              _saveSettings();
                            });
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Miles'),
                          value: 'Miles',
                          groupValue: _selectedDistance,
                          onChanged: (value) {
                            setState(() {
                              _selectedDistance = value!;
                              _saveSettings();
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          // Show role-specific settings
          if (userRole == 'driver')
            _buildSection(
              title: _getDriverSettingsText(l10n),
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: Text(_getArrivalAlertText(l10n)),
                  subtitle: const Text('100 meters'),
                  onTap: () {
                    // Show arrival alert distance settings
                    _showArrivalAlertSettings();
                  },
                ),
              ],
            ),
          if (userRole == 'passenger')
            _buildSection(
              title: _getPassengerSettingsText(l10n),
              children: [
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: Text(_getEtaPreferenceText(l10n)),
                  subtitle: const Text('Conservative'),
                  onTap: () {
                    // Show ETA preference settings
                    _showEtaPreferenceSettings();
                  },
                ),
              ],
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Clear app data
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(_getClearDataText(l10n)),
                        content: Text(_getClearDataConfirmationText(l10n)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(_getCancelText(l10n)),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearAppData();
                              Navigator.pop(context);
                            },
                            child: Text(_getClearText(l10n)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_getClearAppDataText(l10n)),
                ),
                const SizedBox(height: 8),
                Text(
                  'App Version: 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showArrivalAlertSettings() {
    // Implement a dialog or screen for configuring arrival alert distance
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrival Alert Distance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Select how far in advance you want to be notified about arrival at stops'),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: 100,
              items: [50, 100, 200, 300].map((meters) {
                return DropdownMenuItem<int>(
                  value: meters,
                  child: Text('$meters meters'),
                );
              }).toList(),
              onChanged: (value) {
                // Save the selected value
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Arrival alert distance set to $value meters')),
                );
              },
              isExpanded: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEtaPreferenceSettings() {
    // Implement a dialog or screen for configuring ETA preference
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ETA Preference'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Select how your estimated time of arrival is calculated'),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: 'Conservative',
              items: ['Optimistic', 'Balanced', 'Conservative'].map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                // Save the selected value
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ETA preference set to $value')),
                );
              },
              isExpanded: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAppData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Reset local state
      setState(() {
        _notificationsEnabled = true;
        _locationTrackingEnabled = true;
        _darkModeEnabled = false;
        _selectedTheme = 'System Default';
        _selectedDistance = 'Kilometers';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App data cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear app data: $e')),
        );
      }
    }
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }
}

// Helper methods to get localized strings with fallbacks
String _getGeneralText(AppLocalizations? l10n) => l10n?.general ?? 'General';
String _getSettingsText(AppLocalizations? l10n) => l10n?.settings ?? 'Settings';
String _getLanguageText(AppLocalizations? l10n) => l10n?.language ?? 'Language';
String _getThemeText(AppLocalizations? l10n) => l10n?.theme ?? 'Theme';
String _getSelectThemeText(AppLocalizations? l10n) =>
    l10n?.selectTheme ?? 'Select Theme';
String _getNotificationsText(AppLocalizations? l10n) =>
    l10n?.notifications ?? 'Notifications';
String _getNotificationsDescriptionText(AppLocalizations? l10n) =>
    l10n?.notificationsDescription ?? 'Get notified about important updates';
String _getLocationTrackingText(AppLocalizations? l10n) =>
    l10n?.locationTracking ?? 'Background Location Tracking';
String _getLocationTrackingDescriptionText(AppLocalizations? l10n) =>
    l10n?.locationTrackingDescription ??
    'Allow the app to track your location in the background';
String _getPrivacyText(AppLocalizations? l10n) => l10n?.privacy ?? 'Privacy';
String _getUnitsText(AppLocalizations? l10n) => l10n?.units ?? 'Units';
String _getSelectDistanceUnitText(AppLocalizations? l10n) =>
    l10n?.selectDistanceUnit ?? 'Select Distance Unit';
String _getDistanceUnitText(AppLocalizations? l10n) =>
    l10n?.distanceUnit ?? 'Distance Unit';
String _getArrivalAlertText(AppLocalizations? l10n) =>
    l10n?.arrivalAlert ?? 'Arrival Alert Distance';
String _getDriverSettingsText(AppLocalizations? l10n) =>
    l10n?.driverSettings ?? 'Driver Settings';
String _getPassengerSettingsText(AppLocalizations? l10n) =>
    l10n?.passengerSettings ?? 'Passenger Settings';
String _getEtaPreferenceText(AppLocalizations? l10n) =>
    l10n?.etaPreference ?? 'ETA Preference';
String _getClearDataText(AppLocalizations? l10n) =>
    l10n?.clearData ?? 'Clear App Data';
String _getCancelText(AppLocalizations? l10n) => l10n?.cancel ?? 'Cancel';
String _getClearDataConfirmationText(AppLocalizations? l10n) =>
    l10n?.clearDataConfirmation ??
    'Are you sure you want to clear all app data? This cannot be undone.';
String _getClearText(AppLocalizations? l10n) => l10n?.clear ?? 'Clear';
String _getClearAppDataText(AppLocalizations? l10n) =>
    l10n?.clearAppData ?? 'Clear App Data';
