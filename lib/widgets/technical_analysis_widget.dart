import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class TechnicalAnalysisWidget extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const TechnicalAnalysisWidget({
    super.key,
    required this.stockData,
  });

  @override
  State<TechnicalAnalysisWidget> createState() =>
      _TechnicalAnalysisWidgetState();
}

class _TechnicalAnalysisWidgetState extends State<TechnicalAnalysisWidget> {
  String _selectedIndicator = 'all';

  Widget _buildTechnicalIndicatorCard({
    required String title,
    required String value,
    required String interpretation,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              interpretation,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorSelector(LanguageProvider lang) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildIndicatorChip('all', 'All Indicators', Icons.analytics),
          _buildIndicatorChip('rsi', 'RSI', Icons.show_chart),
          _buildIndicatorChip('macd', 'MACD', Icons.trending_up),
          _buildIndicatorChip('bollinger', 'Bollinger Bands', Icons.layers),
          _buildIndicatorChip('volume', 'Volume Analysis', Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(String value, String label, IconData icon) {
    final isSelected = _selectedIndicator == value;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) => setState(() => _selectedIndicator = value),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildRSIChart(ThemeData theme) {
    final indicators = widget.stockData['technicalIndicators'];
    final rsi = indicators['rsi'];
    Color rsiColor = theme.colorScheme.primary;
    String rsiInterpretation = 'Neutral';

    if (rsi > 70) {
      rsiColor = Colors.red;
      rsiInterpretation = 'Overbought';
    } else if (rsi < 30) {
      rsiColor = Colors.green;
      rsiInterpretation = 'Oversold';
    }

    return _buildTechnicalIndicatorCard(
      title: 'RSI (14)',
      value: rsi.toStringAsFixed(2),
      interpretation: rsiInterpretation,
      color: rsiColor,
      icon: Icons.show_chart,
    );
  }

  Widget _buildMACDChart(ThemeData theme) {
    final indicators = widget.stockData['technicalIndicators'];
    final macd = indicators['macd'];
    final isPositive = macd['histogram'] > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final interpretation = isPositive ? 'Bullish Momentum' : 'Bearish Momentum';

    return _buildTechnicalIndicatorCard(
      title: 'MACD',
      value: '${macd['macdLine'].toStringAsFixed(2)}',
      interpretation: interpretation,
      color: color,
      icon: Icons.trending_up,
    );
  }

  Widget _buildBollingerBandsChart(ThemeData theme) {
    final indicators = widget.stockData['technicalIndicators'];
    final bb = indicators['bollingerBands'];
    final price = widget.stockData['price'];
    Color bbColor = theme.colorScheme.primary;
    String bbInterpretation = 'Within Bands';

    if (price > bb['upper']) {
      bbColor = Colors.red;
      bbInterpretation = 'Overbought';
    } else if (price < bb['lower']) {
      bbColor = Colors.green;
      bbInterpretation = 'Oversold';
    }

    return _buildTechnicalIndicatorCard(
      title: 'Bollinger Bands',
      value:
          '${(((price - bb['middle']) / bb['middle']) * 100).toStringAsFixed(2)}%',
      interpretation: bbInterpretation,
      color: bbColor,
      icon: Icons.layers,
    );
  }

  Widget _buildVolumeAnalysis(ThemeData theme) {
    final volume = widget.stockData['volume'];
    final prevVolume = widget.stockData['prevVolume'];
    final volumeChange = ((volume - prevVolume) / prevVolume) * 100;
    final isPositive = volumeChange > 0;

    return _buildTechnicalIndicatorCard(
      title: 'Volume Analysis',
      value: '${volumeChange.abs().toStringAsFixed(2)}%',
      interpretation: isPositive ? 'Volume Increasing' : 'Volume Decreasing',
      color: isPositive ? Colors.green : Colors.red,
      icon: Icons.bar_chart,
    );
  }

  Widget _buildIndicatorCharts() {
    final theme = Theme.of(context);

    switch (_selectedIndicator) {
      case 'rsi':
        return _buildRSIChart(theme).animate().fadeIn();
      case 'macd':
        return _buildMACDChart(theme).animate().fadeIn();
      case 'bollinger':
        return _buildBollingerBandsChart(theme).animate().fadeIn();
      case 'volume':
        return _buildVolumeAnalysis(theme).animate().fadeIn();
      default:
        return Column(
          children: [
            _buildRSIChart(theme),
            const SizedBox(height: 16),
            _buildMACDChart(theme),
            const SizedBox(height: 16),
            _buildBollingerBandsChart(theme),
            const SizedBox(height: 16),
            _buildVolumeAnalysis(theme),
          ],
        ).animate().fadeIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            lang.translate('technical_analysis'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
        ),
        _buildIndicatorSelector(lang),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildIndicatorCharts(),
        ),
      ],
    );
  }
}
