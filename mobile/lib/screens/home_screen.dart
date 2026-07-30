import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'auth/login_screen.dart';
import 'drafts_screen.dart';
import 'profile_screen.dart';
import 'report_creation/report_type_screen.dart';
import 'reports_pool_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Handles navigation switching
  Widget _getBody(User user) {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard(user);
      case 1:
        return const ReportsPoolScreen();
      case 2:
        return const DraftsScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        if (user.isAdmin) {
          return const AdminDashboardScreen();
        }
        return _buildDashboard(user);
      default:
        return _buildDashboard(user);
    }
  }

  void _createNewReport() {
    Navigator.of(context).push(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const ReportTypeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final User? user = authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 768;

    // Define navigation items dynamically based on admin status
    final List<NavigationDestination> destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
        label: 'Ana Sayfa',
      ),
      const NavigationDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article, color: AppTheme.primaryColor),
        label: 'Havuz',
      ),
      const NavigationDestination(
        icon: Icon(Icons.edit_note_outlined),
        selectedIcon: Icon(Icons.edit_note, color: AppTheme.primaryColor),
        label: 'Taslaklar',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
        label: 'Profil',
      ),
      if (user.isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings, color: AppTheme.primaryColor),
          label: 'Admin',
        ),
    ];

    return Scaffold(
      body: Row(
        children: <Widget>[
          // Side navigation rail for tablets
          if (isTablet)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: GoogleFonts.inter(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: GoogleFonts.inter(
                color: AppTheme.textLight,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              elevation: 4,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TrafoReport',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                      onPressed: () async {
                        await authService.logout();
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<dynamic>(builder: (BuildContext context) => const LoginScreen()),
                          );
                        }
                      },
                      tooltip: 'Oturumu Kapat',
                    ),
                  ),
                ),
              ),
              destinations: destinations.map((NavigationDestination dest) {
                return NavigationRailDestination(
                  icon: dest.icon,
                  selectedIcon: dest.selectedIcon,
                  label: Text(dest.label),
                );
              }).toList(),
            ),
          
          // Main Body Screen
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: SafeArea(child: _getBody(user)),
            ),
          ),
        ],
      ),
      
      // Bottom Navigation bar for mobile viewports
      bottomNavigationBar: !isTablet
          ? NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.white,
              elevation: 8,
              destinations: destinations,
            )
          : null,
    );
  }

  // Dashboard Tab Content
  Widget _buildDashboard(User user) {
    final Size size = MediaQuery.of(context).size;
    final bool isTablet = size.width > 768;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Merhaba, ${user.fullName}',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isAdmin ? 'Yönetici Arayüzü' : 'Saha Bakım Arayüzü',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (size.width <= 768) // Logout button for mobile (on tablet it's in rail)
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                  onPressed: () async {
                    final AuthService authService = Provider.of<AuthService>(context, listen: false);
                    await authService.logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<dynamic>(builder: (BuildContext context) => const LoginScreen()),
                      );
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Primary Quick Action Card: Yeni Rapor Oluştur
          GestureDetector(
            onTap: _createNewReport,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.note_add_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Yeni Rapor Başlat',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Trafo bakım veya test verilerini girmek için tıklayın.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Grid of Other Actions
          Text(
            'Hızlı Menü',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isTablet ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: <Widget>[
              _buildMenuCard(
                'Rapor Havuzu',
                'Kesinleşmiş şirket raporları',
                Icons.folder_shared_outlined,
                AppTheme.primaryColor,
                () => setState(() => _currentIndex = 1),
              ),
              _buildMenuCard(
                'Taslaklar',
                'Yarım kalan raporlarınız',
                Icons.edit_note_rounded,
                AppTheme.secondaryColor,
                () => setState(() => _currentIndex = 2),
              ),
              _buildMenuCard(
                'Profil / İmza',
                'Kullanıcı ayarları & imza',
                Icons.account_circle_outlined,
                AppTheme.accentColor,
                () => setState(() => _currentIndex = 3),
              ),
              if (user.isAdmin)
                _buildMenuCard(
                  'Yönetici Paneli',
                  'Şablon ve kullanıcı yönetimi',
                  Icons.admin_panel_settings_outlined,
                  AppTheme.primaryLight,
                  () => setState(() => _currentIndex = 4),
                )
              else
                _buildMenuCard(
                  'Destek Talebi',
                  'Sorun ve arıza bildirme',
                  Icons.support_agent_outlined,
                  Colors.blueGrey,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Destek hizmeti şu anda çevrimdışı.')),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 32),

          // Informative Section
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Saha Bakım Rehberi',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Saha ölçümlerine başlamadan önce trafo etiketindeki QR/Barkodu okutarak marka, güç, gerilim gibi bilgileri otomatik doldurabilirsiniz.\n'
                    '2. Dinamik formlar, seçtiğiniz trafo tipine göre (Hermetik, Kuru Tip, Genleşme Tanklı) uygun soruları getirecektir.\n'
                    '3. Fotoğraf çekimi adımlarında öncesi, sonrası ve etiket resimlerinin eklenmesi zorunludur.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textLight,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
