import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:libas_app/src/common/services/data_change_service.dart';

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final DataChangeService _dataChangeService = DataChangeService();
  
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  // WebSocket URL - replace with your backend URL
  static const String wsUrl = 'ws://your-backend-url.com/ws';

  // Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;
    
    _isConnecting = true;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      
      if (kDebugMode) {
        print('WebSocket connected successfully');
      }
      
      notifyListeners();
    } catch (e) {
      _isConnecting = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('WebSocket connection failed: $e');
      }
      
      _scheduleReconnect();
    }
  }

  // Handle incoming messages from server
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      
      if (kDebugMode) {
        print('Received WebSocket message: $data');
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
            print('Unknown message type: ${data['type']}');
          }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing WebSocket message: $e');
      }
    }
  }

  // Handle WebSocket errors
  void _handleError(error) {
    if (kDebugMode) {
      print('WebSocket error: $error');
    }
    _handleDisconnect();
  }

  // Handle WebSocket disconnection
  void _handleDisconnect() {
    _isConnected = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('WebSocket disconnected');
    }
    
    _scheduleReconnect();
  }

  // Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      
      if (kDebugMode) {
        print('Scheduling WebSocket reconnection attempt $_reconnectAttempts');
      }
      
      Timer(reconnectDelay, () {
        if (!_isConnected) {
          connect();
        }
      });
    } else {
      if (kDebugMode) {
        print('Max WebSocket reconnection attempts reached');
      }
    }
  }

  // Send message to server
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  // Subscribe to specific data changes
  void subscribeToChanges(List<String> dataTypes) {
    sendMessage({
      'action': 'subscribe',
      'dataTypes': dataTypes,
    });
  }

  // Unsubscribe from data changes
  void unsubscribeFromChanges(List<String> dataTypes) {
    sendMessage({
      'action': 'unsubscribe',
      'dataTypes': dataTypes,
    });
  }

  // Disconnect WebSocket
  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
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