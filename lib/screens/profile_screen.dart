import 'package:flutter/material.dart';
import 'package:ethio_trading_app/models/user_profile.dart';
import 'package:ethio_trading_app/data/mock_data.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

// ProfileScreen is a StatefulWidget that displays and allows the user to edit their profile information.
class ProfileScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  // Constructor for ProfileScreen. Requires a callback function to change the theme.
  const ProfileScreen({super.key, required this.onThemeChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// _ProfileScreenState is the state class for ProfileScreen.
class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for the username and email text fields.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // userProfile will hold the current user profile data.
  late UserProfile userProfile;
  // newUserProfile will hold the user data when it is changed.
  late UserProfile newUserProfile;

  @override
  void initState() {
    super.initState();
    // Initialize the userProfile with mock data.
    userProfile = generateMockUserProfile();
    // Initialize the newUserProfile with the current user profile.
    newUserProfile = UserProfile(
      userId: userProfile.userId,
      username: userProfile.username,
      email: userProfile.email,
      profilePictureUrl: userProfile.profilePictureUrl,
    );

    // Set the initial text for the username controller.
    _usernameController.text = userProfile.username;
    // Set the initial text for the email controller.
    _emailController.text = userProfile.email;
  }

  // Dispose the controllers when the widget is removed from the widget tree.
  @override
  void dispose() {
    // Dispose the username controller.
    _usernameController.dispose();
    // Dispose the email controller.
    _emailController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    setState(() {
      userProfile = UserProfile(
          userId: userProfile.userId,
          username: newUserProfile.username,
          email: newUserProfile.email,
          profilePictureUrl: userProfile.profilePictureUrl);
      // Update the username controller text.
      _usernameController.text = newUserProfile.username;
      // Update the email controller text.
      _emailController.text = newUserProfile.email;
    });
    // Show a snackbar to indicate that the profile has been updated.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!')),
    );
  }

  // The build method describes the part of the user interface represented by this widget.
  // This method is called whenever the widget needs to rebuild.
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
        appBar: AppBar(
          title: Text(languageProvider.translate('profile')),
        ),
        body: Padding(
          // Add padding to the body.
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              // Display User Data
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(userProfile.username),
                subtitle: Text(userProfile.email),
              ),
              // Add spacing between the user data and the username input field.
              const SizedBox(height: 20),
              // Username Input
              TextField(
                // Set the controller for the username input field.
                controller: _usernameController,
                // Customize the decoration of the username input field.
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                // Update the user profile when the username changes.
                onChanged: (value) {
                  setState(() {
                    newUserProfile = UserProfile(
                        userId: newUserProfile.userId,
                        username: value,
                        email: newUserProfile.email,
                        profilePictureUrl: newUserProfile.profilePictureUrl);
                  });
                },
              ),
              // Add spacing between the username input field and the email input field.
              const SizedBox(height: 20),
              // Email Input
              TextField(
                // Set the controller for the email input field.
                controller: _emailController,
                // Customize the decoration of the email input field.
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                // Update the user profile when the email changes.
                onChanged: (value) {
                  setState(() {
                    newUserProfile = UserProfile(
                        userId: newUserProfile.userId,
                        username: newUserProfile.username,
                        email: value,
                        profilePictureUrl: newUserProfile.profilePictureUrl);
                  });
                },
              ),
              // Add spacing between the email input field and the save changes button.
              const SizedBox(height: 20),
              // Save Changes Button
              ElevatedButton(
                // Save the changes when the button is pressed.
                onPressed: _saveChanges,
                child: const Text('Save Changes'),
              ),
              // Add spacing between the save changes button and the language selection.
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.translate('language'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<String>(
                        title: const Text('English'),
                        value: 'en',
                        groupValue: languageProvider.currentLanguage,
                        onChanged: (value) {
                          if (value != null) {
                            languageProvider.setLanguage(value);
                          }
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('አማርኛ'),
                        value: 'am',
                        groupValue: languageProvider.currentLanguage,
                        onChanged: (value) {
                          if (value != null) {
                            languageProvider.setLanguage(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Add spacing between the language selection and the theme change buttons.
              const SizedBox(height: 20),
              // Theme change buttons
              ElevatedButton(
                onPressed: () => widget.onThemeChanged(ThemeMode.light),
                child: const Text('Light Mode'),
              ),
              ElevatedButton(
                // Change the theme to dark mode when the button is pressed.
                onPressed: () => widget.onThemeChanged(ThemeMode.dark),
                child: const Text('Dark Mode'),
              ),
              ElevatedButton(
                onPressed: () => widget.onThemeChanged(ThemeMode.system),
                child: const Text('System Default'),
              ),
            ],
          ),
        ));
  }
}
