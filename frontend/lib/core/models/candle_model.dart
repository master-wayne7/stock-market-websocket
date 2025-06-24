import 'package:equatable/equatable.dart';

class CandleModel extends Equatable {
  final String symbol;
  final double open;
  final double high;
  final double low;
  final double close;
  final DateTime timestamp;

  const CandleModel({
    required this.symbol,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.timestamp,
  });

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      symbol: json['symbol'] as String,
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'open': open,
      'high': high,
      'low': low,
      'close': close,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        symbol,
        open,
        high,
        low,
        close,
        timestamp
      ];
}

class BroadcastMessage extends Equatable {
  final String updateType;
  final CandleModel candle;

  const BroadcastMessage({
    required this.updateType,
    required this.candle,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    return BroadcastMessage(
      updateType: json['update_type'] as String,
      candle: CandleModel.fromJson(json['candle'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'update_type': updateType,
      'candle': candle.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        updateType,
        candle
      ];
}

enum UpdateType {
  live,
  closed;

  static UpdateType fromString(String value) {
    switch (value) {
      case 'live':
        return UpdateType.live;
      case 'closed':
        return UpdateType.closed;
      default:
        return UpdateType.live;
    }
  }
}
