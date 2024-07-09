function cov = covariance(X, Y)
if nargin == 1
    %autocovariance
    Y = X;
end

cov = sum(X.*Y)/length(X)-sum(X)*sum(Y)/length(X)/length(X);