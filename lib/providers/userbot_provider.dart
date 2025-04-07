import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Userbot {
  final String phoneNumber;
  final String status;
  final DateTime lastActive;
  final bool isWaitingForCode;
  final String? verificationCode;
  final bool isAuthenticated;

  Userbot({
    required this.phoneNumber,
    required this.status,
    required this.lastActive,
    this.isWaitingForCode = false,
    this.verificationCode,
    this.isAuthenticated = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'status': status,
      'lastActive': lastActive.toIso8601String(),
      'isWaitingForCode': isWaitingForCode,
      'verificationCode': verificationCode,
      'isAuthenticated': isAuthenticated,
    };
  }

  factory Userbot.fromJson(Map<String, dynamic> json) {
    return Userbot(
      phoneNumber: json['phoneNumber'],
      status: json['status'],
      lastActive: DateTime.parse(json['lastActive']),
      isWaitingForCode: json['isWaitingForCode'] ?? false,
      verificationCode: json['verificationCode'],
      isAuthenticated: json['isAuthenticated'] ?? false,
    );
  }
}

class UserbotProvider with ChangeNotifier {
  List<Userbot> _userbots = [];
  final SharedPreferences _prefs;

  UserbotProvider(this._prefs) {
    _loadUserbots();
  }

  List<Userbot> get userbots => _userbots;

  Future<void> _loadUserbots() async {
    final userbotsJson = _prefs.getStringList('userbots') ?? [];
    _userbots = userbotsJson.map((json) => Userbot.fromJson(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> _saveUserbots() async {
    final userbotsJson = _userbots.map((userbot) => jsonEncode(userbot.toJson())).toList();
    await _prefs.setStringList('userbots', userbotsJson);
  }

  Future<void> addUserbot(String phoneNumber) async {
    _userbots.add(Userbot(
      phoneNumber: phoneNumber,
      status: 'Telegramga kirish kutilmoqda',
      lastActive: DateTime.now(),
      isWaitingForCode: false,
    ));
    await _saveUserbots();
    notifyListeners();
  }

  Future<void> requestAuthCode(int index) async {
    if (index >= 0 && index < _userbots.length) {
      _userbots[index] = Userbot(
        phoneNumber: _userbots[index].phoneNumber,
        status: 'SMS kodi kutilmoqda',
        lastActive: DateTime.now(),
        isWaitingForCode: true,
        isAuthenticated: false,
      );
      await _saveUserbots();
      notifyListeners();
    }
  }

  Future<void> verifyUserbot(int index, String code) async {
    if (index >= 0 && index < _userbots.length) {
      _userbots[index] = Userbot(
        phoneNumber: _userbots[index].phoneNumber,
        status: 'Aktiv',
        lastActive: DateTime.now(),
        isWaitingForCode: false,
        verificationCode: code,
        isAuthenticated: true,
      );
      await _saveUserbots();
      notifyListeners();
    }
  }

  Future<void> editUserbot(int index, String newPhoneNumber) async {
    if (index >= 0 && index < _userbots.length) {
      _userbots[index] = Userbot(
        phoneNumber: newPhoneNumber,
        status: _userbots[index].status,
        lastActive: _userbots[index].lastActive,
        isWaitingForCode: _userbots[index].isWaitingForCode,
        verificationCode: _userbots[index].verificationCode,
        isAuthenticated: _userbots[index].isAuthenticated,
      );
      await _saveUserbots();
      notifyListeners();
    }
  }

  Future<void> deleteUserbot(int index) async {
    if (index >= 0 && index < _userbots.length) {
      _userbots.removeAt(index);
      await _saveUserbots();
      notifyListeners();
    }
  }

  Future<void> updateUserbotStatus(int index, String status) async {
    if (index >= 0 && index < _userbots.length) {
      _userbots[index] = Userbot(
        phoneNumber: _userbots[index].phoneNumber,
        status: status,
        lastActive: DateTime.now(),
        isWaitingForCode: _userbots[index].isWaitingForCode,
        verificationCode: _userbots[index].verificationCode,
        isAuthenticated: _userbots[index].isAuthenticated,
      );
      await _saveUserbots();
      notifyListeners();
    }
  }
}
