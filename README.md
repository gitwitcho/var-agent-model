# var-agent-model
An agent-based simulation to calculate market instability induced by value-at-risk models

Copyright (c) 2011-2015 Gilbert Peffer, Bàrbara Llacay

See LICENSE for redistribution information.

## Rationale of var-agent-model
<tt>Var-agent-model</tt> is a Java agent-based framework created to analyse the effect of most common trading strategies and value-at-risk (VaR) risk-management models in market dynamics. 

VaR models, which measure the maximum loss that an asset portfolio may suffer over a specific horizon and with a given level of confidence, are used by financial institutions around the world to manage their market risk. VaR models, as any other risk management system, are meant to keep financial institutions out of trouble, but some researchers have warned that the widespread use of VaR models creates negative externalities in financial markets, as it can feed market instability. Financial institutions usually set VaR limits to their traders or units, which are forced to reduce their positions when the risk exceeds these limits; when volatility increases, the VaR of trading portfolios also goes up and so traders can be forced to reduce their positions, but their sales can cause a price drop and so a new volatility upsurge, triggering further portfolio reductions. When many investors hold similar positions and also use the same type of risk management models, they may be forced to simultaneously sell the same assets, leading to an instabilising spiral.

<tt>Var-agent-model</tt> has been created to analyse the potential of VaR systems to amplify market disturbances with an agent-based model where traders set position limits and must reduce their positions when the VaR of their portfolio is above the limit.

## Description of the model
The market contains multiple assets – the number of assets is specified by the user, – each one in unrestricted supply. At each time step, the price is updated based on orders sent by traders, who change the composition of their investment portfolios in accordance with their respective valuation model and, in the case where portfolio risk limits apply, with a Value-at-Risk (VaR) model.

<b>Price formation</b>. The price for the stocks is set by a market maker in accordance to a linear formation rule: prices rise (fall) in the presence of over-demand (over-supply) by an amount that is inversely proportional to the liquidity of the traded security.

<b>Trading strategies</b>. Three trading strategies are implemented:
<ul>
<li> <em>Value strategy</em>: traders using this strategy receive an exogenous signal which is interpreted as the fundamental value of the stock, and decide to buy or sell depending on whether the asset is undervalued or overvalued with respect to the value. The positions of value traders are proportional to the difference of actual price to perceived fundamental value. However, an agent only enters a position when the different between price and value is above a given entry threshold. Fundamentalist investors keep their positions open until the price and the fundamental value converge, that is, until their difference is smaller than a given threshold. In that case, the agents liquidate their position. This strategy is based on the fundamental strategy implemented by J. Doyne Farmer and Shareen Joshi in “The price dynamics of common trading strategies” (<i>Journal of Economic Behavior & Organization</i>, Vol. 49 (2002), 149–171) </li>
<li> <em>Trend strategy</em>: traders using this strategy buy when the price shows an upward trend, and they sell when the price shows a downward trend. To detect the start of price trends, they compare a short- and a long-term moving average of past prices; when the two moving averages cross, it is the key time to buy or sell. Positions are proportional to the difference in slope between the two moving averages, because it is assumed that the greater this difference, the steeper the upward or downward price trend. Technical investors keep their positions open until they think that the price trend has begun to reverse. In order to detect a trend reversal, agents rely on the technique of channel breakouts: if the current price is the lowest in the last days, then the technical trader interprets that the price is going down, and any long position should be liquidated; if the current price is the highest in the last days, then the technical trader interprets that the price is going up, and any short position should be liquidated. </li>
<li> <em>Long-short strategy</em>: traders using this strategy track the spreads between different assets, and exploit the divergence of these spreads with respect to their historical mean. They open a long-short position when the spread between two stocks has diverged from its historical mean more than 2 standard deviations. In that case, a position is open simultaneously in the two assets that make part of the spread: a long position in the lower-price asset, and a short position in the higher-price asset. Positions are proportional to the difference between the spread and its historical mean. Long-short traders close their positions when the spread has converged to its historical mean – that is, until their difference is smaller than a given threshold, – or when it has diverged beyond 3 standard deviations. </li> </ul>

