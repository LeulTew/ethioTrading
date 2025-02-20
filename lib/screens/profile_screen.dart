import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/ethiopian_utils.dart';

class ProfileScreen extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const ProfileScreen({super.key, required this.onThemeChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bankAccountController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    if (userData != null) {
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phoneNumber'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _bankAccountController.text = userData['bankAccountNumber'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.updateProfile({
        'username': _usernameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'bankAccountNumber': _bankAccountController.text,
      });

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    final userData = Provider.of<AuthProvider>(context).userData;
    final tradingLevel = userData?['tradingLevel'] ?? 'beginner';
    final isVerified = userData?['isVerified'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      userData?['profilePictureUrl'] ??
                          'https://ui-avatars.com/api/?name=${_usernameController.text}',
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          onPressed: () {/* Implement photo upload */},
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Trading Level Badge
            Center(
              child: Chip(
                avatar: Icon(
                  tradingLevel == 'advanced'
                      ? Icons.workspace_premium
                      : tradingLevel == 'intermediate'
                          ? Icons.trending_up
                          : Icons.school,
                  color: theme.primaryColor,
                ),
                label: Text(
                  tradingLevel.toUpperCase(),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Verification Status
            ListTile(
              leading: Icon(
                isVerified ? Icons.verified : Icons.warning,
                color: isVerified ? Colors.green : Colors.orange,
              ),
              title: Text(
                  isVerified ? 'Verified Account' : 'Verification Required'),
              subtitle: Text(isVerified
                  ? 'Your account is fully verified'
                  : 'Complete verification to unlock full trading features'),
              trailing: isVerified
                  ? null
                  : TextButton(
                      onPressed: () {/* Implement verification flow */},
                      child: const Text('Verify Now'),
                    ),
            ),
            const Divider(),

            // Profile Fields
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                enabled: _isEditing,
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _emailController,
              enabled: false, // Email changes require verification
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                enabled: _isEditing,
                prefixIcon: const Icon(Icons.phone),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Phone number is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                enabled: _isEditing,
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 2,
              validator: (value) =>
                  value?.isEmpty == true ? 'Address is required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _bankAccountController,
              decoration: InputDecoration(
                labelText: 'Bank Account Number',
                enabled: _isEditing,
                prefixIcon: const Icon(Icons.account_balance),
              ),
              validator: (value) => value?.isEmpty == true
                  ? 'Bank account number is required'
                  : null,
            ),
            const SizedBox(height: 24),

            if (!_isEditing)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesTab() {
    final languageProvider = context.watch<LanguageProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                RadioListTile<String>(
                  title: const Text('English'),
                  value: 'en',
                  groupValue: languageProvider.currentLanguage,
                  onChanged: (value) =>
                      languageProvider.setLanguage(value ?? 'en'),
                ),
                RadioListTile<String>(
                  title: const Text('አማርኛ'),
                  value: 'am',
                  groupValue: languageProvider.currentLanguage,
                  onChanged: (value) =>
                      languageProvider.setLanguage(value ?? 'am'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode),
                  title: const Text('Light Mode'),
                  onTap: () => widget.onThemeChanged(ThemeMode.light),
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Dark Mode'),
                  onTap: () => widget.onThemeChanged(ThemeMode.dark),
                ),
                ListTile(
                  leading: const Icon(Icons.settings_brightness),
                  title: const Text('System Default'),
                  onTap: () => widget.onThemeChanged(ThemeMode.system),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTradingLimitsTab() {
    final userData = Provider.of<AuthProvider>(context).userData;
    final tradingLevel = userData?['tradingLevel'] ?? 'beginner';
    final availableBalance = userData?['availableBalance'] ?? 0.0;

    String limit;
    switch (tradingLevel) {
      case 'advanced':
        limit = '1,000,000';
        break;
      case 'intermediate':
        limit = '500,000';
        break;
      default:
        limit = '100,000';
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trading Level Overview'),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Current Level'),
                  trailing: Text(
                    tradingLevel.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Daily Trading Limit'),
                  trailing: Text(
                    'ETB $limit',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  title: const Text('Available Balance'),
                  trailing: Text(
                    EthiopianCurrencyFormatter.format(availableBalance),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tradingLevel != 'advanced')
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Upgrade Your Trading Level'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {/* Implement upgrade flow */},
                    child: const Text('Request Upgrade'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security Settings'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: const Text('Change Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* Implement password change */},
                ),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Two-Factor Authentication'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* Implement 2FA */},
                ),
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('Trusted Devices'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* Implement device management */},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Activity Log'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Login History'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {/* Implement login history */},
                ),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Security Notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {/* Implement notification toggle */},
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Profile'),
            Tab(text: 'Preferences'),
            Tab(text: 'Trading Limits'),
            Tab(text: 'Security'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildPreferencesTab(),
          _buildTradingLimitsTab(),
          _buildSecurityTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }
}
