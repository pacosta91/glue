function percentileValue = getPercentileValue(v, percentile)
% percentile - (dbl) - Any number from 0 to 100

% N = length(v);
% interval = 1/length(v);
% percentilearray(1) = interval/2; percentilearray(N) = 1 - interval/2;
% for i=2:(N-1)
%     percentilearray(i) = percentilearray(i-1) + interval;
% end

% This is a short version of the above code that optimizes MATLAB's
% internal functions
percentileValue = interp1(linspace(0.5/length(v), 1-0.5/length(v), length(v))', sort(v), percentile*0.01, 'spline');

end

