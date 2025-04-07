import 'dart:ffi';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

class TdlibService {
  DynamicLibrary? _lib;
  Pointer<Void>? _client;
  bool _isInitialized = false;
  bool _isParametersSet = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized && !_isDisposed;

  Future<void> initialize() async {
    if (_isDisposed) {
      throw Exception('TdlibService already disposed');
    }

    try {
      _lib = DynamicLibrary.open('libtdjson.so');
      final createClient = _lib!.lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>('td_json_client_create');
      _client = createClient();
      _isInitialized = true;

      // Telegram parametrlarini sozlash
      final params = {
        '@type': 'setTdlibParameters',
        'parameters': {
          'use_test_dc': false,
          'database_directory': 'tdlib',
          'files_directory': 'tdlib',
          'use_file_database': true,
          'use_chat_info_database': true,
          'use_message_database': true,
          'use_secret_chats': true,
          'api_id': 7564972,
          'api_hash': '1dddd8bc417dc3e188bc07f68fe44e83',
          'system_language_code': 'en',
          'device_model': 'Android',
          'system_version': '1.0',
          'application_version': '1.0',
          'enable_storage_optimizer': true,
        }
      };

      sendRequest(params);

      // Update'larni tinglash
      int attempts = 0;
      const maxAttempts = 10;

      while (attempts < maxAttempts && !_isDisposed) {
        final response = receiveResponse();
        if (response != null) {
          final responseData = json.decode(response);
          debugPrint('TDLib response: $responseData');

          if (responseData['@type'] == 'updateAuthorizationState') {
            final state = responseData['authorization_state'];
            if (state['@type'] == 'authorizationStateReady') {
              debugPrint('TDLib is ready');
              return;
            } else if (state['@type'] == 'authorizationStateWaitTdlibParameters') {
              if (!_isParametersSet) {
                sendRequest(params);
                _isParametersSet = true;
              }
            }
          } else if (responseData['@type'] == 'error') {
            debugPrint('TDLib error: ${responseData['message']}');
            throw Exception(responseData['message']);
          }
        }

        attempts++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!_isDisposed) {
        throw Exception('TDLib initialization timeout');
      }
    } catch (e) {
      debugPrint('TdlibService initialize error: $e');
      await dispose();
      rethrow;
    }
  }

  void sendRequest(Map<String, dynamic> request) {
    if (!isInitialized || _client == null || _lib == null) {
      throw Exception('TdlibService not initialized');
    }

    final send = _lib!.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('td_json_client_send');

    final requestJson = json.encode(request);
    final requestPtr = requestJson.toNativeUtf8();
    try {
      if (requestPtr != nullptr) {
        send(_client!, requestPtr);
      }
    } finally {
      if (requestPtr != nullptr) {
        malloc.free(requestPtr);
      }
    }
  }

  String? receiveResponse() {
    if (!isInitialized || _client == null || _lib == null) {
      throw Exception('TdlibService not initialized');
    }

    final receive = _lib!.lookupFunction<Pointer<Utf8> Function(Pointer<Void>, Double), Pointer<Utf8> Function(Pointer<Void>, double)>('td_json_client_receive');

    final responsePtr = receive(_client!, 1.0);
    if (responsePtr == nullptr) {
      return null;
    }

    try {
      if (responsePtr != nullptr) {
        final response = responsePtr.toDartString();
        return response;
      }
      return null;
    } finally {
      if (responsePtr != nullptr) {
        malloc.free(responsePtr);
      }
    }
  }

  Future<void> dispose() async {
    if (!_isDisposed) {
      _isDisposed = true;
      _isInitialized = false;
      _isParametersSet = false;

      if (_client != null) {
        try {
          final destroy = _lib?.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('td_json_client_destroy');
          if (destroy != null) {
            destroy(_client!);
          }
        } catch (e) {
          debugPrint('Error destroying TDLib client: $e');
        } finally {
          _client = null;
        }
      }

      _lib = null;
    }
  }
}
