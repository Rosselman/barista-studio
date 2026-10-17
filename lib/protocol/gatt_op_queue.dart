import 'dart:async';
import 'dart:collection';

typedef GattTask = Future<bool> Function();

/// Sequential FIFO Queue for BLE GATT Operations
/// Prevents concurrent BLE read/write collisions and ensures deterministic execution.
class GattOpQueue {
  final Queue<_QueuedOp> _queue = Queue<_QueuedOp>();
  bool _isProcessing = false;
  static const Duration opTimeout = Duration(milliseconds: 3500);
  static const Duration settlingDelay = Duration(milliseconds: 45);

  /// Enqueues an async GATT operation with callback and timeout
  Future<bool> enqueue(GattTask task, {String description = 'GATT Op'}) {
    final completer = Completer<bool>();
    _queue.add(_QueuedOp(task, completer, description));
    _processNext();
    return completer.future;
  }

  void _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final op = _queue.removeFirst();
    bool result = false;

    try {
      result = await op.task().timeout(
        opTimeout,
        onTimeout: () {
          print('[GattOpQueue] Operation timed out: ${op.description}');
          return false;
        },
      );
    } catch (e) {
      print('[GattOpQueue] Error executing ${op.description}: $e');
      result = false;
    } finally {
      if (!op.completer.isCompleted) {
        op.completer.complete(result);
      }
      // Brief settling delay before starting next operation
      await Future.delayed(settlingDelay);
      _isProcessing = false;
      _processNext();
    }
  }

  /// Cancels all pending operations (e.g. on disconnect)
  void clear() {
    while (_queue.isNotEmpty) {
      final op = _queue.removeFirst();
      if (!op.completer.isCompleted) {
        op.completer.complete(false);
      }
    }
    _isProcessing = false;
  }

  int get length => _queue.length;
  bool get isEmpty => _queue.isEmpty;
}

class _QueuedOp {
  final GattTask task;
  final Completer<bool> completer;
  final String description;

  _QueuedOp(this.task, this.completer, this.description);
}
