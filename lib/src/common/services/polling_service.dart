import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:libas_app/src/common/services/data_change_service.dart';

class PollingService extends ChangeNotifier {
  static final PollingService _instance = PollingService._internal();
  factory PollingService() => _instance;
  PollingService._internal();

  Timer? _pollingTimer;
  final DataChangeService _dataChangeService = DataChangeService();
  
  bool _isPolling = false;
  Duration _pollingInterval = const Duration(seconds: 10);
  DateTime _lastUpdate = DateTime.now();

  bool get isPolling => _isPolling;

  // API endpoints - replace with your backend URLs
  static const String baseUrl = 'http://your-backend-url.com/api';
  static const String changesEndpoint = '$baseUrl/changes';

  // Start polling for changes
  void startPolling({Duration? interval}) {
    if (_isPolling) return;
    
    if (interval != null) {
      _pollingInterval = interval;
    }
    
    _isPolling = true;
    notifyListeners();
    
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _checkForChanges();
    });
    
    if (kDebugMode) {
      print('Started polling for changes every ${_pollingInterval.inSeconds} seconds');
    }
  }

  // Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    notifyListeners();
    
    if (kDebugMode) {
      print('Stopped polling for changes');
    }
  }

  // Check for changes from server
  Future<void> _checkForChanges() async {
    try {
      final response = await http.get(
        Uri.parse('$changesEndpoint?since=${_lastUpdate.toIso8601String()}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_AUTH_TOKEN', // Add your auth token
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final changes = data['changes'] as List;
        
        if (changes.isNotEmpty) {
          if (kDebugMode) {
            print('Received ${changes.length} changes from server');
          }
          
          _processChanges(changes);
          _lastUpdate = DateTime.now();
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch changes: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error polling for changes: $e');
      }
    }
  }

  // Process changes from server
  void _processChanges(List changes) {
    for (final change in changes) {
      try {
        switch (change['type']) {
          case 'category_added':
            _dataChangeService.categoryAdded(
              change['id'],
              change['data'],
            );
            break;
            
          case 'category_updated':
            _dataChangeService.categoryUpdated(
              change['id'],
              change['data'],
            );
            break;
            
          case 'category_removed':
            _dataChangeService.categoryRemoved(change['id']);
            break;
            
          case 'product_added':
            _dataChangeService.productAdded(
              change['id'],
              change['data'],
            );
            break;
            
          case 'product_updated':
            _dataChangeService.productUpdated(
              change['id'],
              change['data'],
            );
            break;
            
          case 'product_removed':
            _dataChangeService.productRemoved(change['id']);
            break;
            
          case 'banner_added':
            _dataChangeService.bannerAdded(
              change['id'],
              change['data'],
            );
            break;
            
          case 'banner_updated':
            _dataChangeService.bannerUpdated(
              change['id'],
              change['data'],
            );
            break;
            
          case 'banner_removed':
            _dataChangeService.bannerRemoved(change['id']);
            break;
            
          default:
            if (kDebugMode) {
              print('Unknown change type: ${change['type']}');
            }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing change: $e');
        }
      }
    }
  }

  // Set polling interval
  void setPollingInterval(Duration interval) {
    _pollingInterval = interval;
    
    if (_isPolling) {
      stopPolling();
      startPolling();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
} 