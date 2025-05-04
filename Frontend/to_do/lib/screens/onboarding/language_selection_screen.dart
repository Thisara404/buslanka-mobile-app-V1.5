import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/providers/language_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/screens/onboarding/role_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final bool isOnboarding;

  const LanguageSelectionScreen({
    Key? key,
    this.isOnboarding = true,
  }) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLocale = languageProvider.currentLocale;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isOnboarding
              ? 'Select Language'
              : AppLocalizations.of(context)?.languageSettings ?? 'Language',
        ),
        centerTitle: true,
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Choose your preferred language',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (Locale locale in LanguageProvider.supportedLocales)
                  _buildLanguageCard(
                    context,
                    locale,
                    isSelected:
                        locale.languageCode == currentLocale.languageCode,
                    onTap: () => _selectLanguage(locale),
                  ),
              ],
            ),
          ),
          if (widget.isOnboarding)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _continueToNextScreen,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: const Text('Continue'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    Locale locale, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      elevation: isSelected ? 2.0 : 1.0,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        title: Text(
          LanguageProvider.getLanguageName(locale),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _selectLanguage(Locale locale) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    await languageProvider.changeLanguage(locale);
  }

  void _continueToNextScreen() {
    if (widget.isOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    } else {
      Navigator.pop(context);
    }
  }
}
