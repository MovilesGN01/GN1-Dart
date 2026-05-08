import 'dart:collection';

/// Thread-safe by design: Dart isolates are
/// single-threaded, no mutex needed.
/// Capacity 50 covers ~5-10 origin/destination
/// combinations per session (~100 KB max).
class LRUCache<K, V> {
  LRUCache({this.capacity = 50});

  final int capacity;
  final LinkedHashMap<K, V> _map = LinkedHashMap();

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void invalidate(K key) => _map.remove(key);
  void invalidateAll() => _map.clear();
  int get size => _map.length;
}