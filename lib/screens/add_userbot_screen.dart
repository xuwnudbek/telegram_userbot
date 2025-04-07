import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/userbot_provider.dart';
import '../services/tdlib_service.dart';
import 'dart:convert';

class AddUserbotScreen extends StatefulWidget {
  const AddUserbotScreen({super.key});

  @override
  State<AddUserbotScreen> createState() => _AddUserbotScreenState();
}

class _AddUserbotScreenState extends State<AddUserbotScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isWaitingForCode = false;
  bool _isWaitingForPassword = false;
  String _status = '';
  final _tdlibService = TdlibService();

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _tdlibService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi userbot qo\'shish'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon raqam',
                hintText: '+998901234567',
              ),
              keyboardType: TextInputType.phone,
              enabled: !_isWaitingForCode && !_isWaitingForPassword,
            ),
            const SizedBox(height: 16),
            if (_isWaitingForCode) ...[
              TextField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'SMS kodi',
                  hintText: '12345',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
            if (_isWaitingForPassword) ...[
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '2-bosqichli parol',
                  hintText: 'Parolni kiriting',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _handleButtonPress,
              child: Text(_getButtonText()),
            ),
          ],
        ),
      ),
    );
  }

  String _getButtonText() {
    if (_isWaitingForPassword) return 'Parolni tasdiqlash';
    if (_isWaitingForCode) return 'Kodni tasdiqlash';
    return 'Telegramga kirish';
  }

  void _handleButtonPress() {
    if (_isWaitingForPassword) {
      _verifyPassword();
    } else if (_isWaitingForCode) {
      _verifyCode();
    } else {
      _requestCode();
    }
  }

  void _requestCode() async {
    if (_phoneController.text.isEmpty) {
      setState(() {
        _status = 'Iltimos, telefon raqamni kiriting';
      });
      return;
    }

    setState(() {
      _status = 'Telegram client yaratilmoqda...';
    });

    try {
      // Telegram client yaratish
      await _tdlibService.initialize();

      // Telefon raqam orqali kirish uchun so'rov
      final request = {
        '@type': 'setAuthenticationPhoneNumber',
        'phone_number': _phoneController.text,
      };

      _tdlibService.sendRequest(request);

      setState(() {
        _isWaitingForCode = true;
        _status = 'SMS kodi yuborildi. Iltimos, kuting...';
      });
    } catch (e) {
      setState(() {
        _status = 'Xatolik yuz berdi: $e';
      });
    }
  }

  void _verifyCode() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _status = 'Iltimos, SMS kodini kiriting';
      });
      return;
    }

    setState(() {
      _status = 'Kod tekshirilmoqda...';
    });

    try {
      // SMS kodini tekshirish
      final request = {
        '@type': 'checkAuthenticationCode',
        'code': _codeController.text,
      };

      _tdlibService.sendRequest(request);

      // Telegramdan javobni kutish
      while (true) {
        final response = _tdlibService.receiveResponse();
        if (response != null) {
          final responseData = json.decode(response);

          if (responseData['@type'] == 'error') {
            setState(() {
              _status = 'Xatolik: ${responseData['message']}';
            });
            return;
          }

          // Agar 2-bosqichli parol kerak bo'lsa
          if (responseData['@type'] == 'authorizationStateWaitPassword') {
            setState(() {
              _isWaitingForCode = false;
              _isWaitingForPassword = true;
              _status = '2-bosqichli parol kerak';
            });
            return;
          }

          // Agar muvaffaqiyatli bo'lsa
          if (responseData['@type'] == 'authorizationStateReady') {
            final provider = context.read<UserbotProvider>();
            provider.addUserbot(_phoneController.text);
            Navigator.of(context).pop();
            return;
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      setState(() {
        _status = 'Xatolik yuz berdi: $e';
      });
    }
  }

  void _verifyPassword() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _status = 'Iltimos, parolni kiriting';
      });
      return;
    }

    setState(() {
      _status = 'Parol tekshirilmoqda...';
    });

    try {
      // 2-bosqichli parolni tekshirish
      final request = {
        '@type': 'checkAuthenticationPassword',
        'password': _passwordController.text,
      };

      _tdlibService.sendRequest(request);

      // Telegramdan javobni kutish
      while (true) {
        final response = _tdlibService.receiveResponse();
        if (response != null) {
          final responseData = json.decode(response);

          if (responseData['@type'] == 'error') {
            setState(() {
              _status = 'Xatolik: ${responseData['message']}';
            });
            return;
          }

          // Agar muvaffaqiyatli bo'lsa
          if (responseData['@type'] == 'authorizationStateReady') {
            final provider = context.read<UserbotProvider>();
            provider.addUserbot(_phoneController.text);
            Navigator.of(context).pop();
            return;
          }
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      setState(() {
        _status = 'Xatolik yuz berdi: $e';
      });
    }
  }
}
