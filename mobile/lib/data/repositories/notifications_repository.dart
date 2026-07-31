import '../../core/services/network/api_client.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as String,
        type: j['type'] as String? ?? 'info',
        title: j['title'] as String,
        body: j['body'] as String? ?? '',
        read: j['read'] as bool? ?? false,
      );
}

class NotificationsRepository {
  NotificationsRepository(this._client);

  final ApiClient _client;

  Future<List<NotificationItem>> getAll() async {
    final res = await _client.dio.get('/notifications');
    return (res.data as List)
        .map((j) => NotificationItem.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) async {
    await _client.dio.patch('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.dio.post('/notifications/read-all');
  }
}
