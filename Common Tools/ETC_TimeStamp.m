function dstr = ETC_TimeStamp(date, style)
%Enter date as serial, vector, or string, style 1 is the 6digit day number
%style 2 is the 6 digit day number with the 6 digit time stamp

if nargin == 1
    style = 1;
end

if length(date)~=6
    date = datevec(date);
end

yy = num2str(date(1));
yy = yy(3:4);

mm = num2str(date(2));
if length(mm) == 1
    mm = ['0' mm];
end

dd = num2str(date(3));
if length(dd) == 1
    dd = ['0' dd];
end

hh = num2str(date(4));
if length(hh) == 1
    hh = ['0' hh];
end

mi = num2str(date(5));
if length(mi) == 1
    mi = ['0' mi];
end

ss = num2str(floor(date(6)));
if length(ss) == 1
    ss = ['0' ss];
end

dstr = [yy mm dd '_' hh mi ss];
if style == 1
    dstr = [yy mm dd];
end