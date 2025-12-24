import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_messaging_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_messaging_app/core/config/theme/theme_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController();
  final _picker = ImagePicker();

  void _showEditProfileDialog(BuildContext context, String? currentName, String? currentAvatar) {
    _nameController.text = currentName ?? '';
    XFile? selectedImage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        selectedImage = image;
                      });
                    }
                  },
                  child: FutureBuilder<Widget>(
                    future: _buildAvatarImage(selectedImage, currentAvatar),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        radius: 40,
                        child: snapshot.data ?? const Icon(Icons.person, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Tap to change photo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(
                    AuthUpdateProfileRequested(
                      name: _nameController.text,
                      imageFile: selectedImage,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Widget> _buildAvatarImage(XFile? selectedImage, String? currentAvatar) async {
    if (selectedImage != null) {
      final bytes = await selectedImage.readAsBytes();
      return ClipOval(
        child: Image.memory(
          bytes,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    } else if (currentAvatar != null) {
      return ClipOval(
        child: Image.network(
          currentAvatar,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(Icons.person, size: 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          String name = 'Guest';
          String email = 'Not Logged In';
          String? avatarUrl;

          if (state is AuthAuthenticated) {
            name = state.user.name ?? 'No Name';
            email = state.user.email;
            avatarUrl = state.user.avatarUrl;
          }

          return ListView(
            children: [
              // Profile Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                     GestureDetector(
                       onTap: () {
                         if (state is AuthAuthenticated) {
                           _showEditProfileDialog(context, state.user.name, state.user.avatarUrl);
                         }
                       },
                       child: Stack(
                         children: [
                           CircleAvatar(
                            radius: 35,
                            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null ? const Icon(Icons.person, size: 35) : null,
                                                   ),
                           Positioned(
                             right: 0,
                             bottom: 0,
                             child: Container(
                               padding: const EdgeInsets.all(4),
                               decoration: BoxDecoration(
                                 color: Theme.of(context).primaryColor,
                                 shape: BoxShape.circle,
                               ),
                               child: const Icon(Icons.edit, size: 12, color: Colors.white),
                             ),
                           )
                         ],
                       ),
                     ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              _buildSectionHeader(context, 'Account'),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit Profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                   if (state is AuthAuthenticated) {
                      _showEditProfileDialog(context, state.user.name, state.user.avatarUrl);
                   }
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),

              _buildSectionHeader(context, 'Preferences'),
               ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: Switch(value: true, onChanged: (v) {}, activeColor: Theme.of(context).primaryColor),
              ),
               ListTile(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (v) {
                    context.read<ThemeCubit>().toggleTheme(v);
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).primaryColor, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}
