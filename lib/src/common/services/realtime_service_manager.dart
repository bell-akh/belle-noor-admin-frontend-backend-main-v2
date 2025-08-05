import 'package:flutter/foundation.dart';
import 'package:libas_app/src/common/services/websocket_service.dart';
import 'package:libas_app/src/common/services/sse_service.dart';
import 'package:libas_app/src/common/services/polling_service.dart';

enum RealtimeStrategy {
  websocket,
  sse,
  polling,
  none,
}

class RealtimeServiceManager extends ChangeNotifier {
  static final RealtimeServiceManager _instance = RealtimeServiceManager._internal();
  factory RealtimeServiceManager() => _instance;
  RealtimeServiceManager._internal();

  final WebSocketService _webSocketService = WebSocketService();
  final SSEService _sseService = SSEService();
  final PollingService _pollingService = PollingService();

  RealtimeStrategy _currentStrategy = RealtimeStrategy.none;
  RealtimeStrategy _preferredStrategy = RealtimeStrategy.websocket;
  bool _isConnected = false;

  RealtimeStrategy get currentStrategy => _currentStrategy;
  RealtimeStrategy get preferredStrategy => _preferredStrategy;
  bool get isConnected => _isConnected;

  // Initialize real-time connection with preferred strategy
  Future<void> initialize() async {
    await _connectWithPreferredStrategy();
  }

  // Connect using preferred strategy
  Future<void> _connectWithPreferredStrategy() async {
    switch (_preferredStrategy) {
      case RealtimeStrategy.websocket:
        await _tryWebSocket();
        break;
      case RealtimeStrategy.sse:
        await _trySSE();
        break;
      case RealtimeStrategy.polling:
        await _tryPolling();
        break;
      case RealtimeStrategy.none:
        _isConnected = false;
        notifyListeners();
        break;
    }
  }

  // Try WebSocket connection
  Future<void> _tryWebSocket() async {
    try {
      await _webSocketService.connect();
      
      if (_webSocketService.isConnected) {
        _currentStrategy = RealtimeStrategy.websocket;
        _isConnected = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('Connected using WebSocket strategy');
        }
      } else {
        await _trySSE();
      }
    } catch (e) {
      if (kDebugMode) {
        print('WebSocket failed, trying SSE: $e');
      }
      await _trySSE();
    }
  }

  // Try SSE connection
  Future<void> _trySSE() async {
    try {
      await _sseService.connect();
      
      if (_sseService.isConnected) {
        _currentStrategy = RealtimeStrategy.sse;
        _isConnected = true;
        notifyListeners();
        
        if (kDebugMode) {
          print('Connected using SSE strategy');
        }
      } else {
        await _tryPolling();
      }
    } catch (e) {
      if (kDebugMode) {
        print('SSE failed, trying polling: $e');
      }
      await _tryPolling();
    }
  }

  // Try polling connection
  Future<void> _tryPolling() async {
    try {
      _pollingService.startPolling();
      _currentStrategy = RealtimeStrategy.polling;
      _isConnected = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('Connected using polling strategy');
      }
    } catch (e) {
      if (kDebugMode) {
        print('All real-time strategies failed: $e');
      }
      _currentStrategy = RealtimeStrategy.none;
      _isConnected = false;
      notifyListeners();
    }
  }

  // Set preferred strategy
  void setPreferredStrategy(RealtimeStrategy strategy) {
    _preferredStrategy = strategy;
    
    if (_isConnected) {
      disconnect();
      initialize();
    }
  }

  // Subscribe to specific data changes
  void subscribeToChanges(List<String> dataTypes) {
    switch (_currentStrategy) {
      case RealtimeStrategy.websocket:
        _webSocketService.subscribeToChanges(dataTypes);
        break;
      case RealtimeStrategy.sse:
        // SSE doesn't support subscriptions, it streams all changes
        break;
      case RealtimeStrategy.polling:
        // Polling automatically checks for all changes
        break;
      case RealtimeStrategy.none:
        break;
    }
  }

  // Unsubscribe from data changes
  void unsubscribeFromChanges(List<String> dataTypes) {
    switch (_currentStrategy) {
      case RealtimeStrategy.websocket:
        _webSocketService.unsubscribeFromChanges(dataTypes);
        break;
      case RealtimeStrategy.sse:
        // SSE doesn't support unsubscriptions
        break;
      case RealtimeStrategy.polling:
        // Polling automatically checks for all changes
        break;
      case RealtimeStrategy.none:
        break;
    }
  }

  // Disconnect all services
  void disconnect() {
    _webSocketService.disconnect();
    _sseService.disconnect();
    _pollingService.stopPolling();
    
    _currentStrategy = RealtimeStrategy.none;
    _isConnected = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('Disconnected from all real-time services');
    }
  }

  // Get connection status for each strategy
  Map<RealtimeStrategy, bool> getConnectionStatus() {
    return {
      RealtimeStrategy.websocket: _webSocketService.isConnected,
      RealtimeStrategy.sse: _sseService.isConnected,
      RealtimeStrategy.polling: _pollingService.isPolling,
      RealtimeStrategy.none: false,
    };
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 