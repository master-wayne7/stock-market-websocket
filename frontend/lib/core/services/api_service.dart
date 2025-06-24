import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/app_constants.dart';
import '../models/candle_model.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio() {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add pretty dio logger interceptor for beautiful HTTP logs
    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  Future<List<String>> fetchAvailableSymbols() async {
    try {
      final response = await _dio.get(AppConstants.symbolsUrl);

      final List<dynamic> data = response.data;
      final symbols = data.map((symbol) => symbol.toString()).toList();

      return symbols;
    } catch (e) {
      throw ApiException('Failed to fetch symbols: $e');
    }
  }

  Future<Map<String, List<CandleModel>>> fetchAllStocksHistory() async {
    try {
      final response = await _dio.get(AppConstants.stocksHistoryUrl);

      final Map<String, dynamic> data = response.data;
      final Map<String, List<CandleModel>> result = {};

      data.forEach((symbol, candlesJson) {
        final List<dynamic> candlesList = candlesJson as List<dynamic>;
        result[symbol] = candlesList.map((candleJson) => CandleModel.fromJson(candleJson as Map<String, dynamic>)).toList();
      });

      return result;
    } catch (e) {
      throw ApiException('Failed to fetch stocks history: $e');
    }
  }

  Future<List<CandleModel>> fetchStockCandles(String symbol) async {
    try {
      final response = await _dio.get(
        AppConstants.stocksCandlesUrl,
        queryParameters: {
          'symbol': symbol
        },
      );

      final List<dynamic> data = response.data;
      final candles = data.map((candleJson) => CandleModel.fromJson(candleJson as Map<String, dynamic>)).toList();

      return candles;
    } catch (e) {
      throw ApiException('Failed to fetch candles for $symbol: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
