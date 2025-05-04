import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ETADisplay extends StatelessWidget {
  final DateTime? estimatedArrival;
  final DateTime? scheduledArrival;
  final bool isLive;
  final String? vehicleId;
  final String? busNumber;

  const ETADisplay({
    Key? key,
    required this.estimatedArrival,
    this.scheduledArrival,
    this.isLive = false,
    this.vehicleId,
    this.busNumber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (estimatedArrival == null) {
      return const Text(
        'No ETA available',
        style: TextStyle(color: Colors.grey),
      );
    }

    // Calculate delay
    final delay = scheduledArrival != null
        ? estimatedArrival!.difference(scheduledArrival!)
        : Duration.zero;

    // Format times
    final timeFormat = DateFormat('HH:mm');
    final etaFormatted = timeFormat.format(estimatedArrival!);

    // Determine color based on delay
    Color statusColor = Colors.green;
    String statusText = 'On time';

    if (delay.inMinutes > 5) {
      statusColor = Colors.red;
      statusText = '${delay.inMinutes} min late';
    } else if (delay.inMinutes > 0) {
      statusColor = Colors.orange;
      statusText = '${delay.inMinutes} min late';
    } else if (delay.inMinutes < -2) {
      statusColor = Colors.blue;
      statusText = '${-delay.inMinutes} min early';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            if (isLive) const SizedBox(width: 8),
            Text(
              etaFormatted,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (busNumber != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Bus $busNumber',
              style: const TextStyle(fontSize: 14),
            ),
          ),
      ],
    );
  }
}
