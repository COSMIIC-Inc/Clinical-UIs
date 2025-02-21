function f_clipboard(d)

size_d = size(d);
str = '';
for i = 1:size_d(1)
    for j = 1:size_d(2)
        if j == size_d(2)
            str = sprintf('%s%f',str,d(i,j));
        else
            str = sprintf('%s%f\t',str,d(i,j));
        end
    end
    str = sprintf('%s\n',str);
end

clipboard ('copy',str);

end