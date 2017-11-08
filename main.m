% Program:  LTCM Delta Hedging
% Group: Dexter
% Authors:
%           262017254 Pegah Ehsani
%           260630190 Deon Kim
%           260566889 Jaskrit Singh
%
% Last Modified: 2017-10
%
% Course: Applied Quantitative Finance
%
% Project: LTCM Delta Hedging Assingment
%
% Purpose of the program:
%
% Files Used:
%           vix.csv
% Inputs:
%
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

% switch variables
question = 1;

isVolConst = true;
constVol = 0.2;
isRfConst = true;
constRf = 0.05;

plotsOn = false;
subplotsOn = false;
cusSubplotOn = true;

% read data and add dates
vixT = readtable("vix.csv");
vixT.datenum = datenum(vixT.Date);
vixT.year = year(vixT.datenum);
vixT.month = month(vixT.datenum);
vixT.day = day(vixT.datenum);

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

if isVolConst
    vixT.sigma = ones(length(vixT.sigma), 1)*constVol;
end


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


blsPriceMarkup = blsprice(vixExt.sp500(1),strike,vixExt.r(1), vixExt.TimeToMaturity(1)/365, markup * vixExt.sigma(1)); % start from here next time

% Getting the call price and changes in value
for i = 1 : len
    vixExt.blsPrice(i) = blsprice(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i)); % start from here next time
    vixExt.delta(i) = blsdelta(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.gamma(i) = blsgamma(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.vega(i) = blsvega(vixExt.sp500(i),strike,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
    vixExt.moneyness(i) = vixExt.sp500(i)/strike;
end

%vixExt.cash(1) = vixExt.blsPrice(1) - vixExt.delta(1)*vixExt.sp500(1);
vixExt.cash(1) = blsPriceMarkup - vixExt.delta(1)*vixExt.sp500(1);
for i = 2 : len
    timeStep = vixExt.datenum(i) - vixExt.datenum(i-1);
    vixExt.cash(i) = vixExt.cash(i-1)*exp(vixExt.r(i-1) * timeStep/365) - (vixExt.delta(i) - vixExt.delta(i-1))*vixExt.sp500(i);
end

for i = 1: len
    vixExt.hedgePortValue(i) = vixExt.cash(i) + vixExt.delta(i)*vixExt.sp500(i);
end

ltcm = table(vixExt.datenum, 'VariableNames', {'datenum'});
ltcm.hedgePL = vixExt.hedgePortValue - vixExt.hedgePortValue(1);
ltcm.clientPL = vixExt.blsPrice - vixExt.blsPrice(1);
ltcm.netPortfolioValue = ltcm.hedgePL - ltcm.clientPL;

vixExt(1:3,:)
ltcm(1:3,:)

% since creating plots takes some time, I'll make a switch to turn it on and off.
if plotsOn
    plot(vixExt.datenum, ltcm.clientPL)
    hold on
    plot(vixExt.datenum, ltcm.hedgePL)
    plot(vixExt.datenum, ltcm.netPortfolioValue)
    datetick('x', 'yyyymmdd')

    % plot 2
    figure
    yyaxis left
    plot(vixExt.datenum, vixExt.delta)
    yyaxis right
    plot(vixExt.datenum, vixExt.sp500)
    datetick('x', 'yyyymmdd')

    % plot 3
    figure
    yyaxis left
    plot(vixExt.datenum, vixExt.gamma)
    yyaxis right
    plot(vixExt.datenum, vixExt.moneyness)
    datetick('x', 'yyyymmdd')

    % plot 4
    figure
    yyaxis left
    plot(vixExt.datenum, vixExt.vega)
    yyaxis right
    plot(vixExt.datenum, vixExt.sigma)
    datetick('x', 'yyyymmdd')

    % plot 5 (custom)
    %figure
    %plot(vixExt.datenum, ltcm.hedgePL)
    %hold on
    %plot(vixExt.datenum, vixExt.sp500)

    % plot(vixExt.datenum, vixExt.moneyness)
end

if subplotsOn
    subplot(2,2,1);
    plot(vixExt.datenum, ltcm.clientPL)
    hold on
    plot(vixExt.datenum, ltcm.hedgePL)
    plot(vixExt.datenum, ltcm.netPortfolioValue)
    title("PLs and Net Portfolio Value")
    legend('client PL', 'hedge PL', 'Net Portfolio Value');
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');

    subplot(2,2,2);
    yyaxis left
    plot(vixExt.datenum, vixExt.delta)
    yyaxis right
    plot(vixExt.datenum, vixExt.sp500)
    title('delta and sp500')
    legend('delta', 'sp500')
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');

    subplot(2,2,3);
    yyaxis left
    plot(vixExt.datenum, vixExt.gamma)
    yyaxis right
    plot(vixExt.datenum, vixExt.moneyness)
    title('gamma and moneyness')
    legend('gamma', 'moneyness')
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');

    subplot(2,2,4);
    yyaxis left
    plot(vixExt.datenum, vixExt.vega)
    yyaxis right
    plot(vixExt.datenum, vixExt.sigma)
    title('vega and sigma')
    legend('vega', 'sigma')
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');

end

if cusSubplotOn
    figure
    subplot(2,2,1);
    plot(vixExt.datenum, ltcm.clientPL)
    hold on
    plot(vixExt.datenum, ltcm.hedgePL)
    plot(vixExt.datenum, ltcm.netPortfolioValue)
    title("PLs and Net Portfolio Value")
    legend('client PL', 'hedge PL', 'Net Portfolio Value');
    numTicks = 12;
    set(gca, 'XTick', linspace(vixExt.datenum(1), vixExt.datenum(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');

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

function [] = customPlotyy(xaxis, y1axis, y2axis)
    yyaxis left
    plot(xaxis, y1axis)
    yyaxis right
    plot(xaxis, y2axis)
    numTicks = 12;
    set(gca, 'XTick', linspace(xaxis(1), xaxis(end), numTicks));
    datetick('x', 'yyyy-mm-dd', 'keepticks');
end
