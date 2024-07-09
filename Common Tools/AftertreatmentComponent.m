function component = AftertreatmentComponent(n)
    switch n
        case '0'
            component = 'NONE';
        case '1'
            component = 'DOC';
        case '2'
            component = 'DPF';
        case '3'
            component = 'DNX';
        case '4'
            component = 'CAT';
    end
end