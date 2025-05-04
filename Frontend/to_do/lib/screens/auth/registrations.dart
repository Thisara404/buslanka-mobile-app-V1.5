import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do/config/config.dart';
import 'package:to_do/providers/auth_provider.dart';
import 'package:to_do/screens/auth/login_screen.dart';
import 'package:to_do/utils/validators.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isPassenger;

  const RegistrationScreen({
    Key? key,
    required this.isPassenger,
  }) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isPassenger = true;

  @override
  void initState() {
    super.initState();
    _isPassenger = widget.isPassenger;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final Map<String, dynamic> registrationData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'password': _passwordController.text,
        };

        if (_isPassenger) {
          registrationData['addresses'] = {
            'home': _addressController.text.trim()
          };
        } else {
          registrationData['address'] = _addressController.text.trim();
          // Fix: Generate a unique placeholder instead of 'TBD'
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          registrationData['busDetails'] = {
            'busNumber': 'PENDING_$timestamp' // Generate unique placeholder
          };
        }

        final success =
            await authProvider.register(registrationData, _isPassenger);

        if (success) {
          setState(() {
            _successMessage = 'Registration successful! You can now login.';
          });

          // Clear form fields
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _addressController.clear();

          // Navigate to login after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get localization or provide fallbacks
    final l10n = AppLocalizations.of(context);
    final emailLabel = l10n?.email ?? 'Email';
    final passwordLabel = l10n?.password ?? 'Password';
    final registerButtonText = l10n?.registerButton ?? 'REGISTER';

    // This handles the case when localization isn't available yet

    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isPassenger ? 'Passenger Registration' : 'Driver Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),

              // Role selection toggle
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(l10n?.passengerRole ?? 'Passenger'),
                      value: true,
                      groupValue: _isPassenger,
                      onChanged: (value) {
                        setState(() {
                          _isPassenger = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: Text(l10n?.driverRole ?? 'Driver'),
                      value: false,
                      groupValue: _isPassenger,
                      onChanged: (value) {
                        setState(() {
                          _isPassenger = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n?.fullName ?? 'Full Name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.nameValidator,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: emailLabel,
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.emailValidator,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n?.phoneNumber ?? 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.phoneValidator,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: _isPassenger ? 'Home Address' : 'Address',
                  prefixIcon: const Icon(Icons.home),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.addressValidator,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: passwordLabel,
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                ),
                validator: Validators.passwordValidator,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n?.confirmPassword ?? 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => Validators.confirmPasswordValidator(
                    value, _passwordController.text),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(registerButtonText),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: Text(
                    l10n?.loginPrompt ?? "Already have an account? Login now."),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
