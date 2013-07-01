require "observer"
require 'yahoofinance'

class Ticker          ### Periodically fetch a stock price.
	include Observable

    def initialize(symbol1)
		@symbol = symbol1.upcase
		@price = Price.fetch(@symbol)
		@stock_name = StockName.fetch(@symbol)
		@percent_change = PercentChange.fetch(@symbol)
		@points_change = PointsChange.fetch(@symbol)

	end
	
	def printstock
		@price = Price.fetch(@symbol)
		@stock_name = StockName.fetch(@symbol)
		@percent_change = PercentChange.fetch(@symbol)
		print "\nCompany: #{@stock_name}"		
		print "\nQuote: #{@symbol}  lastTrade: #{ @price }  percent change: #{@percent_change}% points change: #{@points_change}"
# Markets are closed
		t = Time.now
		if t.wday == 0 or t.wday == 6 or ((t.hour < 7 and t.min < 30) or t.hour > 14)
			print "\nThe US Stock Market is closed.\n\n"
			exit
		end
	end
	
	def run
      lastPrice = nil
	  lastPercent = nil
	  lastPoints = nil
      loop do
#Markets open --- The stock quotes will refresh every 20 seconds 
		printstock
		if @price != lastPrice or @percent_change != lastPercent or @points_change != lastPoints
			changed                 # notify observers
			lastPrice = @price
			notify_observers(Time.now, @price, @percent_change, @points_change)
        end
        sleep 20
      end
    end
  end

  class Price          ### A class to fetch a stock price.
    def Price.fetch(symbol)
		p = YahooFinance::get_quotes(YahooFinance::StandardQuote, symbol)
		if p[symbol].lastTrade == 0
			print "The stock symbol entered is incorrect!\n"
			exit
		end
		p[symbol].lastTrade
	end
  end

class StockName          ### A class to fetch a stock name.
    def StockName.fetch(symbol)
		p = YahooFinance::get_quotes(YahooFinance::StandardQuote, symbol)
		p[symbol].name
	end
end

class PercentChange          ### A class to fetch a stock percent change.
    def PercentChange.fetch(symbol)
		p = YahooFinance::get_quotes(YahooFinance::StandardQuote, symbol)
		p[symbol].changePercent
	end
  end
  
class PointsChange          ### A class to fetch a stock points change.
    def PointsChange.fetch(symbol)
		p = YahooFinance::get_quotes(YahooFinance::StandardQuote, symbol)
		p[symbol].changePoints
	end
end


  class Warner          ### An abstract observer of Ticker objects.
    def initialize(ticker, price_limit, percent_limit, points_limit)
      @limit = price_limit
	  @percent_limit = percent_limit
	  @points_limit = points_limit
      ticker.add_observer(self)
    end
  end

  class WarnLow < Warner
    def update(time, price, percent, points )       # callback for observer
		if price < @limit
			print "\n--- #{time.to_s}: Price below #@limit: #{ price }"
		end
		if percent < @percent_limit
			print "\n--- #{time.to_s}: Percentage below #@percent_limit: #{ percent }"
		end
		if points < @points_limit
			print "\n--- #{time.to_s}: Points below #@points_limit: #{ points }"
		end
    end
  end

  class WarnHigh < Warner
    def update(time, price, percent, points )       # callback for observer
      if price > @limit
			print "\n--- #{time.to_s}: Price above #@limit: #{ price }"
		end
		if percent > @percent_limit
			print "\n--- #{time.to_s}: Percentage above #@percent_limit: #{ percent }"
		end
		if points > @points_limit
			print "\n--- #{time.to_s}: Points above #@points_limit: #{ points }"
		end
    end
  end



print "\nWhat stock to you want to observe?\n"
print "\n------ Please enter a stock symbol ------\n"
my_sym = gets.chomp
ticker = Ticker.new(my_sym)
ticker.printstock
print "\nSet High/Low warning prices?\n"
print "\n------ Please enter a High price ------\n"
price_high = Float(gets.chomp)
print "\n------ Please enter a Low price ------\n"
price_low = Float(gets.chomp)
print "\nSet High/Low warning percentages\n"
print "\n------ Please enter a High percentages ------\n"
percent_high = Float(gets.chomp)
print "\n------ Please enter a Low percentages ------\n"
percent_low = Float(gets.chomp)
print "\nSet High/Low warning percentages\n"
print "\n------ Please enter a High points ------\n"
points_high = Float(gets.chomp)
print "\n------ Please enter a Low points ------\n"
points_low = Float(gets.chomp)


  WarnLow.new(ticker, price_low, percent_low, points_low)
  WarnHigh.new(ticker, price_high, percent_high, points_high)
  ticker.run
