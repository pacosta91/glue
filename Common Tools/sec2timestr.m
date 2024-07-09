function timestr = sec2timestr(sec)
%SEC2TIMESTR sec2timestr(sec) converts a time measurement from seconds into a human readable string.

d = floor(sec/86400);
sec = sec - d*86400;
h = floor(sec/3600);
sec = sec - h*3600;
m = floor(sec/60);
sec = sec - m*60;
s = floor(sec);

if d > 0
	if d > 2
		timestr = sprintf('%d day',d+round(h/24));
	else
		timestr = sprintf('%d day, %d hr',d,h+round(m/60));
	end
elseif h > 0
	if h > 3
		timestr = sprintf('%d hr',h+round(m/60));
	else
		timestr = sprintf('%d hr, %d min',h,m+round(s/60));
	end
elseif m > 0
	if m > 20
		timestr = sprintf('%d min',m+round(s/60));
	else
		timestr = sprintf('%d min, %d sec',m,s);
	end
else
	timestr = sprintf('%d sec',s);
end
