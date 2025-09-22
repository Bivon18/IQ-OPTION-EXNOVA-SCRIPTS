instrument {
    name = "CCI & Stochastic Momentum",
    short_name = "CCI_Stoch_Momentum",
    overlay = false,
    icon = "indicators:MomentumOscillator"
}

--  Inputs
cciPeriod     = input(14, "CCI Period")
stochKPeriod  = input(14, "%K Period")
stochDPeriod  = input(3, "%D Period")
obLevel       = input(80, "Overbought Level")
osLevel       = input(20, "Oversold Level")

--  Color Inputs
cciColor      = input("blue", "CCI Line Color", input.color)
kColor        = input("orange", "%K Line Color", input.color)
dColor        = input("purple", "%D Line Color", input.color)
obColor       = input("red", "Overbought Line", input.color)
osColor       = input("green", "Oversold Line", input.color)
upArrowColor  = input("lime", "Uptrend Arrow", input.color)
downArrowColor= input("red", "Downtrend Arrow", input.color)

--  Calculations
cciVal        = cci(close, cciPeriod)
stochK        = stoch_k(close, high, low, stochKPeriod)
stochD        = stoch_d(close, high, low, stochDPeriod)

--  Plots
plot(cciVal, "CCI", cciColor)
plot(stochK, "%K", kColor)
plot(stochD, "%D", dColor)
hline(100, "CCI OB", obColor)
hline(-100, "CCI OS", osColor)
hline(obLevel, "Stoch OB", obColor)
hline(osLevel, "Stoch OS", osColor)

--  Delta Logic
cci_up        = cciVal - cciVal[1] > 0
cci_down      = cciVal - cciVal[1] < 0
stochK_up     = stochK - stochK[1] > 0
stochK_down   = stochK - stochK[1] < 0

--  Signal Logic
isUptrend     = cciVal > 100 and cci_up and stochK_up and crossover(stochK, stochD)
isDowntrend   = cciVal < -100 and cci_down and stochK_down and crossunder(stochK, stochD)

--  Arrow Plots
plot_shape(isUptrend, "Momentum Buy", shape_style.arrowup, shape_size.large, upArrowColor, shape_location.belowbar)
plot_shape(isDowntrend, "Momentum Sell", shape_style.arrowdown, shape_size.large, downArrowColor, shape_location.abovebar)

--  Commentary (Optional)
if isUptrend then
    message("Momentum Shift: CCI rising above 100 & StochK gaining   Bullish bias forming")
end
if isDowntrend then
    message("Momentum Shift: CCI falling below -100 & StochK weakening   Bearish bias forming")
end
