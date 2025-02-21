import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/currency_formatter.dart';

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationCard({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = notification['timestamp'] as DateTime?;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _showNotificationDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification['type'])
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification['type']),
                      color: _getNotificationColor(notification['type']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification['title'],
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (timestamp != null)
                          Text(
                            timeago.format(timestamp),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (notification['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  notification['description'],
                  style: GoogleFonts.spaceGrotesk(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'trade':
        return Colors.blue;
      case 'alert':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'trade':
        return Icons.currency_exchange;
      case 'alert':
        return Icons.notifications_active;
      case 'system':
        return Icons.system_update;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.notifications;
    }
  }

  void _showNotificationDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NotificationDetails(notification: notification),
    );
  }
}

class _NotificationDetails extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationDetails({required this.notification});

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'trade':
        return Colors.blue;
      case 'alert':
        return Colors.orange;
      case 'system':
        return Colors.purple;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'trade':
        return Icons.currency_exchange;
      case 'alert':
        return Icons.notifications_active;
      case 'system':
        return Icons.system_update;
      case 'error':
        return Icons.error_outline;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final timestamp = notification['timestamp'] as DateTime?;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification['type'])
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification['type']),
                    color: _getNotificationColor(notification['type']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          timeago.format(timestamp),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (notification['description'] != null) ...[
              Text(
                notification['description'],
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (notification['type'] == 'trade') ...[
              _buildTradeDetails(context, notification, theme, lang),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  lang.translate('close'),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeDetails(
      BuildContext context,
      Map<String, dynamic> notification,
      ThemeData theme,
      LanguageProvider lang) {
    final tradeDetails = notification['tradeDetails'] as Map<String, dynamic>?;
    if (tradeDetails == null) return const SizedBox.shrink();

    final isBuy = tradeDetails['side'] == 'buy';
    final amount =
        (tradeDetails['quantity'] as num) * (tradeDetails['price'] as num);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('trade_details'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              lang.translate('side'),
              lang.translate(isBuy ? 'buy' : 'sell'),
              theme,
              valueColor: isBuy ? Colors.green : Colors.red,
            ),
            _buildDetailRow(
              lang.translate('symbol'),
              tradeDetails['symbol'],
              theme,
            ),
            _buildDetailRow(
              lang.translate('quantity'),
              tradeDetails['quantity'].toString(),
              theme,
            ),
            _buildDetailRow(
              lang.translate('price'),
              EthiopianCurrencyFormatter.format(tradeDetails['price']),
              theme,
            ),
            _buildDetailRow(
              lang.translate('total'),
              EthiopianCurrencyFormatter.format(amount),
              theme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme,
      {Color? valueColor, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              color: valueColor,
              fontWeight: isTotal ? FontWeight.bold : null,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
