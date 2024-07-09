function s = dec2let(d)
list = 'A':'Z';
ext = '';
if d > 702
    ext = list(floor((d-26)/676)-(floor((d-26)/676)==(d-26)/676));
    d = d-(floor((d-26)/676)-(floor((d-26)/676)==(d-26)/676))*676;
end
if d > 26
    s = strcat(ext,list(floor(d/26)-(floor(d/26)==d/26)),list(mod(d,26)+26*(floor(d/26)==d/26)));
else
    s = list(mod(d,26)+26*(floor(d/26)==d/26));
end
end