import 'dart:async';
import 'dart:math';

class MarketItem {
  final String symbol;
  final String name;
  final double price;
  final double changePercent;
  final bool isUp;

  const MarketItem({
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.isUp,
  });

  MarketItem copyWith({double? price, double? changePercent, bool? isUp}) {
    return MarketItem(
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      isUp: isUp ?? this.isUp,
    );
  }
}

class MarketDataService {
  MarketDataService._internal();
  static final MarketDataService _instance = MarketDataService._internal();
  factory MarketDataService() => _instance;

  final _random = Random();
  late final StreamController<List<MarketItem>> _controller;
  Timer? _driftTimer;

  List<MarketItem> _items = [
    const MarketItem(symbol: 'NIFTY 50',  name: 'NSE India',       price: 26823.50, changePercent:  1.24, isUp: true),
    const MarketItem(symbol: 'SENSEX',    name: 'BSE India',       price: 87910.25, changePercent:  0.95, isUp: true),
    const MarketItem(symbol: 'NASDAQ',    name: 'US Tech',         price: 23440.50, changePercent: -0.34, isUp: false),
    const MarketItem(symbol: 'S&P 500',   name: 'US Market',       price:  5862.75, changePercent:  0.72, isUp: true),
    const MarketItem(symbol: 'BTC/USD',   name: 'Bitcoin',         price: 67842.00, changePercent:  2.15, isUp: true),
    const MarketItem(symbol: 'GOLD',      name: 'Gold ₹/10g',      price: 78450.00, changePercent:  0.45, isUp: true),
    const MarketItem(symbol: 'USD/INR',   name: 'Dollar Rupee',    price:    83.42, changePercent: -0.12, isUp: false),
  ];

  bool _initialized = false;

  Stream<List<MarketItem>> get stream {
    _ensureInitialized();
    return _controller.stream;
  }

  List<MarketItem> get currentItems => List.unmodifiable(_items);

  void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _controller = StreamController<List<MarketItem>>.broadcast();
    _controller.add(List.unmodifiable(_items));
    _startDrift();
  }

  void _startDrift() {
    _driftTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _items = _items.map((item) {
        final driftFactor = 1.0 + (_random.nextDouble() * 0.006 - 0.003);
        final newPrice = item.price * driftFactor;
        final delta = newPrice - item.price;
        final newChange = item.changePercent + (delta / item.price * 100);
        final isUp = delta >= 0;
        return item.copyWith(
          price: newPrice,
          changePercent: double.parse(newChange.toStringAsFixed(2)),
          isUp: isUp,
        );
      }).toList();

      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(_items));
      }
    });
  }

  void dispose() {
    _driftTimer?.cancel();
    _driftTimer = null;
    if (_initialized && !_controller.isClosed) {
      _controller.close();
    }
    _initialized = false;
  }
}
