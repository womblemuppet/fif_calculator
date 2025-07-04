require "bigdecimal"
require "csv"

# For my personal usage there are two relevant methods of determining FIF income
# Fair Dividend Rate  (FDR)
# Comparative Value   (CV)

# As a rough estimate - eyeball your total increase from april 1 to march 31
# if it's considerably over 5%, the fair dividend rate should be used
# if it is around 5% then you will need to calculate using both methods

big_decimal_converter = -> (field, field_info) do
  if ["Notional Value (NZD)", "Market Value (NZD)", "Quantity"].include?(field_info.header)
    next BigDecimal(field)
  else
    next field
  end
end

closing_positions_file = File.read("input/closing-positions.csv")
closing_positions = CSV.parse(closing_positions_file, headers: true, converters: big_decimal_converter)

closing_quantities_by_symbol = closing_positions.each_with_object({}) do |position, hash|
  hash[position["Symbol"]] = position["Quantity"]
end

opening_positions_file = File.read("input/opening-positions.csv")
opening_positions = CSV.parse(opening_positions_file, headers: true, converters: big_decimal_converter)

opening_quantities_by_symbol = opening_positions.each_with_object({}) do |position, hash|
  hash[position["Symbol"]] = position["Quantity"]
end

nzd_sum = opening_positions.sum { |position| position["Market Value (NZD)"] }
five_percent_of_nzd_sum = nzd_sum * 0.05

puts "5% of total NZD opening position:"
puts format("%5f", five_percent_of_nzd_sum)

trades_file = File.read("input/trades.csv")
trades = CSV.parse(trades_file, headers: true, converters: big_decimal_converter)

# Quick sales are trades that are bought and sold in the same year at a profit
# For each quick sale, you can use the lower of the peak holding method or actual gain method
#

quick_sales_trades_by_symbol = trades
  .group_by { |trade| trade["Symbol"] }
  .select do |symbol, trades|
    next trades.length > 1 &&
      trades.any? { |trade| trade["Notional Value (NZD)"] > 0 } &&
      trades.any? { |trade| trade["Notional Value (NZD)"] < 0 }
  end

puts "Quick sales:"
puts quick_sales_trades_by_symbol.keys.join(", ")

quick_sales_calcs_by_symbol = quick_sales_trades_by_symbol.each_with_object({}) do |(symbol, trades), hash|
  hash[symbol] = {}
  puts "\n", symbol

  all_purchases = trades.select { |trade| trade["Notional Value (NZD)"] > 0 }
  all_purchases_total_quantity = all_purchases.sum { |trade| trade["Quantity"] }
  all_purchases_total_value = all_purchases.sum { |trade| trade["Notional Value (NZD)"] }
  all_purchases_average_cost = all_purchases_total_value / all_purchases_total_quantity

  puts "all_purchases_total_quantity", format("%5f", all_purchases_total_quantity)
  puts "total_cost", format("%5f", all_purchases_total_value)
  puts "all_purchases_average_cost", all_purchases_average_cost

  opening_quantity = opening_quantities_by_symbol[symbol] || 0.0
  puts "opening_quantity", format("%5f", opening_quantity)

  closing_quantity = closing_quantities_by_symbol[symbol] || 0.0
  puts "closing_quantity", format("%5f", closing_quantity)

  greatest_quantity = trades.map { |trade| trade["Quantity"] }
    .inject({ running_quantity: opening_quantity, max_quantity: opening_quantity}) do |acc, quantity|
      puts "running_quantity #{format("%5f", acc[:running_quantity]) } max_quantity #{format("%5f", acc[:max_quantity])} - adding #{format("%5f", quantity)}"

      running_quantity = acc[:running_quantity] + quantity

      if running_quantity > acc[:max_quantity]
        next { running_quantity: running_quantity, max_quantity: running_quantity }
      else
        next { running_quantity: running_quantity, max_quantity: acc[:max_quantity] }
      end
    end[:max_quantity]

  puts "greatest_quantity", format("%5f", greatest_quantity)

  max_and_opening_position_difference = greatest_quantity - opening_quantity
  puts "max_and_opening_position_difference", format("%5f", max_and_opening_position_difference)
  max_and_closing_position_difference = greatest_quantity - closing_quantity
  puts "max_and_closing_position_difference", format("%5f", max_and_closing_position_difference)

  peak_holding_differential = [max_and_opening_position_difference, max_and_closing_position_difference].min
  puts "peak_holding_differential", format("%5f", peak_holding_differential)

  peak_holding_method_value = peak_holding_differential * all_purchases_average_cost * 0.05
  puts "peak_holding_method_value", format("%5f", peak_holding_method_value)

  hash[symbol][:peak_holding_method_value] = peak_holding_method_value

  all_sales = trades.select { |trade| trade["Notional Value (NZD)"] < 0 }
  all_sales_total_value = all_sales.sum { |trade| trade["Notional Value (NZD)"] }.abs
  puts "all_sales_total_value", format("%5f", all_sales_total_value)
  all_sales_total_quantity = all_sales.sum { |trade| trade["Quantity"] }.abs
  puts "all_sales_total_quantity", format("%5f", all_sales_total_quantity)
  puts "all_purchases_average_cost", format("%5f", all_purchases_average_cost)
  actual_gain = all_sales_total_value - (all_sales_total_quantity * all_purchases_average_cost)
  puts "actual_gain", format("%5f", actual_gain)

  hash[symbol][:actual_gain_method_value] = actual_gain

  minimum_of_both_methods = [
    hash[symbol][:peak_holding_method_value],
    hash[symbol][:actual_gain_method_value]
  ].min

  hash[symbol][:quick_sales_adjustment] = [0, minimum_of_both_methods].max
end

puts "\n", "quick_sales_calcs_by_symbol:"
quick_sales_calcs_by_symbol.each do |symbol, quick_sales_calculations|
  puts symbol + ":"
  puts "peak_holding_method_value:"
  puts format("%5f", quick_sales_calculations[:peak_holding_method_value])
  puts "actual_gain_method_value:"
  puts format("%5f", quick_sales_calculations[:actual_gain_method_value])
  puts "using #{format("%5f", quick_sales_calculations[:quick_sales_adjustment])}"
end


quick_sales_total = quick_sales_calcs_by_symbol
  .values
  .sum { |quick_sales_calculations| quick_sales_calculations[:quick_sales_adjustment]  }

puts "\n", "5% of total NZD opening position:"
puts format("%5f", five_percent_of_nzd_sum)

puts "Quick sales total"
puts format("%5f", quick_sales_total)

final_total = five_percent_of_nzd_sum + quick_sales_total

puts "Final total:"
puts format("%5f", final_total)


puts "done"