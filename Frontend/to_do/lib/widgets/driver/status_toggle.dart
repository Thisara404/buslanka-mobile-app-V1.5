import 'package:flutter/material.dart';

enum DriverStatus { inactive, active, maintenance }

class StatusToggle extends StatelessWidget {
  final DriverStatus currentStatus;
  final Function(DriverStatus) onStatusChanged;
  final bool isLoading;

  const StatusToggle({
    Key? key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bus Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                children: [
                  _buildStatusButton(
                    context,
                    DriverStatus.inactive,
                    'Inactive',
                    Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context,
                    DriverStatus.active,
                    'Active',
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _buildStatusButton(
                    context,
                    DriverStatus.maintenance,
                    'Maintenance',
                    Colors.orange,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    DriverStatus status,
    String label,
    Color color,
  ) {
    final isSelected = currentStatus == status;

    return Expanded(
      child: OutlinedButton(
        onPressed: () => onStatusChanged(status),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : color,
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
