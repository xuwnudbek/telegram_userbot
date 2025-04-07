import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/telegram_provider.dart';
import 'userbots_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Dastur ishga tushganda API kalitlarini yuklash
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TelegramProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram Userbot'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Telegram Userbot',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Userbotlar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserbotsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Sozlamalar'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Consumer<TelegramProvider>(
        builder: (context, provider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!provider.isInitialized)
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('API kalitlarini kiritish'),
                  ),
                if (provider.isInitialized) ...[
                  ElevatedButton(
                    onPressed: () {
                      _showImportDialog(context);
                    },
                    child: const Text('Telefon raqamlarni import qilish'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showChannelDialog(context);
                    },
                    child: const Text('Kanalga qo\'shilish'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showGroupDialog(context);
                    },
                    child: const Text('Guruhga qo\'shilish'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showUserbotsDialog(BuildContext context) async {
    final provider = context.read<TelegramProvider>();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Userbotlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.phoneNumbers.isEmpty)
              const Text('Userbotlar mavjud emas')
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: provider.phoneNumbers.length,
                itemBuilder: (context, index) {
                  final number = provider.phoneNumbers[index];
                  return ListTile(
                    title: Text(number),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _showEditUserbotDialog(context, number, index);
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
                  );
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              _showAddUserbotDialog(context);
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserbotDialog(BuildContext context) async {
    final numberController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi userbot qo\'shish'),
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
          TextButton(
            onPressed: () {
              final provider = context.read<TelegramProvider>();
              provider.importPhoneNumbers([numberController.text]);
              Navigator.of(context).pop();
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditUserbotDialog(BuildContext context, String currentNumber, int index) async {
    final numberController = TextEditingController(text: currentNumber);

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
          TextButton(
            onPressed: () {
              final provider = context.read<TelegramProvider>();
              provider.editPhoneNumber(index, numberController.text);
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
          TextButton(
            onPressed: () {
              final provider = context.read<TelegramProvider>();
              provider.deletePhoneNumber(index);
              Navigator.of(context).pop();
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(BuildContext context) async {
    final numbersController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Telefon raqamlarni kiriting'),
        content: TextField(
          controller: numbersController,
          decoration: const InputDecoration(
            labelText: 'Raqamlar (har bir qator yangi raqam)',
          ),
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              final numbers = numbersController.text.split('\n').where((line) => line.isNotEmpty).toList();
              final provider = context.read<TelegramProvider>();
              provider.importPhoneNumbers(numbers);
              Navigator.of(context).pop();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChannelDialog(BuildContext context) async {
    final usernameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanal usernameni kiriting'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Kanal username (@ belgisiz)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<TelegramProvider>();
              provider.joinChannel(usernameController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Qo\'shilish'),
          ),
        ],
      ),
    );
  }

  Future<void> _showGroupDialog(BuildContext context) async {
    final usernameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guruh usernameni kiriting'),
        content: TextField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Guruh username (@ belgisiz)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              final provider = context.read<TelegramProvider>();
              provider.joinGroup(usernameController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Qo\'shilish'),
          ),
        ],
      ),
    );
  }
}
