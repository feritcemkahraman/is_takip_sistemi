import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../login_screen.dart';
import '../user_management_screen.dart';
import '../meeting_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yönetici Paneli'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Bildirimler ekranına yönlendir
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
        children: [
          FutureBuilder(
            future: authService.getCurrentUserModel(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const DrawerHeader(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final user = snapshot.data!;
              return UserAccountsDrawerHeader(
                accountName: Text(user.name),
                accountEmail: Text(user.email),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Genel Bakış'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Kullanıcı Yönetimi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: Text('Görev Yönetimi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: Text('Toplantı Yönetimi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: Text('Departman Yönetimi'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: Text('Raporlar'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Ayarlar'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Divider(),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: Text('Yardım'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardPage(),
          UserManagementScreen(),
          _buildTaskManagementPage(),
          const MeetingListScreen(),
          _buildDepartmentManagementPage(),
          _buildReportsPage(),
          _buildSettingsPage(),
          _buildHelpPage(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildDashboardPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(),
          const SizedBox(height: 24),
          _buildRecentActivities(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          title: 'Toplam Kullanıcı',
          value: '24',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Aktif Görevler',
          value: '12',
          icon: Icons.task,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Departmanlar',
          value: '6',
          icon: Icons.business,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Tamamlanan Görevler',
          value: '156',
          icon: Icons.check_circle,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Aktiviteler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    _getActivityIcon(index),
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: Text(_getActivityTitle(index)),
                subtitle: Text(_getActivityTime(index)),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Aktivite detayına yönlendir
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person_add;
      case 1:
        return Icons.task;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.business;
      case 4:
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  String _getActivityTitle(int index) {
    switch (index) {
      case 0:
        return 'Yeni kullanıcı kaydı yapıldı';
      case 1:
        return 'Yeni görev oluşturuldu';
      case 2:
        return 'Görev tamamlandı';
      case 3:
        return 'Departman güncellendi';
      case 4:
        return 'Kullanıcı bilgileri güncellendi';
      default:
        return 'Bilinmeyen aktivite';
    }
  }

  String _getActivityTime(int index) {
    switch (index) {
      case 0:
        return '5 dakika önce';
      case 1:
        return '15 dakika önce';
      case 2:
        return '1 saat önce';
      case 3:
        return '3 saat önce';
      case 4:
        return '5 saat önce';
      default:
        return '';
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildActionButton(
              title: 'Kullanıcı Ekle',
              icon: Icons.person_add,
              onTap: () {
                // TODO: Kullanıcı ekleme ekranına yönlendir
              },
            ),
            _buildActionButton(
              title: 'Görev Oluştur',
              icon: Icons.add_task,
              onTap: () {
                // TODO: Görev oluşturma ekranına yönlendir
              },
            ),
            _buildActionButton(
              title: 'Rapor Al',
              icon: Icons.download,
              onTap: () {
                // TODO: Rapor indirme işlemini başlat
              },
            ),
            _buildActionButton(
              title: 'Ayarlar',
              icon: Icons.settings,
              onTap: () {
                // TODO: Ayarlar ekranına yönlendir
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 150,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskManagementPage() {
    return const Center(child: Text('Görev Yönetimi'));
  }

  Widget _buildDepartmentManagementPage() {
    return const Center(child: Text('Departman Yönetimi'));
  }

  Widget _buildReportsPage() {
    return const Center(child: Text('Raporlar'));
  }

  Widget _buildSettingsPage() {
    return const Center(child: Text('Ayarlar'));
  }

  Widget _buildHelpPage() {
    return const Center(child: Text('Yardım'));
  }

  Widget? _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 1: // Kullanıcı Yönetimi
        return FloatingActionButton(
          onPressed: () {
            // TODO: Yeni kullanıcı ekleme ekranına yönlendir
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.person_add),
        );
      case 2: // Görev Yönetimi
        return FloatingActionButton(
          onPressed: () {
            // TODO: Yeni görev ekleme ekranına yönlendir
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add_task),
        );
      case 3: // Departman Yönetimi
        return FloatingActionButton(
          onPressed: () {
            // TODO: Yeni departman ekleme ekranına yönlendir
          },
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add_business),
        );
      default:
        return null;
    }
  }
}
