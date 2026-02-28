clc;
clear;

subdir = 1:12;

filebase = '/path/to/neural_rdm/sub';
groupbase = '/path/to/output_directory/';

predictiveRDM = load('/path/to/model_rdm.mat');
predictiveRDM = predictiveRDM.stimulusRDM;

ROIs = {'IFG_L', 'IFG_R', 'IFGorb_L', 'IFGorb_R', 'MFG_L', 'MFG_R', 'AntTemp_L', 'AntTemp_R', 'PostTemp_L', 'PostTemp_R'};

for j = 1:length(ROIs)

    spearman_correlations = [];

    for i = subdir
        subFile = [filebase '-' num2str(i, '%02d') '/Results_' ROIs{j} '/dissimilarity_matrix.mat'];

        load(subFile);

        index_matrix = tril(ones(size(dissimilarity_matrix)),-1);

        rdm_avg_vector = dissimilarity_matrix(logical(index_matrix));
        rdm_predictive_vector = predictiveRDM(logical(index_matrix));

        disp('RDM Average Vector:');
        disp(rdm_avg_vector);
        disp('Predictive RDM Vector:');
        disp(rdm_predictive_vector);

        [rho, p] = corr(rdm_avg_vector, rdm_predictive_vector, 'Type', 'Spearman');

        z_val = 0.5 * log((1 + rho) / (1 - rho));

        columnNames = {['RSA_' ROIs{j}], 'p_value'};

        resultsTable = table(z_val,p,'VariableNames', columnNames);

        if ~exist([groupbase ROIs{j}], 'dir')
            mkdir([groupbase ROIs{j}]);
        end

        save([groupbase ROIs{j} '/RSA_zscores_sub-' num2str(i, '%02d') '.mat'], 'resultsTable');
    end
end