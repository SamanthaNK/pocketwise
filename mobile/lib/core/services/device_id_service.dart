import 'package:uuid/uuid.dart';
import '../storage/secure_storage_service.dart';

class DeviceIdService {
  DeviceIdService(this._secureStorage);

  final SecureStorageService _secureStorage;
  String? _cachedDeviceId;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final existing = await _secureStorage.readDeviceId();
    if (existing != null) {
      _cachedDeviceId = existing;
      return existing;
    }

    final newId = const Uuid().v4();
    await _secureStorage.writeDeviceId(newId);
    _cachedDeviceId = newId;
    return newId;
  }
}