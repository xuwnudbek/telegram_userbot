import 'package:flutter/foundation.dart';
import '../services/tdlib_service.dart';

class TelegramProvider with ChangeNotifier {
  final TdlibService _tdlib = TdlibService();
  List<String> phoneNumbers = [];

  bool get isInitialized => _tdlib.isInitialized;

  Future<void> initialize() async {
    try {
      await _tdlib.initialize();
      notifyListeners();
    } catch (e) {
      debugPrint('TDlib initialization error: $e');
    }
  }

  Future<void> importPhoneNumbers(List<String> numbers) async {
    phoneNumbers.addAll(numbers);
    notifyListeners();
  }

  void editPhoneNumber(int index, String newNumber) {
    if (index >= 0 && index < phoneNumbers.length) {
      phoneNumbers[index] = newNumber;
      notifyListeners();
    }
  }

  void deletePhoneNumber(int index) {
    if (index >= 0 && index < phoneNumbers.length) {
      phoneNumbers.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> joinChannel(String channelUsername) async {
    if (!isInitialized) {
      await initialize();
    }

    final request = {'@type': 'joinChatByInviteLink', 'invite_link': 'https://t.me/$channelUsername'};
    _tdlib.sendRequest(request);

    // Wait for response
    final response = _tdlib.receiveResponse();
    if (response != null) {
      debugPrint('Channel join response: $response');
    }
  }

  Future<void> joinGroup(String groupUsername) async {
    if (!isInitialized) {
      await initialize();
    }

    final request = {'@type': 'joinChatByInviteLink', 'invite_link': 'https://t.me/$groupUsername'};
    _tdlib.sendRequest(request);

    // Wait for response
    final response = _tdlib.receiveResponse();
    if (response != null) {
      debugPrint('Group join response: $response');
    }
  }

  @override
  void dispose() {
    _tdlib.dispose();
    super.dispose();
  }
}
