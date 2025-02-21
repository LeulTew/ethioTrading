import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for TextInputFormatter
import 'package:candlesticks/candlesticks.dart'; // Added for Candle and Candlesticks
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../utils/ethiopian_utils.dart';
import '../utils/validators.dart';
import '../providers/language_provider.dart';
import '../providers/auth_provider.dart';

// Add extension for ColorScheme
extension ColorSchemeExt on ColorScheme {
  Color get onSuccess => Colors.white;
}

class StockDetailScreen extends StatefulWidget {
  final Map<String, dynamic> stockData;

  const StockDetailScreen({
    super.key,
    required this.stockData,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool isBuySelected = true;
  bool isInWatchlist = false;
  bool isMarketOrder = true;
  String selectedTimeframe = '1D';
  List<Map<String, dynamic>> mockNews = [];
  List<Candle> candles = [];
  bool showVolume = true;
  bool showGrid = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _quantityController.text = '1';
    _priceController.text = widget.stockData['price'].toString();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _generateMockNews(),
      _generateCandleData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _generateCandleData() async {
    final random = math.Random();
    double open = widget.stockData['price'].toDouble();
    double close = open;
    final List<Candle> generatedCandles = [];

    // Generate 100 candles with realistic price movements
    for (int i = 100; i > 0; i--) {
      open = close;
      // More realistic price movements based on Ethiopian market rules (±10% daily limit)
      final maxChange = open * 0.10; // 10% max daily move
      final changeAmount = (random.nextDouble() * 2 - 1) * maxChange;
      close = open + changeAmount;

      final high = math.max(open, close) * (1 + random.nextDouble() * 0.02);
      final low = math.min(open, close) * (1 - random.nextDouble() * 0.02);

      // Volume increases with price volatility
      final volatility = (high - low) / open;
      final volume = widget.stockData['volume'] *
          (1 + volatility * 2) *
          random.nextDouble();

      generatedCandles.add(
        Candle(
          date: DateTime.now().subtract(Duration(days: i)),
          high: high,
          low: low,
          open: open,
          close: close,
          volume: volume,
        ),
      );
    }

    setState(() => candles = generatedCandles);
  }

  Widget _buildAdvancedChart() {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        children: [
          _buildChartControls(),
          Expanded(
            child: Candlesticks(
              candles: candles,
              actions: [
                ToolBarAction(
                  onPressed: () => setState(() => showGrid = !showGrid),
                  child: Icon(
                    showGrid ? Icons.grid_on : Icons.grid_off,
                    color: Colors.white,
                  ),
                ),
                ToolBarAction(
                  onPressed: () => setState(() => showVolume = !showVolume),
                  child: Icon(
                    showVolume ? Icons.show_chart : Icons.bar_chart,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildTimeframeSelector(),
        ],
      ),
    );
  }

  Widget _buildChartControls() {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate('technical_analysis'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => showGrid = !showGrid),
                icon: Icon(
                  showGrid ? Icons.grid_on : Icons.grid_off,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                tooltip: lang.translate(showGrid ? 'hide_grid' : 'show_grid'),
              ),
              IconButton(
                onPressed: () => setState(() => showVolume = !showVolume),
                icon: Icon(
                  showVolume ? Icons.show_chart : Icons.bar_chart,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                tooltip:
                    lang.translate(showVolume ? 'hide_volume' : 'show_volume'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['1D', '1W', '1M', '3M', '6M', '1Y', 'ALL'];
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: timeframes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final timeframe = timeframes[index];
          final isSelected = selectedTimeframe == timeframe;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTimeframe = timeframe;
                  _generateCandleData();
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  lang.translate(timeframe.toLowerCase()),
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTradingForm() {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text(
              lang.translate('place_order'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Order Type Selector with animation
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildOrderTypeSelector(theme, lang),
            ),
            const SizedBox(height: 16),

            // Buy/Sell Selector with animation
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: _buildBuySellSelector(theme, lang),
            ),
            const SizedBox(height: 24),

            // Form fields with animations
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: _buildOrderFormFields(theme, lang),
            ),

            const SizedBox(height: 24),

            // Order Summary Card with animation
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildOrderSummaryCard(theme, lang),
            ),

            const SizedBox(height: 24),

            // Place Order Button with animation
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: _buildPlaceOrderButton(theme, lang),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector(ThemeData theme, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SegmentedButton<bool>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary.withValues(alpha: 0.1);
            }
            return null;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
        ),
        segments: [
          ButtonSegment(
            value: true,
            label: Text(lang.translate('market_order')),
            icon: const Icon(Icons.speed),
          ),
          ButtonSegment(
            value: false,
            label: Text(lang.translate('limit_order')),
            icon: const Icon(Icons.price_change),
          ),
        ],
        selected: {isMarketOrder},
        onSelectionChanged: (selected) =>
            setState(() => isMarketOrder = selected.first),
      ),
    );
  }

  Widget _buildBuySellSelector(ThemeData theme, LanguageProvider lang) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: SegmentedButton<bool>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return (isBuySelected ? Colors.green : Colors.red)
                  .withValues(alpha: 0.1);
            }
            return null;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isBuySelected ? Colors.green : Colors.red;
            }
            return null;
          }),
          side: WidgetStateProperty.all(BorderSide.none),
        ),
        segments: [
          ButtonSegment(
            value: true,
            label: Text(lang.translate('buy')),
            icon: const Icon(Icons.add_circle_outline),
          ),
          ButtonSegment(
            value: false,
            label: Text(lang.translate('sell')),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
        selected: {isBuySelected},
        onSelectionChanged: (selected) =>
            setState(() => isBuySelected = selected.first),
      ),
    );
  }

  Widget _buildOrderFormFields(ThemeData theme, LanguageProvider lang) {
    return Column(
      children: [
        _buildTextField(
          controller: _quantityController,
          label: lang.translate('quantity'),
          icon: Icons.shopping_cart_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) => TradeValidator.validateQuantity(
            value ?? '',
            lotSize: widget.stockData['lotSize'] ?? 1,
            availableBalance: widget.stockData['availableBalance'] ?? 0,
            price: double.tryParse(_priceController.text) ??
                widget.stockData['price'],
          ),
        ),
        if (!isMarketOrder) ...[
          const SizedBox(height: 16),
          _buildTextField(
            controller: _priceController,
            label: lang.translate('price'),
            icon: Icons.attach_money,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) => TradeValidator.validatePrice(
              value ?? '',
              basePrice: widget.stockData['price'],
              tickSize: widget.stockData['tickSize'] ?? 0.01,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.spaceGrotesk(),
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme, LanguageProvider lang) {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ??
        (widget.stockData['price'] as num).toDouble();
    final total = (quantity * price).toDouble();

    // Use correct validator class and method
    final fees = TradingValidator.calculateTradingFees(
      amount: total,
      isBuy: isBuySelected,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
              lang.translate('order_summary'),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              lang.translate('order_type'),
              lang.translate(isMarketOrder ? 'market_order' : 'limit_order'),
              theme,
            ),
            _buildSummaryRow(
              lang.translate('quantity'),
              quantity.toString(),
              theme,
            ),
            if (!isMarketOrder)
              _buildSummaryRow(
                lang.translate('price'),
                EthiopianCurrencyFormatter.format(price),
                theme,
              ),
            const Divider(height: 32),
            _buildSummaryRow(
              lang.translate('estimated_total'),
              EthiopianCurrencyFormatter.format(total),
              theme,
              isTotal: true,
            ),
            Text(
              '${lang.translate('commission')}: ${EthiopianCurrencyFormatter.format(fees['commission']?.toDouble() ?? 0.0)}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            Text(
              '${lang.translate('vat')}: ${EthiopianCurrencyFormatter.format(fees['vat']?.toDouble() ?? 0.0)}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            if ((fees['capitalGainsTax'] ?? 0.0) > 0)
              Text(
                '${lang.translate('capital_gains_tax')}: ${EthiopianCurrencyFormatter.format(fees['capitalGainsTax']?.toDouble() ?? 0.0)}',
                style: GoogleFonts.spaceGrotesk(),
              ),
            const Divider(),
            Text(
              '${lang.translate('total')}: ${EthiopianCurrencyFormatter.format(fees['total']?.toDouble() ?? 0.0)}',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme,
      {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(ThemeData theme, LanguageProvider lang) {
    return ElevatedButton(
      onPressed: _handlePlaceOrder,
      style: ElevatedButton.styleFrom(
        backgroundColor: isBuySelected ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        lang.translate(isBuySelected ? 'place_buy_order' : 'place_sell_order'),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _handlePlaceOrder() async {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Validate form fields
    final quantity = _quantityController.text;
    final price = isMarketOrder
        ? widget.stockData['price'].toString()
        : _priceController.text;
    final tradeType = isMarketOrder ? 'market' : 'limit';
    final orderSide = isBuySelected ? 'buy' : 'sell';

    // Validate trade
    final validation = TradeValidator.validateTrade(
      quantity: quantity,
      price: price,
      tradeType: tradeType,
      orderSide: orderSide,
      stockData: widget.stockData,
      userProfile: authProvider.userData ?? {},
    );

    if (!validation['isValid']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.translate(validation['error']),
              style: GoogleFonts.spaceGrotesk(),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
      return;
    }

    // Calculate fees using correct method name and parameters
    final total = (int.parse(_quantityController.text) *
            double.parse(_priceController.text))
        .toDouble();
    final fees = TradingValidator.calculateTradingFees(
      amount: total,
      isBuy: isBuySelected,
    );

    // Show confirmation dialog with null-safe fee access
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          lang.translate('confirm_order'),
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lang.translate(orderSide)}: $quantity ${widget.stockData['symbol']}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            const SizedBox(height: 8),
            Text(
              '${lang.translate('price')}: ${EthiopianCurrencyFormatter.format(double.parse(price))}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            const SizedBox(height: 8),
            Text(
              '${lang.translate('commission')}: ${EthiopianCurrencyFormatter.format((fees['commission'] as num).toDouble())}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            Text(
              '${lang.translate('vat')}: ${EthiopianCurrencyFormatter.format((fees['vat'] as num).toDouble())}',
              style: GoogleFonts.spaceGrotesk(),
            ),
            if ((fees['capitalGainsTax'] as num?) != null &&
                (fees['capitalGainsTax'] as num) > 0)
              Text(
                '${lang.translate('capital_gains_tax')}: ${EthiopianCurrencyFormatter.format((fees['capitalGainsTax'] as num).toDouble())}',
                style: GoogleFonts.spaceGrotesk(),
              ),
            const Divider(),
            Text(
              '${lang.translate('total')}: ${EthiopianCurrencyFormatter.format((fees['total'] as num).toDouble())}',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.translate('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      // Execute trade
      await authProvider.executeTrade({
        'symbol': widget.stockData['symbol'],
        'type': tradeType,
        'side': orderSide,
        'quantity': int.parse(quantity),
        'price': double.parse(price),
        'fees': fees,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pop(context); // Close order form
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.onSuccess),
                const SizedBox(width: 8),
                Text(
                  lang.translate('order_executed_successfully'),
                  style: GoogleFonts.spaceGrotesk(),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.onError),
                const SizedBox(width: 8),
                Text(
                  lang.translate('order_execution_failed'),
                  style: GoogleFonts.spaceGrotesk(),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isPositiveChange = (widget.stockData['change'] ?? 0) >= 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              widget.stockData['symbol'],
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lang.translate(widget.stockData['sector'].toLowerCase()),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isInWatchlist ? Icons.star : Icons.star_border,
              color: isInWatchlist ? Colors.amber : null,
            ),
            onPressed: () => setState(() => isInWatchlist = !isInWatchlist),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: lang.translate('overview')),
            Tab(text: lang.translate('chart')),
            Tab(text: lang.translate('analysis')),
            Tab(text: lang.translate('news')),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    lang.translate('loading_data'),
                    style: GoogleFonts.spaceGrotesk(),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(theme, isPositiveChange, lang),
                _buildAdvancedChart(),
                _buildAnalysisTab(theme, lang),
                _buildNewsTab(theme, lang),
              ],
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildTradingForm(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            lang.translate('trade'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
      ThemeData theme, bool isPositiveChange, LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceSection(theme, isPositiveChange, lang),
          const SizedBox(height: 24),
          _buildCompanyInfo(theme, lang),
          const SizedBox(height: 24),
          _buildKeyStatistics(theme, lang),
        ],
      ),
    );
  }

  Widget _buildPriceSection(
      ThemeData theme, bool isPositiveChange, LanguageProvider lang) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              EthiopianCurrencyFormatter.format(widget.stockData['price']),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(
                  isPositiveChange ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositiveChange ? Colors.green : Colors.red,
                  size: 16,
                ),
                Text(
                  '${isPositiveChange ? '+' : ''}${widget.stockData['change'].toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositiveChange ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfo(ThemeData theme, LanguageProvider lang) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('company_info'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('name', widget.stockData['name'], theme, lang),
            _buildInfoRow('sector', widget.stockData['sector'], theme, lang),
            _buildInfoRow(
                'ownership', widget.stockData['ownership'], theme, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label, String value, ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate(label),
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStatistics(ThemeData theme, LanguageProvider lang) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('key_statistics'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
                'volume',
                EthiopianCurrencyFormatter.formatVolume(
                    widget.stockData['volume']),
                theme,
                lang),
            _buildStatRow(
                'market_cap',
                EthiopianCurrencyFormatter.format(
                    widget.stockData['marketCap']),
                theme,
                lang),
            _buildStatRow('lot_size', widget.stockData['lotSize'].toString(),
                theme, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate(label),
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(ThemeData theme, LanguageProvider lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.translate('technical_analysis'),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTechnicalIndicators(theme, lang),
        ],
      ),
    );
  }

  Widget _buildTechnicalIndicators(ThemeData theme, LanguageProvider lang) {
    final indicators = widget.stockData['technicalIndicators'];
    if (indicators == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('technical_indicators'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildIndicatorRow(
                'sma20', indicators['sma20'].toString(), theme, lang),
            _buildIndicatorRow(
                'ema20', indicators['ema20'].toString(), theme, lang),
            _buildIndicatorRow(
                'rsi', indicators['rsi'].toString(), theme, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(
      String label, String value, ThemeData theme, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            lang.translate(label),
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsTab(ThemeData theme, LanguageProvider lang) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockNews.length,
      itemBuilder: (context, index) {
        final news = mockNews[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
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
                  news['title'],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  news['summary'],
                  style: GoogleFonts.spaceGrotesk(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      news['date'],
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateMockNews() async {
    final random = math.Random();
    final titles = [
      'Company announces strong Q4 results',
      'New expansion plans revealed',
      'Board approves dividend payment',
      'Strategic partnership announced',
      'Market share continues to grow'
    ];

    setState(() {
      mockNews = List.generate(5, (index) {
        return {
          'title': titles[index],
          'summary':
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
          'date': '${random.nextInt(24)} hours ago',
        };
      });
    });
  }
}
