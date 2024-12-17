import 'package:flutter/material.dart';
import '../../constants/color_constants.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: ColorConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Yönetici',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_outline,
                  title: 'Kullanıcılar',
                  onTap: () {
                    // Navigate to users page
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.folder_outlined,
                  title: 'Projeler',
                  onTap: () {
                    // Navigate to projects page
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.task_outlined,
                  title: 'Görevler',
                  onTap: () {
                    // Navigate to tasks page
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics_outlined,
                  title: 'Raporlar',
                  onTap: () {
                    // Navigate to reports page
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings_outlined,
                  title: 'Ayarlar',
                  onTap: () {
                    // Navigate to settings page
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildDrawerItem(
              icon: Icons.logout_outlined,
              title: 'Çıkış Yap',
              onTap: () {
                // Handle logout
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }
}
