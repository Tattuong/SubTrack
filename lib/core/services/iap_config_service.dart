import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/iap_constants.dart';
import 'storage_service.dart';

enum IapConfigStatus {
  loading,
  loaded,
  networkError,
  timeout,
  parseError,
}

class IapRemoteConfig {
  final String name;
  final String id;
  final String version;
  final bool billingDisabled;
  final String code;
  final String status;
  final String message;

  const IapRemoteConfig({
    required this.name,
    required this.id,
    required this.version,
    required this.billingDisabled,
    required this.code,
    required this.status,
    required this.message,
  });

  factory IapRemoteConfig.fromJson(Map<String, dynamic> json) {
    final disable = json['disable'];
    final disabled = disable == 1 || disable == '1' || disable == true;
    return IapRemoteConfig(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      billingDisabled: disabled,
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      message: json['msg']?.toString() ?? json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
        'version': version,
        'disable': billingDisabled ? 1 : 0,
        'code': code,
        'status': status,
        'msg': message,
      };

  static IapRemoteConfig fallback() => const IapRemoteConfig(
        name: 'SubTrack',
        id: 'com.SubTrackMNG.SubTrack',
        version: '1.0.1',
        billingDisabled: false,
        code: 'FULL_IAP',
        status: 'ONLINE',
        message: 'Using cached or default config',
      );
}

class IapConfigService {
  static const _cacheKey = 'st_iap_remote_config';

  IapRemoteConfig _config = IapRemoteConfig.fallback();
  IapConfigStatus _status = IapConfigStatus.loading;

  IapRemoteConfig get config => _config;
  IapConfigStatus get status => _status;
  bool get isBillingDisabled => _config.billingDisabled;

  Future<IapRemoteConfig> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      await _loadCached();
    }

    _status = IapConfigStatus.loading;

    try {
      final response = await http
          .get(Uri.parse(IapConstants.remoteConfigUrl))
          .timeout(IapConstants.configTimeout);

      if (response.statusCode != 200) {
        _status = IapConfigStatus.networkError;
        return _config;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        _status = IapConfigStatus.parseError;
        return _config;
      }

      _config = IapRemoteConfig.fromJson(Map<String, dynamic>.from(decoded));
      _status = IapConfigStatus.loaded;
      await StorageService.instance.saveData(_cacheKey, _config.toJson());
      return _config;
    } on TimeoutException {
      _status = IapConfigStatus.timeout;
      debugPrint('IAP config fetch timeout');
    } catch (e) {
      _status = IapConfigStatus.networkError;
      debugPrint('IAP config fetch error: $e');
    }

    return _config;
  }

  Future<void> _loadCached() async {
    try {
      final cached = await StorageService.instance.getData(_cacheKey);
      if (cached != null) {
        _config = IapRemoteConfig.fromJson(cached);
        _status = IapConfigStatus.loaded;
      }
    } catch (e) {
      debugPrint('IAP config cache error: $e');
    }
  }
}
