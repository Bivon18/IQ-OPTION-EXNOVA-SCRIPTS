instrument { name = "Gold Pulse Breakout + Liquidity v", overlay = true }

-- =========================
-- Inputs
-- =========================
group "Liquidity levels"
show_session   = input(true,  "Session high/low", input.boolean)
show_round     = input(true,  "Round levels",     input.boolean)
round_step     = input(5.0,   "Round step",       input.double)         -- e.g., 5 for XAUUSD
show_swings    = input(true,  "Swing highs/lows", input.boolean)
swing_lr       = input(2,     "Swing L/R bars",   input.integer, 1, 20)

group "Breakouts"
show_liq_signals   = input(true,  "Show liquidity-filtered breakouts", input.boolean)
require_liquidity  = input(true,  "Require proximity to liquidity",    input.boolean)
liq_proximity      = input(1.0,   "Liquidity proximity",               input.double, 0.0, 1000.0, 0.1)
donch_lookback     = input(20,    "Donchian lookback",                 input.integer, 2, 1000)

show_all_breakouts = input(true,  "Show all breakouts (debug)",        input.boolean)

group "Styles"
session_color = input { default = rgba(0, 191, 255, 0.8), type = input.color }   -- DeepSkyBlue
round_color   = input { default = rgba(192, 192, 192, 0.8), type = input.color } -- Silver
swing_color   = input { default = rgba(255, 165,   0, 1.0), type = input.color } -- Orange
up_color      = input { default = rgba( 50, 205,  50, 1.0), type = input.color } -- Lime
dn_color      = input { default = rgba(255,  99,  71, 1.0), type = input.color } -- Tomato
dbg_color     = input { default = rgba(105, 105, 105, 1.0), type = input.color } -- DimGray

-- =========================
-- Helpers (no math.*)
-- =========================
local function is_new_day()
    return dayofmonth(time) ~= dayofmonth(time[1])
        or month(time) ~= month(time[1])
        or year(time) ~= year(time[1])
end

local function abs(x) return x >= 0 and x or -x end
local function fmin(a, b) return (a < b) and a or b end
local function fmax(a, b) return (a > b) and a or b end

-- floor for positive numbers
local function floor_(x)
    return x - (x % 1)
end

-- round x to nearest multiple of step (assumes step > 0, x >= 0)
local function round_to_step(x, step)
    if step <= 0 then return x end
    local n = x / step
    local nf = floor(n)
    if (n - nf) >= 0.5 then nf = nf + 1 end
    return nf * step
end

-- min distance among up to 4 values; ignore NaN via self-inequality
local function min_dist(price, a, b, c, d)
    local best = 1e100
    if a == a then best = fmin(best, abs(price - a)) end
    if b == b then best = fmin(best, abs(price - b)) end
    if c == c then best = fmin(best, abs(price - c)) end
    if d == d then best = fmin(best, abs(price - d)) end
    return best
end

na_val = 0/0

-- =========================
-- Session high/low (series-safe)
-- =========================
if bar_index == 0 then
    session_high = high
    session_low  = low
else
    if is_new_day() then
        session_high = high
        session_low  = low
    else
        session_high = fmax(session_high[1], high)
        session_low  = fmin(session_low[1], low)
    end
end

if show_session then
    plot(session_high, "Session High", session_color, 1)
    plot(session_low,  "Session Low",  session_color, 1)
end

-- =========================
-- Round-number levels (nearest to close)
-- =========================
round_lvl = na_val
if show_round then
    local step = (round_step > 1e-9) and round_step or 1e-9
    round_lvl = round_to_step(close, step)
    plot(round_lvl, "Round Level", round_color, 1)
end

-- =========================
-- Swing highs/lows (fractals)
-- =========================
swing_hi = na_val
swing_lo = na_val
if show_swings then
    local L = swing_lr
    if bar_index > 2 * L then
        local piv = high[L]
        local is_sh = true
        for k = 1, L do
            if not (piv > high[L + k] and piv > high[L - k]) then
                is_sh = false
                break
            end
        end
        swing_hi = is_sh and piv or na_val

        local pivl = low[L]
        local is_sl = true
        for k = 1, L do
            if not (pivl < low[L + k] and pivl < low[L - k]) then
                is_sl = false
                break
            end
        end
        swing_lo = is_sl and pivl or na_val
    end

    plot(swing_hi, "Swing High", swing_color, 1)
    plot(swing_lo, "Swing Low",  swing_color, 1)
end

-- =========================
-- Donchian breakout (exclude current bar)
-- =========================
local lb = (donch_lookback > 2) and donch_lookback or 2
don_high_excl = highest(high, lb)[1]
don_low_excl  = lowest(low,  lb)[1]

brk_up   = high > don_high_excl and close > don_high_excl
brk_down = low  < don_low_excl  and close < don_low_excl

-- =========================
-- Liquidity proximity filter
-- =========================
liq_hi = show_session and session_high or na_val
liq_lo = show_session and session_low  or na_val
liq_rn = show_round   and round_lvl    or na_val
liq_sh = show_swings  and swing_hi     or na_val
liq_sl = show_swings  and swing_lo     or na_val

nearest_dist = min_dist(close, liq_hi, liq_lo, liq_rn, (liq_sh == liq_sh and liq_sh or liq_sl))
pass_liq     = (not require_liquidity) or (nearest_dist <= liq_proximity)

-- =========================
-- Plot signals
-- =========================
if show_all_breakouts then
    plot_shape(brk_up,   "Breakout Up (all)",   shape_style.square,  shape_size.small, dbg_color, shape_location.belowbar)
    plot_shape(brk_down, "Breakout Down (all)", shape_style.square,  shape_size.small, dbg_color, shape_location.abovebar)
end

if show_liq_signals then
    plot_shape(brk_up   and pass_liq, "Breakout Up (liq)",   shape_style.triangleup,   shape_size.large, up_color, shape_location.belowbar)
    plot_shape(brk_down and pass_liq, "Breakout Down (liq)", shape_style.triangledown, shape_size.large, dn_color, shape_location.abovebar)
end
