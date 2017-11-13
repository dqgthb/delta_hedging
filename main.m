% Program:  LTCM Delta Hedging
% Group: Dexter
% Authors:
%           262017254 Pegah Ehsani
%           260630190 Deon Kim
%           260566889 Jaskrit Singh
%
% Last Modified: 2017-11-12
%
% Course: Applied Quantitative Finance
%
% Project: LTCM Delta Hedging Assingment
%
% Purpose of the program:
% Calculate BSM price, delta, gamma, moneyness, cash balance for a call option, in order for LTCM to sell the options at markup-adjusted price and to hedge the risks by replicating the sold option by performing delta hedging.
%
% Files Used:
%           vix.csv
% Inputs:
%   - switch variables : These must be user-defined before the code runs. Can be found in %%% switch variables %%% section right below.
%       - question : switch variable controlling the overall functionality of code. If question = 1, the code generates solution for question 1 of the assignment. Likewise with question = 2.
%       - isVolConst :switch variable. If isVolConst = 1, all values of the column vix.sigma is set as constVol, which is another user-defined switch variable.
%       - constVol : switch variable. If isVolConst = 1, vix.sigma is set to this value. Users are free to change this value to whatever they want to test with. If isVolConst = 0, this has no effect on the code.
%       - isRfConst : switch variable. If isRfConst = 1, all values of the column vix.rf is set to constRf.
%       - constRf : switch variable. If isRfConst = 1, vix.rf is set to this value. Users are free to change this value to whatever value they want to test with. If isRfConst = 0, this has no effect on the code.
%       - isPlotOn : switch variable. if isPlotOn = 1, the code creates 2x2 plots. If 0, the code does not generate the plot. This is for a performance reason, as sometimes generating plots take a lot of time while executing the code.
% Dataset descriptions:
% Tables:
%       - vixT : a matlab table containing raw information of vix.csv and additional datenum variables.
%       - vixExt : a matlab table vixT excerpt starting from 'startDate' to 'endDate'. These two values depend on the switch variable 'question'.
%       - ltcm : a matlab table containing datenum, hedgePL, clientPL and netPortfolioValue columns. Answer to cody.
%
% Outputs:
%
%           4 plot:
%                   - Client P&L, Hedge P&L, cash account evolution over time
%                   - Delta and S&P500 over time
%                   - Gamma and moneyness over
%                   - Vega vixT over time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% switch variables %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
question = 2 % 1 or 2
isVolConst = 0 % 0 or 1
constVol = 0.2 % any reasonable value
isRfConst = 0 % 0 or 1
constRf = 0.05 % any reasonable value

isPlotOn = true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read data and add dates
vixT = readtable("vix.csv");
vixT.datenum = datenum(vixT.Date);
vixT.year = year(vixT.datenum);
vixT.month = month(vixT.datenum);
vixT.day = day(vixT.datenum);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Choose between Q1 and Q2 with switch variable 'question' above.
if question == 1
startDate = datenum('1997-01-02');
endDate = datenum('1997-12-31');
matureDate = datenum('2002-01-02');
strike = 600;
markup = 1.0;
elseif question == 2
startDate = datenum('1998-01-05');
endDate = datenum('1998-12-31');
matureDate = datenum('2003-01-06');
strike = 1000;
markup = 1.2;
else
    disp("which question?");
end

% make volatility constant if isVolConst = 1
if isVolConst
    vixT.sigma = ones(length(vixT.sigma), 1) * constVol;
end

% make risk free constant if isVolConst = 1
if isRfConst
    vix.r = ones(length(vixT.sigma), 1) * constRf;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% prepare table
% vix Extract from startDate to endDate
vixExt = vixT(vixT.datenum >= startDate & vixT.datenum <= endDate,:);
len = length(vixExt.datenum);
vixExt.TimeToMaturity = matureDate - vixExt.datenum;
vixExt.blsPrice = NaN(len, 1);
vixExt.delta = NaN(len, 1);
vixExt.gamma = NaN(len,1);
vixExt.vega = NaN(len,1);
vixExt.moneyness = NaN(len,1);
vixExt.cash = NaN(len, 1);
vixExt.hedgePortValue = NaN(len, 1);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% markup-adjusted BSM price
blsPriceMarkup = blsprice(vixExt.sp500(1),strike,vixExt.r(1), vixExt.TimeToMaturity(1)/365, markup * vixExt.sigma(1)); % start from here next time

% calculate bls price, delta, gamma, vega and moneyness for the given date range.
for i = 1 : len
    vixExt.blsPrice(i) = blsprice(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i)); % start from here next time
    vixExt.delta(i) = blsdelta(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.gamma(i) = blsgamma(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.vega(i) = blsvega(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.moneyness(i) = vixExt.sp500(i)/strike;
end

% calculate initial cash
vixExt.cash(1) = blsPriceMarkup - vixExt.delta(1)*vixExt.sp500(1); % Initial cash
% calculate cash account for the rest. (1+rf)*(existing cash) - (cash needed to buy new stocks)
for i = 2 : len
    timeStep = vixExt.datenum(i) - vixExt.datenum(i-1);
    vixExt.cash(i) = vixExt.cash(i-1)*exp(vixExt.r(i-1) * timeStep/365) - (vixExt.delta(i) - vixExt.delta(i-1))*vixExt.sp500(i);
end

% Hedge Portfolio Value = cash account + value of stocks we own at time = i.
for i = 1: len
    vixExt.hedgePortValue(i) = vixExt.cash(i) + vixExt.delta(i)*vixExt.sp500(i);
end

% Prepare ltcm table for cody
ltcm = table(vixExt.datenum, 'VariableNames', {'datenum'});
ltcm.hedgePL = vixExt.hedgePortValue - vixExt.hedgePortValue(1); % value of stocks and cash LTCM owns -  the revenue from option sold to client at t=1
ltcm.clientPL = vixExt.blsPrice - vixExt.blsPrice(1); % value of option client owns - the cost of option at t=1
ltcm.netPortfolioValue = ltcm.hedgePL - ltcm.clientPL;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Show 4 plots 2x2
if isPlotOn
    figure;
    subplot(2,2,1);
    hold on
    plot(vixExt.datenum, ltcm.clientPL)
    plot(vixExt.datenum, ltcm.hedgePL)
    plot(vixExt.datenum, ltcm.netPortfolioValue)
    title("PLs and Net Portfolio Value")
    legend('client PL', 'hedge PL', 'Net Portfolio Value');
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yymmdd', 'keepticks');

    subplot(2,2,2);
    customPlotyy(vixExt.datenum, vixExt.delta, vixExt.sp500);
    title('delta and sp500')
    legend('delta', 'sp500')

    subplot(2,2,3);
    customPlotyy(vixExt.datenum, vixExt.gamma, vixExt.moneyness);
    title('gamma and moneyness')
    legend('gamma', 'moneyness')

    subplot(2,2,4);
    customPlotyy(vixExt.datenum, vixExt.vega, vixExt.sigma);
    title('vega and sigma')
    legend('vega', 'sigma')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plotyy deprecated in MATLAB document, so create a simple customized plotyy on our own.
function [] = customPlotyy(xaxis, y1axis, y2axis)
    yyaxis left
    plot(xaxis, y1axis)
    yyaxis right
    plot(xaxis, y2axis)
    numTicks = 12;
    set(gca, 'XTick', linspace(xaxis(1), xaxis(end), numTicks));
    datetick('x', 'yymmdd', 'keepticks');
end
