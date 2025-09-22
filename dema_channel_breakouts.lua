instrument {
    name = 'DEMA Channel Crossover with Linked Breakouts',
    icon = 'indicators:MA',
    overlay = true
}

-- Core Parameters
period = input(10, "DEMA Period", input.integer, 1)
atr_period = input(14, "ATR Period", input.integer, 1)
mult = input(3.5, "ATR Multiplier", input.double, 0.1)

-- Compression Parameters
compression_period = input(20, "Compression EMA Period", input.integer, 1)
compression_threshold = input(0.5, "Compression Ratio Threshold", input.double, 0.1)
lookback = input(3, "Compression Lookback Bars", input.integer, 1)

-- DEMA Calculations
fn1 = input(2, "front.newind.average", input.string_selection, averages.titles)
e1_1 = averages[fn1](close, period)
e2_1 = averages[fn1](e1_1, period)
dema1 = 2 * e1_1 - e2_1

fn2 = input(2, "front.newind.average", input.string_selection, averages.titles)
e1_2 = averages[fn2](open, period)
e2_2 = averages[fn2](e1_2, period)
dema2 = 2 * e1_2 - e2_2

fn3 = input(2, "front.newind.average", input.string_selection, averages.titles)
e1_3 = averages[fn3](high, period)
e2_3 = averages[fn3](e1_3, period)
dema_high = 2 * e1_3 - e2_3

fn4 = input(2, "front.newind.average", input.string_selection, averages.titles)
e1_4 = averages[fn4](low, period)
e2_4 = averages[fn4](e1_4, period)
dema_low = 2 * e1_4 - e2_4

-- ATR Envelope
atr = atr(atr_period)
dema_upper = dema1 + mult * atr
dema_lower = dema1 - mult * atr

-- Compression Logic
ema_high = ema(high, compression_period)
ema_low = ema(low, compression_period)
price_range = ema_high - ema_low
compression_ratio = price_range / atr
is_compressed = conditional(compression_ratio < compression_threshold)

-- Compression-Linked Breakouts
recent_compression = false
for i = 0, lookback - 1 do
    recent_compression = recent_compression or is_compressed[i]
end
breakout_long = close > dema_upper
breakout_short = close < dema_lower
linked_breakout_long = breakout_long and recent_compression
linked_breakout_short = breakout_short and recent_compression

-- Style Inputs
input_group {
    "Channel Lines",
    show_dema1 = input { default = true, type = input.plot_visibility },
    dema1_color = input { default = "#00FF00", type = input.color },
    dema1_width = input { default = 2, type = input.line_width },

    show_dema2 = input { default = true, type = input.plot_visibility },
    dema2_color = input { default = "#FFA500", type = input.color },
    dema2_width = input { default = 2, type = input.line_width }
}

input_group {
    "Channel Extremes",
    show_dema_high = input { default = true, type = input.plot_visibility },
    dema_high_color = input { default = "#FF0000", type = input.color },
    dema_high_width = input { default = 1, type = input.line_width },

    show_dema_low = input { default = true, type = input.plot_visibility },
    dema_low_color = input { default = "#0000FF", type = input.color },
    dema_low_width = input { default = 1, type = input.line_width }
}

input_group {
    "Envelope Styling",
    show_envelope = input { default = true, type = input.plot_visibility },
    envelope_upper_color = input { default = "black", type = input.color },
    envelope_lower_color = input { default = "cyan", type = input.color },
    envelope_width = input { default = 2, type = input.line_width },
    fill_color = input { default = "#FFD700", type = input.color } -- Bright fill for contrast
}

input_group {
    "Compression Alerts",
    show_compression = input { default = true, type = input.plot_visibility },
    compression_color = input { default = "#FFFFFF", type = input.color }
}

-- Plotting Lines
if show_dema1 then plot(dema1, "DEMA Close", dema1_color, dema1_width) end
if show_dema2 then plot(dema2, "DEMA Open", dema2_color, dema2_width) end
if show_dema_high then plot(dema_high, "DEMA High", dema_high_color, dema_high_width) end
if show_dema_low then plot(dema_low, "DEMA Low", dema_low_color, dema_low_width) end
if show_envelope then
    plot(dema_upper, "Envelope Upper", envelope_upper_color, envelope_width)
    plot(dema_lower, "Envelope Lower", envelope_lower_color, envelope_width)
    fill(dema_upper, dema_lower, "Envelope Fill", fill_color, 100)
end
if show_compression then
    plot_shape(is_compressed, "Compression", shape_style.circle, shape_size.normal, compression_color, shape_location.abovebar)
end

-- Crossover Arrows
buy_signal = dema1 > dema2 and dema1[1] < dema2[1]
sell_signal = dema1 < dema2 and dema1[1] > dema2[1]

plot_shape(buy_signal, "Buy", shape_style.arrowup, shape_size.normal, dema1_color, shape_location.belowbar)
plot_shape(sell_signal, "Sell", shape_style.arrowdown, shape_size.normal, dema2_color, shape_location.abovebar)

-- Breakout Arrows
plot_shape(linked_breakout_long, "Breakout Long", shape_style.arrowup, shape_size.large, envelope_upper_color, shape_location.abovebar)
plot_shape(linked_breakout_short, "Breakout Short", shape_style.arrowdown, shape_size.large, envelope_lower_color, shape_location.belowbar)
