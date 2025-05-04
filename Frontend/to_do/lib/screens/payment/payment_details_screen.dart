import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do/services/payment_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;

  const PaymentDetailsScreen({
    Key? key,
    required this.paymentId,
  }) : super(key: key);

  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  Map<String, dynamic> _paymentDetails = {};
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final details = await _paymentService.getPaymentDetails(widget.paymentId);

      setState(() {
        _paymentDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
        const Divider(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
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
                        onPressed: _loadPaymentDetails,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Payment Status
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _paymentDetails['status'] == 'COMPLETED'
                              ? Colors.green[100]
                              : _paymentDetails['status'] == 'FAILED'
                                  ? Colors.red[100]
                                  : _paymentDetails['status'] == 'REFUNDED'
                                      ? Colors.orange[100]
                                      : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Payment ${_paymentDetails['status'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _paymentDetails['status'] == 'COMPLETED'
                                    ? Colors.green[700]
                                    : _paymentDetails['status'] == 'FAILED'
                                        ? Colors.red[700]
                                        : _paymentDetails['status'] == 'REFUNDED'
                                            ? Colors.orange[700]
                                            : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${_paymentDetails['amount']?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${_paymentDetails['createdAt'] != null ? DateFormat('MMM d, yyyy h:mm a').format(DateTime.parse(_paymentDetails['createdAt'])) : 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Journey Details
                      if (_paymentDetails['journeyId'] != null)
                        _buildSection(
                          'Journey Details',
                          [
                            _buildDetailRow(
                              'Route:',
                              _paymentDetails['journeyId']['routeDetails']?['routeName'] ??
                                  'Unknown Route',
                            ),
                            _buildDetailRow(
                              'From:',
                              _paymentDetails['journeyId']['routeDetails']?['startLocation']?['name'] ??
                                  'Unknown',
                            ),
                            _buildDetailRow(
                              'To:',
                              _paymentDetails['journeyId']['routeDetails']?['endLocation']?['name'] ??
                                  'Unknown',
                            ),
                            _buildDetailRow(
                              'Date:',
                              _paymentDetails['journeyId']['startTime'] != null
                                  ? DateFormat('MMM d, yyyy').format(
                                      DateTime.parse(_paymentDetails['journeyId']['startTime']))
                                  : 'Unknown',
                            ),
                            _buildDetailRow(
                              'Time:',
                              _paymentDetails['journeyId']['startTime'] != null
                                  ? DateFormat('h:mm a').format(
                                      DateTime.parse(_paymentDetails['journeyId']['startTime']))
                                  : 'Unknown',
                            ),
                          ],
                        ),

                      // Transaction Details
                      if (_paymentDetails['transactionDetails'] != null)
                        _buildSection(
                          'Transaction Details',
                          [
                            _buildDetailRow(
                              'Transaction ID:',
                              _paymentDetails['transactionDetails']['captureId'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Payment Method:',
                              _paymentDetails['transactionDetails']['paymentMethod'] ?? 'PayPal',
                            ),
                            if (_paymentDetails['transactionDetails']['processorResponse'] != null)
                              _buildDetailRow(
                                'Status Code:',
                                _paymentDetails['transactionDetails']['processorResponse']['code'] ??
                                    'N/A',
                              ),
                            _buildDetailRow(
                              'Date:',
                              _paymentDetails['transactionDetails']['paymentTimestamp'] != null
                                  ? DateFormat('MMM d, yyyy h:mm a').format(
                                      DateTime.parse(
                                          _paymentDetails['transactionDetails']['paymentTimestamp']))
                                  : DateFormat('MMM d, yyyy h:mm a')
                                      .format(DateTime.parse(_paymentDetails['createdAt'])),
                            ),
                          ],
                        ),

                      // Refund Details (if applicable)
                      if (_paymentDetails['status'] == 'REFUNDED' &&
                          _paymentDetails['refundDetails'] != null)
                        _buildSection(
                          'Refund Details',
                          [
                            _buildDetailRow(
                              'Refund ID:',
                              _paymentDetails['refundDetails']['refundId'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Reason:',
                              _paymentDetails['refundDetails']['reason'] ?? 'N/A',
                            ),
                            _buildDetailRow(
                              'Amount:',
                              '\$${_paymentDetails['refundDetails']['amount']?.toStringAsFixed(2) ?? '0.00'}',
                            ),
                            _buildDetailRow(
                              'Date:',
                              _paymentDetails['refundDetails']['refundedAt'] != null
                                  ? DateFormat('MMM d, yyyy h:mm a').format(
                                      DateTime.parse(_paymentDetails['refundDetails']['refundedAt']))
                                  : 'N/A',
                            ),
                            _buildDetailRow(
                              'Status:',
                              _paymentDetails['refundDetails']['status'] ?? 'N/A',
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}