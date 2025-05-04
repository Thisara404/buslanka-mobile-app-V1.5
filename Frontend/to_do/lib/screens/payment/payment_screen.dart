import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:to_do/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  final String journeyId;
  final double amount;
  final String journeyDetails;

  const PaymentScreen({
    Key? key,
    required this.journeyId,
    required this.amount,
    required this.journeyDetails,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = true;
  String _approveUrl = '';
  String _orderId = '';
  String _error = '';
  bool _paymentSuccess = false;
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _createPaymentOrder();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL is the return URL after payment
            if (request.url.contains('success')) {
              // Payment was successful, capture the payment
              _capturePayment();
              return NavigationDecision.prevent;
            }
            if (request.url.contains('cancel')) {
              // User canceled the payment
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_approveUrl));
  }

  Future<void> _createPaymentOrder() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final order = await _paymentService.createPaymentOrder(
        widget.journeyId,
        widget.amount,
      );

      // Extract PayPal approval URL from links
      final links = order['links'] as List;
      final approvalUrl = links.firstWhere(
        (link) => link['rel'] == 'approve',
        orElse: () => {'href': ''},
      )['href'];

      setState(() {
        _approveUrl = approvalUrl;
        _orderId = order['orderId'];
        _isLoading = false;
      });

      if (_approveUrl.isNotEmpty) {
        _initializeWebView();
      } else {
        setState(() {
          _error = 'Invalid PayPal approval URL';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _capturePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      await _paymentService.capturePayment(_orderId);

      setState(() {
        _paymentSuccess = true;
        _isLoading = false;
      });

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Successful'),
          content: const Text('Your payment has been successfully processed.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context)
                    .pop(true); // Return true to indicate success
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
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
                        onPressed: _createPaymentOrder,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Journey: ${widget.journeyDetails}'),
                          Text('Amount: \$${widget.amount.toStringAsFixed(2)}'),
                          const SizedBox(height: 16),
                          const Text(
                            'Please complete your payment with PayPal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _approveUrl.isEmpty
                          ? const Center(child: Text('Loading payment page...'))
                          : WebViewWidget(controller: _controller),
                    ),
                  ],
                ),
    );
  }
}
