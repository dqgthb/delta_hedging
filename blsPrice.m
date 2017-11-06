function [call, put] = blsPrice(price, strike, rf, time, vol)
    
S = price;
X = strike;
r = rf;
sigma = vol;
T = time;

d1 = (log(S/X) + (r + 0.5*sigma^2) * T) / (sigma * sqrt(T));
d2 = (log(S/X) + (r - 0.5*sigma^2) * T) / (sigma * sqrt(T));

call = S * normcdf(d1) - X*exp(-r*T) * normcdf(d2);
%put = X*exp(-r*T) * normcdf(-d2)- S * normcdf(-d1);

end
