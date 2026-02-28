data = [
    % behavioral linguistic complexity
];

n = length(data);
stimulusRDM = zeros(n, n);
for i = 1:n
    for j = 1:n
        stimulusRDM(i, j) = abs(data(i) - data(j));
    end
end

save_path = '/path/';  
save(save_path, 'stimulusRDM')