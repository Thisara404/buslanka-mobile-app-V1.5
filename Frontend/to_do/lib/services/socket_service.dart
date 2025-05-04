import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do/config/config.dart';

class SocketService {
  static IO.Socket? _socket;
  static final Map<String, List<Function>> _listeners = {};
  static bool _isConnected = false;

  // Initialize and connect to socket server
  static Future<void> initSocket() async {
    try {
      if (_socket != null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.tokenKey);

      _socket = IO.io(ApiConfig.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'auth': {'token': token}
      });

      _socket!.connect();
      _socket!.on('connect', (_) => print('Socket connected'));
      _socket!.on('error', (error) => print('Socket error: $error'));
    } catch (e) {
      print('Socket initialization error: $e');
    }
  }

  // Setup basic socket listeners
  static void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('Socket connected');
      _isConnected = true;
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
      _isConnected = false;
    });

    _socket?.onError((error) {
      print('Socket error: $error');
    });
  }

  // Check if socket is connected
  static bool isConnected() {
    return _isConnected && _socket?.connected == true;
  }

  // Subscribe to route updates
  static void subscribeToRoute(String routeId) {
    if (!isConnected() || _socket == null) return;
    print('Subscribing to route: $routeId');

    _socket!.emit('route:subscribe', {'routeId': routeId});

    _socket!.on('route:subscribed', (data) {
      print('Subscribed to route: $data');
    });
  }

  // static void unsubscribeFromRoute(String routeId) {}
  static void unsubscribeFromRoute(String routeId) {
    if (!isConnected() || _socket == null) return;
    print('Unsubscribing from route: $routeId');

    _socket!.emit('route:unsubscribe', {'routeId': routeId});

    // Remove the route:subscribed listener
    _socket!.off('route:subscribed');
  }

  // Subscribe to schedule updates
  static void subscribeToSchedule(String scheduleId) {
    if (!isConnected() || _socket == null) return;

    _socket!.emit('schedule:subscribe', {'scheduleId': scheduleId});
  }

  // Start vehicle location tracking (for drivers only)
  static void startVehicleTracking(String vehicleId) {
    if (!isConnected() || _socket == null) return;

    _socket!.emit('vehicle:tracking:start', {'vehicleId': vehicleId});
  }

  // Stop vehicle location tracking (for drivers only)
  static void stopVehicleTracking(String vehicleId) {
    if (!isConnected() || _socket == null) return;

    _socket!.emit('vehicle:tracking:stop', {'vehicleId': vehicleId});
  }

  // Send vehicle location update (for drivers only)
  static void sendVehicleLocation(
      String vehicleId, double latitude, double longitude) {
    if (!isConnected() || _socket == null) return;

    _socket!.emit('vehicle:location:update', {
      'vehicleId': vehicleId,
      'location': {
        'type': 'Point',
        'coordinates': [
          longitude,
          latitude
        ], // Using [longitude, latitude] format to match backend
        'timestamp': DateTime.now().toIso8601String(),
      },
      // Optional metadata for better tracking
      'speed': 0.0, // Default or could be calculated from previous positions
      'heading': 0.0, // Default or calculated as direction of travel
    });
  }

  // Add event listener
  static void addListener(String event, Function callback) {
    if (_listeners[event] == null) {
      _listeners[event] = [];

      // Register the event with socket.io if this is the first listener
      _socket?.on(event, (data) {
        final listeners = _listeners[event];
        if (listeners != null) {
          for (var listener in listeners) {
            listener(data);
          }
        }
      });
    }

    _listeners[event]?.add(callback);
  }

  // Remove event listener
  static void removeListener(String event, [Function? callback]) {
    if (callback == null) {
      _listeners.remove(event);
      _socket?.off(event);
    } else if (_listeners.containsKey(event)) {
      _listeners[event]?.remove(callback);

      // If no more listeners for this event, unregister it
      if (_listeners[event]?.isEmpty == true) {
        _listeners.remove(event);
        _socket?.off(event);
      }
    }
  }

  // Disconnect socket
  static void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _listeners.clear();
  }
}
