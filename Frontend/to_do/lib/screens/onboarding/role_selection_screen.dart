import 'package:flutter/material.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/screens/auth/registrations.dart' as registration;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'Bus Tracking'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Are you a passenger or driver?',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: RoleButton(
                  title: l10n?.passengerRole ?? 'Passenger',
                  description: 'Track buses and manage your commute',
                  icon: Icons.person,
                  onTap: () => _navigateToAuth(context, isPassenger: true),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RoleButton(
                  title: l10n?.driverRole ?? 'Driver',
                  description: 'Manage your routes and update locations',
                  icon: Icons.directions_bus,
                  onTap: () => _navigateToAuth(context, isPassenger: false),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToAuth(BuildContext context, {required bool isPassenger}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => registration.RegistrationScreen(isPassenger: isPassenger),
      ),
    );
  }
}

class RoleButton extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const RoleButton({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
