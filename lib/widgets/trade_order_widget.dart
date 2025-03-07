import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../providers/language_provider.dart';
import '../providers/trading_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/market_provider.dart';

class TradeOrderWidget extends StatefulWidget {
  final Asset asset;
  final String initialOrderType;
  final String initialSide;

  const TradeOrderWidget({
    super.key,
    required this.asset,
    this.initialOrderType = 'market',
    this.initialSide = 'buy',
  });

  @override
  State<TradeOrderWidget> createState() => _TradeOrderWidgetState();
}

class _TradeOrderWidgetState extends State<TradeOrderWidget> {
  late String _orderType;
  late String _side;
  int _quantity = 1;
  double _limitPrice = 0.0;
  double _stopPrice = 0.0;
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final TextEditingController _limitPriceController = TextEditingController();
  final TextEditingController _stopPriceController = TextEditingController();
  bool _isReviewing = false;

  @override
  void initState() {
    super.initState();
    _orderType = widget.initialOrderType;
    _side = widget.initialSide;
    _limitPrice = widget.asset.price;
    _stopPrice = _side == 'buy'
        ? widget.asset.price * 1.05 // 5% above current price for buy stop
        : widget.asset.price * 0.95; // 5% below current price for sell stop

    _limitPriceController.text = _limitPrice.toStringAsFixed(2);
    _stopPriceController.text = _stopPrice.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _limitPriceController.dispose();
    _stopPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final tradingProvider = Provider.of<TradingProvider>(context);
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    // Auth provider is used for user verification in future enhancements
    Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    // Calculate estimated cost/proceeds
    final price = _orderType == 'market' ? widget.asset.price : _limitPrice;
    final fees =
        tradingProvider.calculateFees(widget.asset, _quantity, price, _side);
    final estimatedTotal = tradingProvider.getEstimatedTradeCost(
        widget.asset, _quantity, price, _side);

    // Get portfolio item if selling
    final portfolioItem = _side == 'sell'
        ? portfolioProvider.getPortfolioItemBySymbol(widget.asset.symbol)
        : null;

    // Check if user has enough shares to sell
    final hasEnoughShares =
        portfolioItem != null && portfolioItem.quantity >= _quantity;

    // Check if user has enough cash to buy
    final hasEnoughCash =
        _side == 'buy' ? portfolioProvider.cashBalance >= estimatedTotal : true;

    return _isReviewing
        ? _buildOrderReview(
            languageProvider,
            tradingProvider,
            portfolioProvider,
            theme,
            price,
            fees,
            estimatedTotal,
          )
        : _buildOrderForm(
            languageProvider,
            theme,
            portfolioItem,
            hasEnoughShares,
            hasEnoughCash,
            estimatedTotal,
          );
  }

