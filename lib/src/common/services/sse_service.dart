import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:libas_app/src/common/services/data_change_service.dart';

class SSEService extends ChangeNotifier {
  static final SSEService _instance = SSEService._internal();
  factory SSEService() => _instance;
  SSEService._internal();

  StreamSubscription? _subscription;
  final DataChangeService _dataChangeService = DataChangeService();
  
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // SSE URL - replace with your backend URL
  static const String sseUrl = 'http://your-backend-url.com/events';

  // Connect to SSE endpoint
  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    notifyListeners();

    try {
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';

      final response = await http.Client().send(request);
      
      if (response.statusCode == 200) {
        _subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              _handleSSEMessage,
              onError: _handleError,
              onDone: _handleDisconnect,
            );

        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        
        if (kDebugMode) {
          print('SSE connected successfully');
        }
        
        notifyListeners();
      } else {
        throw Exception('SSE connection failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('SSE connection failed: $e');
      }
      
      _scheduleReconnect();
    }
  }

  // Handle SSE messages
  void _handleSSEMessage(String message) {
    if (message.isEmpty || message.startsWith(':')) return;

    try {
      if (message.startsWith('data: ')) {
        final data = jsonDecode(message.substring(6));
        
        if (kDebugMode) {
          print('Received SSE message: $data');
        }

        // Handle different types of real-time updates
        switch (data['type']) {
          case 'category_added':
            _dataChangeService.categoryAdded(
              data['id'],
              data['data'],
            );
            break;
            
          case 'category_updated':
            _dataChangeService.categoryUpdated(
              data['id'],
              data['data'],
            );
            break;
            
          case 'category_removed':
            _dataChangeService.categoryRemoved(data['id']);
            break;
            
          case 'product_added':
            _dataChangeService.productAdded(
              data['id'],
              data['data'],
            );
            break;
            
          case 'product_updated':
            _dataChangeService.productUpdated(
              data['id'],
              data['data'],
            );
            break;
            
          case 'product_removed':
            _dataChangeService.productRemoved(data['id']);
            break;
            
          case 'banner_added':
            _dataChangeService.bannerAdded(
              data['id'],
              data['data'],
            );
            break;
            
          case 'banner_updated':
            _dataChangeService.bannerUpdated(
              data['id'],
              data['data'],
            );
            break;
            
          case 'banner_removed':
            _dataChangeService.bannerRemoved(data['id']);
            break;
            
          default:
            if (kDebugMode) {
              print('Unknown SSE message type: ${data['type']}');
            }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing SSE message: $e');
      }
    }
  }

  // Handle SSE errors
  void _handleError(error) {
    if (kDebugMode) {
      print('SSE error: $error');
    }
    _handleDisconnect();
  }

  // Handle SSE disconnection
  void _handleDisconnect() {
    _isConnected = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('SSE disconnected');
    }
    
    _scheduleReconnect();
  }

  // Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      
      if (kDebugMode) {
        print('Scheduling SSE reconnection attempt $_reconnectAttempts');
      }
      
      Timer(reconnectDelay, () {
        if (!_isConnected) {
          connect();
        }
      });
    } else {
      if (kDebugMode) {
        print('Max SSE reconnection attempts reached');
      }
    }
  }

  // Disconnect SSE
  void disconnect() {
    _subscription?.cancel();
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 