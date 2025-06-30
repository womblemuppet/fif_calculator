require "bigdecimal"
require "csv"

# for my personal usage there are two relevant methods of determining FIF income
# fair dividend rate
# comparative value

# as a rough estimate - eyeball your total increase from april 1 to march 31
# if it's considerably over 5%, the fair dividend rate should be used

opening_positions_file = File.read("input/opening-positions.csv")
opening_positions = CSV.parse(opening_positions_file, headers: true)

nzd_sum = opening_positions.sum { |row| BigDecimal(row["Market Value (NZD)"]) }
five_percent_of_nzd_sum = nzd_sum * 0.05

puts "5% of total NZD opening position:"
puts format("%2d", five_percent_of_nzd_sum)

trades_file = File.read("input/trades.csv")
trades = CSV.parse(trades_file, headers: true)

quick_sales_trades_by_symbol = trades
  .group_by { |trade| trade["Symbol"] }
  .select { |symbol, trades| trades.length > 1 }

quick_sales_total = quick_sales_trades_by_symbol
  .values
  .flatten(1) # need to specify depth = 1 as CSV::Row implements to_ary
  .sum { |trade| BigDecimal(trade["Notional Value (NZD)"]) }

puts "Quick sales total"
puts format("%2d", quick_sales_total)

will_ignore_quick_sales_total = quick_sales_total < 0

puts "Ignoring quick sales total as it is negative" if will_ignore_quick_sales_total

final_total = if will_ignore_quick_sales_total
  five_percent_of_nzd_sum
else
  five_percent_of_nzd_sum - quick_sales_total
end

puts "Final total:"
puts format("%2d", final_total)


puts "done"