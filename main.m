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

vixT = readtable("vix.csv")
vixT.datenum = datenum(vixT.Date)
vixT.year = year(vixT.datenum)
vixT.month = month(vixT.datenum)
vixT.day = day(vixT.datenum)
startDate = datenum('1997-01-02');
endDate = datenum('1997-12-31');
matureDate = datenum('2002-01-02');
vixExt = vixT(vixT.datenum >= startDate & vixT.datenum <= endDate,:);

vixExt.TimeToMaturity = matureDate - vixExt.datenum;
vixExt.blsPrice = NaN(length(vixExt.datenum), 1);

len = length(vixExt.datenum)
% Getting the call price and changes in value
for i = 1 : len
    vixExt.blsPrice(i) = blsprice(vixExt.sp500(i),600,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i)); % start from here next time
end

vixExt.delta = NaN(len, 1);
for i = 1 : len
    vixExt.delta(i) = blsdelta(vixExt.sp500(i),600,vixExt.r(i), vixExt.TimeToMaturity(i)/365, vixExt.sigma(i));
end

vixExt.cash = NaN(len, 1);
vixExt.cash(1) = vixExt.blsPrice(1) - vixExt.delta(1)*vixExt.sp500(1);
for i = 2 : len
    timeStep = vixExt.datenum(i) - vixExt.datenum(i-1);
    vixExt.cash(i) = vixExt.cash(i-1)*exp(vixExt.r(i-1) * timeStep/365) - (vixExt.delta(i) - vixExt.delta(i-1))*vixExt.sp500(i);
end

vixExt.hedgePortValue = NaN(len, 1);
for i = 1: len
    vixExt.hedgePortValue(i) = vixExt.cash(i) + vixExt.delta(i)*vixExt.sp500(i);
end

% Creating the synthetic option with delta hedging
plot(vixExt.datenum, vixExt.blsPrice)

ltcm = table(vixExt.datenum, 'VariableNames', {'datenum'});
ltcm.hedgePL = vixExt.hedgePortValue - vixExt.hedgePortValue(1);
ltcm.clientPL = vixExt.blsPrice - vixExt.blsPrice(1);
ltcm.netPortfolioValue = ltcm.hedgePL - ltcm.clientPL;

vixExt(1:3,:)
ltcm(1:3,:)
