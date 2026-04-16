import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/models/event_model.dart';

final activeEventsProvider = FutureProvider.autoDispose<List<EventModel>>(
  (ref) async {
    final data = await ApiClient.get<List<dynamic>>(ApiEndpoints.activeEvents);
    return data
        .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
        .toList();
  },
);
