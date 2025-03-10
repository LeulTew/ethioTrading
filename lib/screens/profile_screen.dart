import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../utils/ethiopian_utils.dart';
import '../widgets/custom_bottom_nav.dart';

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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    try {
      await authProvider.updateProfile({
        'username': _usernameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
        'bankAccountNumber': _bankAccountController.text,
      });

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(lang.translate('profile_updated')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text(lang.translate('update_error')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildProfileCard({
    required String title,
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38), // 0.15 * 255
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty) ...[
                      Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
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
            // Profile Header with Avatar
            Center(
              child: FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          userData?['profilePictureUrl'] ??
                              'https://ui-avatars.com/api/?name=${_usernameController.text}',
                        ),
                      ).animate(
                        effects: [
                          ShimmerEffect(
                            duration: const Duration(seconds: 2),
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              onPressed: () {/* Implement photo upload */},
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Trading Level Badge
            Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tradingLevel == 'advanced'
                            ? Icons.workspace_premium
                            : tradingLevel == 'intermediate'
                                ? Icons.trending_up
                                : Icons.school,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        lang.translate(tradingLevel).toUpperCase(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Verification Status Card
            _buildProfileCard(
              title: '',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.verified : Icons.warning,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    lang.translate(isVerified
                        ? 'verified_account'
                        : 'verification_required'),
                    style:
                        GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    lang.translate(isVerified
                        ? 'account_verified'
                        : 'complete_verification'),
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: isVerified
                      ? null
                      : TextButton.icon(
                          onPressed: () {/* Implement verification flow */},
                          icon: const Icon(Icons.verified_user),
                          label: Text(lang.translate('verify_now')),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Fields Card
            _buildProfileCard(
              title: lang.translate('personal_info'),
              children: [
                _buildProfileField(
                  controller: _usernameController,
                  label: lang.translate('username'),
                  icon: Icons.person,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty == true
                      ? lang.translate('username_required')
                      : null,
                ),
                const SizedBox(height: 16),

                _buildProfileField(
                  controller: _emailController,
                  label: lang.translate('email'),
                  icon: Icons.email,
                  enabled: false,
                ),
                const SizedBox(height: 16),

                _buildProfileField(
                  controller: _phoneController,
                  label: lang.translate('phone_number'),
                  icon: Icons.phone,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty == true
                      ? lang.translate('phone_required')
                      : null,
                ),
                const SizedBox(height: 16),

                _buildProfileField(
                  controller: _addressController,
                  label: lang.translate('address'),
                  icon: Icons.location_on,
                  enabled: _isEditing,
                  maxLines: 2,
                  validator: (value) => value?.isEmpty == true
                      ? lang.translate('address_required')
                      : null,
                ),
                const SizedBox(height: 16),

                _buildProfileField(
                  controller: _bankAccountController,
                  label: lang.translate('bank_account'),
                  icon: Icons.account_balance,
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty == true
                      ? lang.translate('bank_account_required')
                      : null,
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Center(
                  child: _isEditing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _isEditing = false),
                              icon: const Icon(Icons.cancel),
                              label: Text(lang.translate('cancel')),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveProfile,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(lang.translate('save_changes')),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.edit),
                          label: Text(lang.translate('edit_profile')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
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
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('profile')),
        automaticallyImplyLeading: false, // Prevent back button
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: lang.translate('profile')),
            Tab(text: lang.translate('preferences')),
            Tab(text: lang.translate('trading_level')),
            Tab(text: lang.translate('security')),
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
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3, // Profile is selected
        onTap: (index) {
          if (index != 3) {
            // Navigate to the appropriate screen
            final routes = ['/home', '/market', '/portfolio', '/profile'];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
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
