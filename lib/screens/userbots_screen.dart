import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/userbot_provider.dart';
import 'add_userbot_screen.dart';

class UserbotsScreen extends StatelessWidget {
  const UserbotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Userbotlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddUserbotScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserbotProvider>(
        builder: (context, provider, child) {
          if (provider.userbots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Userbotlar mavjud emas',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddUserbotScreen(),
                        ),
                      );
                    },
                    child: const Text('Yangi userbot qo\'shish'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.userbots.length,
            itemBuilder: (context, index) {
              final userbot = provider.userbots[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      userbot.phoneNumber[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(userbot.phoneNumber),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Holat: ${userbot.status}'),
                      if (userbot.isAuthenticated)
                        const Text(
                          'Tasdiqlangan: Ha',
                          style: TextStyle(color: Colors.green),
                        ),
                      Text('Oxirgi faollik: ${_formatDateTime(userbot.lastActive)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!userbot.isAuthenticated && !userbot.isWaitingForCode)
                        IconButton(
                          icon: const Icon(Icons.login),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddUserbotScreen(),
                              ),
                            );
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showEditUserbotDialog(context, userbot, index);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteUserbotDialog(context, index);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  Future<void> _showEditUserbotDialog(BuildContext context, Userbot userbot, int index) async {
    final numberController = TextEditingController(text: userbot.phoneNumber);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Userbotni tahrirlash'),
        content: TextField(
          controller: numberController,
          decoration: const InputDecoration(
            labelText: 'Telefon raqam',
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<UserbotProvider>();
              provider.editUserbot(index, numberController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteUserbotDialog(BuildContext context, int index) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Userbotni o\'chirish'),
        content: const Text('Rostdan ham bu userbotni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<UserbotProvider>();
              provider.deleteUserbot(index);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}