<b>VaR risk-management model</b>.Traders can optionally use a risk model based on VaR position limits. Assuming that for a given portfolio the variation of the portfolio value is distributed normally, then the maximum daily loss for the portfolio value with a given confidence level is proportional to the portfolio standard deviation and the portfolio value. When agents control their risk with the VaR model, they are assigned a limit to the maximum loss they can suffer. Then, before sending an order to the market, they calculate the VaR of the position they would have if the order became effective; in case the VaR of the desired position does not exceeds the VaR limit of the agent, the order is sent to the market to calculate the new price; otherwise, the agent needs to reduce the order to a level where the VaR of the resulting portfolio is below the limit.

<em>NOTE</em>: A detailed description of the model can be found in: Llacay, B. (2015). “El impacto de las técnicas VaR en los mercados financieros. Enfoque basado en la simulación multiagente.” PhD Dissertation, University of Barcelona.

## Parameters

## How to run a simulation
<b>Run configuration</b>. The <tt>***Simulation</tt> files contain the method <tt>main()</tt>. The simulation parameters are read from an xml file (see ‘Input’ subsection below); the launch configuration needs thus to be modified, so that the parameter file is passed as an argument when the simulation is executed.

<b>Edition of simulation file</b>. Inside the folder <a href="https://github.com/gitwitcho/var-agent-model/tree/master/agentsimulator/src/info/financialecology/finance/abm/sandbox">var-agent-model/agentsimulator/src/info/financialecology/finance/abm/sandbox/</a> there are different <tt>***Simulation</tt> files, which correspond to different stages in the code implementation. The last, fully-fledged version is <tt>TrendValueLSVarMultiAssetAbmSimulation.java</tt>.
Although the model parameters are read from an xml file (see ‘Input’ subsection below), several features need to be specified by hand in the simulation file:
<ul> <li>Experiments: if the user wants to run more than one experiment, to analyse how results are affected when a parameter changes (e.g. how does an increasing proportion of agents using VaR impact on market stability?), then the number of experiments <tt>numExp</tt> needs to be adjusted, and the value of the changing parameter needs to be specified for each experiment.</li>
<li> Variability of VaR limits: by default, the VaR limits used by the traders are constant. However, the model allows to study what happens when this limit is variable and procyclical (it increases (decreases) when volatility goes up (down)) or countercyclical (it decreases (increases) when volatility goes up (down)). This is done through the variable <tt>VariabilityVarLimit</tt></li>
<li> Use of stressed VaR: the model allows to explore the effect of using stressed VaR as introduced in Basel III Accord. By default, this is not used, but in case the user wants to activate this feature, this is done through the variable <tt>useStressedVar</tt>. </li></ul>

<b>Input</b>. The model parameters (see section ‘Parameters’ above) are specified in an xml file which is passed as an argument to the simulation file. Sample parameter files for <tt>TrendValueLSVarMultiAssetAbmSimulation.java</tt>can be found in the folder <a href="https://github.com/gitwitcho/var-agent-model/tree/master/agentsimulator/in/params/TrendValueLSVarAbm">var-agent-model/agentsimulator/in/params/TrendValueLSVarAbm/</a>.

<b>Output</b>. The results of the simulations (time series of price, volume, orders, VaR,... for each run) are extracted to CSV files for their posterior analysis.

Scripts in R have been created to analyse the simulation results. This analysis focuses on two main aspects: verification of the main stylised facts observed in stock markets (lack of return autocorrelation, volatility clustering, fat tails, etc.) to validate the model, and study of the market dynamics (price, value, agent performance, instability indicators, etc.). The R scripts can be found in the folder <a href="https://github.com/gitwitcho/var-agent-model/tree/master/agentsimulator/rscripts/sandbox%20(prod)">var-agent-model/agentsimulator/rscripts/sandbox (prod)/</a><tt>var-agent-model/agentsimulator/rscripts/sandbox (prod)/</tt>.
