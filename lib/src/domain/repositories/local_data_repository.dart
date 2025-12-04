import 'package:shared_preferences/shared_preferences.dart';

abstract class _LocalDataRepository {
  Future<void> initialize();

  Future<void> set<T>(String key, T value);

  T? get<T>(String key);

  Future<void> clear();
}

class LocalDataRepository implements _LocalDataRepository {
  static SharedPreferences? _prefs;

  static LocalDataRepository instance = LocalDataRepository._();

  LocalDataRepository._();

  @override
  T? get<T>(String key) {
    if (T == String) {
      return _prefs?.getString(key) as T?;
    } else if (T == int) {
      return _prefs?.getInt(key) as T?;
    } else if (T == double) {
      return _prefs?.getDouble(key) as T?;
    } else if (T == bool) {
      return _prefs?.getBool(key) as T?;
    } else if (T == List<String>) {
      return _prefs?.getStringList(key) as T?;
    }

    return null;
  }

  @override
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    print(_prefs?.getKeys());
  }

  @override
  Future<void> set<T>(String key, T value) async {
    if (T == String) {
      bool? a = await _prefs?.setString(key, value as String);
      print("data saved $key $a");
    } else if (T == int) {
      await _prefs?.setInt(key, value as int);
    } else if (T == double) {
      await _prefs?.setDouble(key, value as double);
    } else if (T == bool) {
      await _prefs?.setBool(key, value as bool);
    } else if (T == List<String>) {
      await _prefs?.setStringList(key, value as List<String>);
    }
  }

  @override
  Future<void> clear() async {
    await _prefs?.clear();
  }
}
