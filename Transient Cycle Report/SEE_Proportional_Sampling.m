function SEE = SEE_Proportional_Sampling(SampleFlowRate, TotalFlowRate)

slope = covariance(TotalFlowRate, SampleFlowRate)/covariance(TotalFlowRate);
intercept = mean(SampleFlowRate)-slope*mean(TotalFlowRate);

errors_squared = (slope*TotalFlowRate+intercept-SampleFlowRate).^2;

errors_squared = sort(errors_squared);

errors_squared = errors_squared(1:floor(0.95*length(SampleFlowRate))); % eliminate 5% of points per §1065.545(a)

SEE = sqrt(sum(errors_squared)/(floor(0.95*length(SampleFlowRate)-2)));