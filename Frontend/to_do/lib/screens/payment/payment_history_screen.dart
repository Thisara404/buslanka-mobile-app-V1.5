import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do/services/payment_service.dart';
import 'package:to_do/screens/payment/payment_details_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  List<dynamic> _payments = [];
  String _error = '';
  int _currentPage = 1;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments({bool refresh = false}) async {
    try {
      setState(() {
        if (refresh) {
          _currentPage = 1;
          _payments = [];
        }
        _isLoading = true;
        _error = '';
      });

      final payments = await _paymentService.getPaymentHistory(
        page: _currentPage,
        limit: 10,
      );

      setState(() {
        if (refresh) {
          _payments = payments;
        } else {
          _payments.addAll(payments);
        }
        _hasMorePages = payments.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _loadMorePayments() {
    if (_hasMorePages && !_isLoading) {
      _currentPage++;
      _loadPayments();
    }
  }

  String _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return 'green';
      case 'FAILED':
        return 'red';
      case 'REFUNDED':
        return 'orange';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: _error.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_error',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _loadPayments(refresh: true),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadPayments(refresh: true),
              child: _payments.isEmpty && !_isLoading
                  ? const Center(
                      child: Text('No payment records found'),
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent) {
                          _loadMorePayments();
                        }
                        return true;
                      },
                      child: ListView.builder(
                        itemCount:
                            _payments.length + (_isLoading && _currentPage > 1 ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _payments.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final payment = _payments[index];
                          final journeyDetails = payment['journeyId'] != null
                              ? '${payment['journeyId']['routeDetails']?['routeName'] ?? 'Unknown Route'}'
                              : 'Unknown Journey';
                          final paymentDate = payment['createdAt'] != null
                              ? DateFormat('MMM d, yyyy').format(
                                  DateTime.parse(payment['createdAt']))
                              : 'Unknown date';
                          final paymentStatus = payment['status'] ?? 'PENDING';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(journeyDetails),
                              subtitle: Text('Date: $paymentDate'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${payment['amount'].toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    paymentStatus,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PaymentDetailsScreen(
                                      paymentId: payment['_id'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
      floatingActionButton: _currentPage > 1
          ? FloatingActionButton(
              onPressed: () {
                // Scroll to top
                _loadPayments(refresh: true);
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }
}