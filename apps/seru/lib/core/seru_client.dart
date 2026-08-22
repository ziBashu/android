import 'package:zibashu_core/zibashu_core.dart';

import 'models.dart';
import 'pay_code.dart';

/// Thin Sanctum client for `/api/mobile/*`. Never wraps the website.
class SeruClient {
  SeruClient(this.api);

  final ApiClient api;

  Future<Result<List<SeruPeer>>> friends() async {
    final result = await api.get('/api/mobile/seru/friends');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad friends payload');
        final list = body['friends'];
        if (list is! List) return const Ok(<SeruPeer>[]);
        return Ok(list.whereType<Map>().map(SeruPeer.fromJson).toList());
      },
      err: Err.new,
    );
  }

  Future<Result<List<SeruPeer>>> search(String q) async {
    final result = await api.get('/api/mobile/seru/search', query: {'q': q});
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad search payload');
        final list = body['results'];
        if (list is! List) return const Ok(<SeruPeer>[]);
        return Ok(list.whereType<Map>().map(SeruPeer.fromJson).toList());
      },
      err: Err.new,
    );
  }

  Future<Result<Map<String, dynamic>>> requests() async {
    final result = await api.get('/api/mobile/seru/requests');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad requests payload');
        return Ok(Map<String, dynamic>.from(body));
      },
      err: Err.new,
    );
  }

  Future<Result<String>> relationship(int userId) async {
    final result = await api.get('/api/mobile/seru/relationship/$userId');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad relationship');
        return Ok(body['state']?.toString() ?? 'none');
      },
      err: Err.new,
    );
  }

  Future<Result<void>> requestConnect(int userId, {String? intro}) async {
    final result = await api.post(
      '/api/mobile/seru/requests/$userId',
      data: {if (intro != null) 'intro': intro},
    );
    return _ok(result);
  }

  Future<Result<void>> respond(int userId, String decision) async {
    final result = await api.post(
      '/api/mobile/seru/requests/$userId/respond',
      data: {'decision': decision},
    );
    return _ok(result);
  }

  Future<Result<void>> block(int userId) async {
    final result = await api.post('/api/mobile/seru/block/$userId');
    return _ok(result);
  }

  Future<Result<void>> sendEnvelope({
    required int receiverId,
    required String clientId,
    required String body,
  }) async {
    final result = await api.post(
      '/api/mobile/seru/messages',
      data: {
        'receiver_id': receiverId,
        'client_id': clientId,
        'body': body,
      },
    );
    return _ok(result);
  }

  Future<Result<List<ThreadCard>>> threads() async {
    final result = await api.get('/api/mobile/threads');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad thread payload');
        final list = body['threads'];
        if (list is! List) return const Ok(<ThreadCard>[]);
        return Ok(list.whereType<Map>().map(ThreadCard.fromJson).toList());
      },
      err: Err.new,
    );
  }

  Future<Result<ZibaAssets>> assets() async {
    final result = await api.get('/api/mobile/ziba/assets');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map) return const Err('Bad assets payload');
        String? code;
        final pc = body['pay_code'];
        if (pc is Map) code = pc['code']?.toString();
        return Ok(ZibaAssets(
          balance: body['balance']?.toString() ?? '0.00000000',
          payCode: code,
          locked: body['locked'] == true,
        ));
      },
      err: Err.new,
    );
  }

  Future<Result<ZibaPayPayload>> createPayCode({String? amount}) async {
    final result = await api.post(
      '/api/mobile/ziba/pay-codes',
      data: {if (amount != null && amount.isNotEmpty) 'amount': amount},
    );
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map || body['ok'] != true) {
          return Err(body is Map ? (body['message']?.toString() ?? 'Could not issue code') : 'Could not issue code');
        }
        final pc = body['pay_code'];
        if (pc is! Map) return const Err('No pay code');
        final parsed = ZibaPayCodes.parse(pc['code']?.toString() ?? '');
        if (parsed == null) return const Err('Bad pay code');
        return Ok(ZibaPayPayload(
          code: parsed.code,
          amount: pc['amount']?.toString(),
          uri: pc['uri']?.toString(),
        ));
      },
      err: Err.new,
    );
  }

  Future<Result<ZibaPayPayload>> lookupPayCode(String code) async {
    final parsed = ZibaPayCodes.parse(code);
    if (parsed == null) return const Err('That is not a ZIBA pay code.');
    final result = await api.get('/api/mobile/ziba/pay-codes/${parsed.code}');
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map || body['ok'] != true) {
          return Err(body is Map ? (body['message']?.toString() ?? 'Unknown code') : 'Unknown code');
        }
        final pc = body['pay_code'];
        if (pc is! Map) return const Err('No pay code');
        return Ok(ZibaPayPayload(
          code: pc['code']?.toString() ?? parsed.code,
          amount: pc['amount']?.toString(),
          uri: pc['uri']?.toString(),
        ));
      },
      err: Err.new,
    );
  }

  Future<Result<String>> pay(PayIntent intent) async {
    final result = await api.post(
      '/api/mobile/ziba/pay-codes/${intent.code}/pay',
      data: {'amount': intent.amount},
    );
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is! Map || body['ok'] != true) {
          return Err(body is Map ? (body['message']?.toString() ?? 'Pay failed') : 'Pay failed');
        }
        return Ok(body['amount']?.toString() ?? intent.amount);
      },
      err: Err.new,
    );
  }

  Result<void> _ok(Result<dynamic> result) {
    return result.when(
      ok: (res) {
        final body = res.data;
        if (body is Map && body['ok'] == false) {
          return Err(body['message']?.toString() ?? body['error']?.toString() ?? 'Request failed');
        }
        final status = res.statusCode ?? 0;
        if (status >= 400) {
          if (body is Map) {
            return Err(body['message']?.toString() ?? body['error']?.toString() ?? 'HTTP $status');
          }
          return Err('HTTP $status');
        }
        return const Ok(null);
      },
      err: Err.new,
    );
  }
}
