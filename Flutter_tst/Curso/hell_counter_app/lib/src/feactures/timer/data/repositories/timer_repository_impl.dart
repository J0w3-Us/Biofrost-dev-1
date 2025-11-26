import '../../domain/repositories/timer_repository.dart';
import '../../domain/entities/ticker.dart';

class TimerRepositoryImpl implements TimerRepository {
  TimerRepositoryImpl(this._ticker);

  final Ticker _ticker;

  @override
  Stream<int> ticker() => _ticker.tick();
}
