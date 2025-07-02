require "bigdecimal"
require "csv"

# For my personal usage there are two relevant methods of determining FIF income
# Fair Dividend Rate
# Comparative Value

# As a rough estimate - eyeball your total increase from april 1 to march 31
# if it's considerably over 5%, the fair dividend rate should be used
# if it is around 5% then you will need to calculate using both methods

closing_positions_file = File.read("input/closing-positions.csv")
closing_positions = CSV.parse(closing_positions_file, headers: true)
closing_positions_by_symbol = closing_positions.each_with_object({}) do |position, hash|
  hash[position["Symbol"]] = position["Market Value (NZD)"]
end

opening_positions_file = File.read("input/opening-positions.csv")
opening_positions = CSV.parse(opening_positions_file, headers: true)

opening_positions_by_symbol = opening_positions.each_with_object({}) do |position, hash|
  hash[position["Symbol"]] = position["Market Value (NZD)"]
end

nzd_sum = opening_positions.sum { |position| BigDecimal(position["Market Value (NZD)"]) }
five_percent_of_nzd_sum = nzd_sum * 0.05

puts "5% of total NZD opening position:"
puts format("%2d", five_percent_of_nzd_sum)

trades_file = File.read("input/trades.csv")
trades = CSV.parse(trades_file, headers: true)

# Quick sales are trades that are bought and sold in the same year at a profit
# For each quick sale, you can use the lower of the average cost method or actual gain method
#

quick_sales_trades_by_symbol = trades
  .group_by { |trade| trade["Symbol"] }
  .select do |symbol, trades|
    next trades.length > 1 &&
      trades.any? { |trade| BigDecimal(trade["Notional Value (NZD)"]) > 0 } &&
      trades.any? { |trade| BigDecimal(trade["Notional Value (NZD)"]) < 0 } &&
      trades.sum  { |trade| BigDecimal(trade["Notional Value (NZD)"]) } > 0
  end

puts "Quick sales:"
puts quick_sales_trades_by_symbol.keys.join(", ")

quick_sales_trades_by_symbol.each_with_object({}) do |(symbol, trades), hash|
  hash[symbol] = {}
  hash[symbol][:trades] = trades

  total_quantity = trades.sum { |trade| BigDecimal(trade["Quantity"]) }
  total_cost = trades.sum { |trade| BigDecimal(trade["Notional Value (NZD)"]) }
  average_cost = total_quantity / total_cost

  puts symbol
  puts "total quantity", format("%2d", total_quantity)
  puts "total cost", format("%2d", total_cost)
  puts "average cost", average_cost

  # hash[symbol][:average_cost_method] = 
end

exit

# quick_sales_total = quick_sales_trades_by_symbol
#   .values
#   .flatten(1) # need to specify depth = 1 as CSV::Row implements to_ary
#   .sum { |trade| BigDecimal(trade["Notional Value (NZD)"]) }

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