  Widget _buildOrderForm(
    LanguageProvider languageProvider,
    ThemeData theme,
    PortfolioItem? portfolioItem,
    bool hasEnoughShares,
    bool hasEnoughCash,
    double estimatedTotal,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order type selector
          Text(
            languageProvider.translate('order_type'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'market',
                label: Text(languageProvider.translate('market_order')),
              ),
              ButtonSegment<String>(
                value: 'limit',
                label: Text(languageProvider.translate('limit_order')),
              ),
              ButtonSegment<String>(
                value: 'stop',
                label: Text(languageProvider.translate('stop_order')),
              ),
            ],
            selected: {_orderType},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _orderType = selection.first;
              });
            },
          ),
          const SizedBox(height: 16.0),

          // Buy/Sell selector
          Text(
            languageProvider.translate('side'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8.0),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'buy',
                label: Text(languageProvider.translate('buy_action')),
                icon: const Icon(Icons.add_circle_outline),
              ),
              ButtonSegment<String>(
                value: 'sell',
                label: Text(languageProvider.translate('sell_action')),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
            selected: {_side},
            onSelectionChanged: (Set<String> selection) {
              setState(() {
                _side = selection.first;
                // Update stop price based on side
                _stopPrice = _side == 'buy'
                    ? widget.asset.price * 1.05
                    : widget.asset.price * 0.95;
                _stopPriceController.text = _stopPrice.toStringAsFixed(2);
              });
            },
          ),
          const SizedBox(height: 16.0),

          // Quantity
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  decoration: InputDecoration(
                    labelText: languageProvider.translate('quantity_amount'),
                    border: const OutlineInputBorder(),
                    suffixText: languageProvider.translate('shares'),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (value) {
                    setState(() {
                      _quantity = int.tryParse(value) ?? 1;
                      if (_quantity < 1) {
                        _quantity = 1;
                        _quantityController.text = '1';
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _quantity += 1;
                        _quantityController.text = _quantity.toString();
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    onPressed: _quantity > 1
                        ? () {
                            setState(() {
                              _quantity -= 1;
                              _quantityController.text = _quantity.toString();
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Limit price (for limit and stop-limit orders)
          if (_orderType == 'limit' || _orderType == 'stop_limit')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('limit_price'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _limitPriceController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'ETB ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _limitPrice =
                          double.tryParse(value) ?? widget.asset.price;
                    });
                  },
                ),
                const SizedBox(height: 16.0),
              ],
            ),

          // Stop price (for stop and stop-limit orders)
          if (_orderType == 'stop' || _orderType == 'stop_limit')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('stop_price'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                TextFormField(
                  controller: _stopPriceController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixText: 'ETB ',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _stopPrice = double.tryParse(value) ??
                          (_side == 'buy'
                              ? widget.asset.price * 1.05
                              : widget.asset.price * 0.95);
                    });
                  },
                ),
                const SizedBox(height: 16.0),
              ],
            ),

          // Current position (if selling)
          if (_side == 'sell' && portfolioItem != null)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageProvider.translate('current_position'),
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(languageProvider.translate('shares')),
                      Text('${portfolioItem.quantity}'),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(languageProvider.translate('avg_cost')),
                      Text('ETB ${portfolioItem.avgPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(languageProvider.translate('current_value')),
                      Text(
                          'ETB ${portfolioItem.currentValue.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16.0),

          // Order summary
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('order_summary'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('symbol')),
                    Text(widget.asset.symbol),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('current_price')),
                    Text('ETB ${widget.asset.price.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('estimated_total')),
                    Text(
                      'ETB ${estimatedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _side == 'buy' ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // Error messages
          if (_side == 'sell' && !hasEnoughShares)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                languageProvider.translate('insufficient_shares'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          if (_side == 'buy' && !hasEnoughCash)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                languageProvider.translate('insufficient_funds'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),

          // Review order button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ((_side == 'sell' && !hasEnoughShares) ||
                      (_side == 'buy' && !hasEnoughCash))
                  ? null
                  : () {
                      setState(() {
                        _isReviewing = true;
                      });
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _side == 'buy' ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(languageProvider.translate('review_order')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderReview(
    LanguageProvider languageProvider,
    TradingProvider tradingProvider,
    PortfolioProvider portfolioProvider,
    ThemeData theme,
    double price,
    Map<String, dynamic> fees,
    double estimatedTotal,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            languageProvider.translate('review_order'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24.0),

          // Order details
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('action'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      _side == 'buy'
                          ? languageProvider.translate('buy_action')
                          : languageProvider.translate('sell_action'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _side == 'buy' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('symbol'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      widget.asset.symbol,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('order_type'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      languageProvider.translate('${_orderType}_order'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('quantity_amount'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      '$_quantity ${languageProvider.translate('shares')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('price_value'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Text(
                      'ETB ${price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (_orderType == 'limit' || _orderType == 'stop_limit') ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.translate('limit_price'),
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        'ETB ${_limitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                if (_orderType == 'stop' || _orderType == 'stop_limit') ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.translate('stop_price'),
                        style: theme.textTheme.bodyLarge,
                      ),
                      Text(
                        'ETB ${_stopPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // Cost breakdown
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageProvider.translate('cost_breakdown'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('subtotal')),
                    Text('ETB ${(_quantity * price).toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('exchange_fee')),
                    Text('ETB ${fees['exchange'].toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('tax')),
                    Text('ETB ${fees['tax'].toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(languageProvider.translate('commission')),
                    Text('ETB ${fees['brokerage'].toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      languageProvider.translate('total'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ETB ${estimatedTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _side == 'buy' ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isReviewing = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: Text(languageProvider.translate('back')),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: tradingProvider.isLoading
                      ? null
                      : () async {
                          // Create trade request
                          final request = TradeRequest(
                            symbol: widget.asset.symbol,
                            quantity: _quantity,
                            price: price,
                            side: _side,
                            orderType: _orderType,
                            fees: fees,
                          );

                          // Execute trade
                          final success =
                              await tradingProvider.executeTrade(request);

                          if (success && mounted) {
                            // Refresh portfolio data
                            final marketProvider = Provider.of<MarketProvider>(
                              context,
                              listen: false,
                            );
                            final assets =
                                marketProvider.assets.fold<Map<String, Asset>>(
                              {},
                              (map, asset) => map..[asset.symbol] = asset,
                            );

                            await portfolioProvider.refreshPortfolio(
                                marketAssets: assets);

                            // Show success message and close dialog
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tradingProvider.successMessage),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _side == 'buy' ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: tradingProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(languageProvider.translate('place_order')),
                ),
              ),
            ],
          ),

          // Error message
          if (tradingProvider.error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                tradingProvider.error,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
