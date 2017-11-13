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
% Calculate BSM price, delta, gamma, moneyness, cash balance for a call option, in order for LTCM to sell the options at markup-adjusted price and to hedge the risks by replicating the sold option by performing delta hedging
%
% Files Used:
%           vix.csv
% Inputs:
%
% Dataset descriptions:
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

% Choose between Q1 and Q2.
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
for i = 1 : len
    % calculate bls price, delta, gamma, vega and moneyness for the given date range.
    vixExt.blsPrice(i) = blsprice(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i)); % start from here next time
    vixExt.delta(i) = blsdelta(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.gamma(i) = blsgamma(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.vega(i) = blsvega(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.moneyness(i) = vixExt.sp500(i)/strike;
end

vixExt.cash(1) = blsPriceMarkup - vixExt.delta(1)*vixExt.sp500(1); % Initial cash
for i = 2 : len
    timeStep = vixExt.datenum(i) - vixExt.datenum(i-1);
    vixExt.cash(i) = vixExt.cash(i-1)*exp(vixExt.r(i-1) * timeStep/365) - (vixExt.delta(i) - vixExt.delta(i-1))*vixExt.sp500(i);
end

% Hedge Portfolio Value
for i = 1: len
    vixExt.hedgePortValue(i) = vixExt.cash(i) + vixExt.delta(i)*vixExt.sp500(i);
end

% Prepare ltcm table for cody
ltcm = table(vixExt.datenum, 'VariableNames', {'datenum'});
ltcm.hedgePL = vixExt.hedgePortValue - vixExt.hedgePortValue(1);
ltcm.clientPL = vixExt.blsPrice - vixExt.blsPrice(1);
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

% plotyy deprecated in MATLAB document, so create a simple customized plot
function [] = customPlotyy(xaxis, y1axis, y2axis)
    yyaxis left
    plot(xaxis, y1axis)
    yyaxis right
    plot(xaxis, y2axis)
    numTicks = 12;
    set(gca, 'XTick', linspace(xaxis(1), xaxis(end), numTicks));
    datetick('x', 'yymmdd', 'keepticks');
end
