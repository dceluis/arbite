class CompareCurrencyLists
  MARKETS = [
    'binance',
    'bittrex',
    'cryptopia',
    'gate',
    'poloniex'
  ].freeze

  UpdateCounters = Struct.new(*MARKETS.map(&:to_sym))
  PercentageRange = Struct.new(:min, :lower_mid, :mid, :upper_mid, :max) do
    def color_for(number)
      if number < lower_mid
        :white
      elsif number < mid
        :light_yellow
      elsif number < upper_mid
        :light_green
      else
        :green
      end
    end
  end

  def initialize(balance = nil)
    @balance = balance
    @percentage_range = PercentageRange.new(0.1, 0.5, 0.8, 1.5, 6)

    @counters = UpdateCounters.new(*Array.new(MARKETS.length, 0))
  end

  def start
    threads = MARKETS.map do |market_name|
      Thread.new do
        while true
          sleep 1

          fetch_tickers(market_name)
        end
      end
      Thread.new do
        while true
          sleep 1
          @counters[market_name] += 1
        end
      end
    end

    while true
      sleep 4

      puts "\n\n=== Results ===\n\n"
      MARKETS.each { |mkt| puts "#{mkt.capitalize}: #{@counters[mkt]}" }

      ticker_tree['BTC'].each_value do |markets_hash|
        tickers = markets_hash.map { |_market_name, ticker| ticker }

        comparisons = compare_list(tickers)
        comparisons.select! do |comparison|
          comparison[:percentage] > @percentage_range.min &&
            comparison[:percentage] < @percentage_range.max
        end

        next if comparisons.length < 2

        comparisons.each do |comparison|
          puts(
            "#{comparison[:base]}-#{comparison[:target]} / "\
            "#{('%.3f' % comparison[:percentage]).colorize(@percentage_range.color_for(comparison[:percentage]))}% \t == "\
            "#{'%10s' % comparison[:buy_from]}: "\
            "#{'%.8f' % comparison[:buy_price]} -- "\
            "#{'%10s' % comparison[:sell_at]}: "\
            "#{'%.8f' % comparison[:sell_price]} \t"\
            " #{'%.8f' % comparison[:buyable]}"
          )
        end
      end
    end
  end

  def compare_list(tickers)
    results = []

    tickers.each do |ticker|
      comparison = {}

      tickers.each do |other|
        color = color_for_market(ticker.market)
        other_color = color_for_market(other.market)

        comparison[:percentage] = compare(ticker, other)
        comparison[:buy_from] = other.market.capitalize.colorize(other_color)
        comparison[:sell_at] = ticker.market.capitalize.colorize(color)
        comparison[:buy_price] = other.ask
        comparison[:sell_price] = ticker.bid
        comparison[:base] = ticker.base
        comparison[:target] = ticker.target
        comparison[:buyable] = @balance.to_f / other.ask
      end

      results.push comparison
    end

    results
  end

  def color_for_market(market)
    colors = String.colors - [:black]
    colors[MARKETS.index(market) % colors.length]
  end

  def compare(ticker, other)
    return 0 if ticker.market == other.market

    ((ticker.bid / other.ask) - 1) * 100
  end

  def ticker_tree
    @ticker_tree ||= { 'BTC' => {} }
  end

  def add_to_ticker_tree(ticker)
    ticker_tree[ticker.target] ||= {}
    ticker_tree[ticker.target][ticker.base] ||= {}
    ticker_tree[ticker.target][ticker.base][ticker.market] = ticker
  end

  def fetch_tickers(market_name)
    capitalized = market_name.capitalize
    market = "Cryptoexchange::Exchanges::#{capitalized}::Services::Market".constantize.new

    tickers = market.fetch

    tickers.each do |ticker|
      add_to_ticker_tree(ticker)
    end

    @counters[market_name.to_sym] = 0
  rescue
  end
end
