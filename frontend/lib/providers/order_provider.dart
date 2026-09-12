import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<OrderModel> _myOrders = [];
  List<dynamic> _mySales = [];
  bool _isLoadingOrders = false;
  bool _isLoadingSales = false;

  List<OrderModel> get myOrders => _myOrders;
  List<dynamic> get mySales => _mySales;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingSales => _isLoadingSales;

  Future<void> fetchMyOrders() async {
    _isLoadingOrders = true;
    notifyListeners();

    final res = await ApiService.get(ApiConstants.myOrders);
    _isLoadingOrders = false;

    if (res.success && res.data != null && res.data['orders'] != null) {
      _myOrders = (res.data['orders'] as List)
          .map((o) => OrderModel.fromJson(o))
          .toList();
      notifyListeners();
    }
  }

  Future<void> fetchMySales() async {
    _isLoadingSales = true;
    notifyListeners();

    final res = await ApiService.get(ApiConstants.mySales);
    _isLoadingSales = false;

    if (res.success && res.data != null && res.data['sales'] != null) {
      _mySales = res.data['sales'] as List;
      notifyListeners();
    }
  }
}
