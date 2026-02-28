clc;    
clear;

subdir = [1:12];

filebase = '/path/sub';
groupbase = '/path/';

Predictive_Lexical_RDM = load('/path/MWF_std_RDM.mat');   
Predictive_Lexical_RDM = Predictive_Lexical_RDM.stimulusRDM;   
Predictive_Syntactic_RDM = load('/path/MDD_std_RDM.mat');   
Predictive_Syntactic_RDM = Predictive_Syntactic_RDM.stimulusRDM;  

ROIs = {'IFG_L', 'IFG_R', 'IFGorb_L', 'IFGorb_R', 'MFG_L', 'MFG_R', 'AntTemp_L', 'AntTemp_R', 'PostTemp_L', 'PostTemp_R'};   

results = struct;  

for i = subdir   
    for j = 1:length(ROIs)
        subFile = [filebase num2str(i, '%02d') '/Results_' ROIs{j} '/dissimilarity_matrix.mat'];   

        load(subFile);   

        index_matrix = tril(ones(size(dissimilarity_matrix)),-1);   

        Neural_RDM_Vector = dissimilarity_matrix(logical(index_matrix));   
        Predictive_Lexical_RDM_Vector = Predictive_Lexical_RDM(logical(index_matrix));   
        Predictive_Syntactic_RDM_Vector = Predictive_Syntactic_RDM(logical(index_matrix));   

        Interaction_Vector = Predictive_Lexical_RDM_Vector .* Predictive_Syntactic_RDM_Vector;   

        X = [Predictive_Lexical_RDM_Vector, Predictive_Syntactic_RDM_Vector, Interaction_Vector];   

        lm = fitlm(X, Neural_RDM_Vector, 'VarNames', {'Lexical', 'Syntactic', 'Interaction', 'Neural'});   

        results(j).ROI = ROIs{j};  
        results(j).Lexical_beta = lm.Coefficients.Estimate(2);  
        results(j).Lexical_SE = lm.Coefficients.SE(2);  
        results(j).Lexical_tStat = lm.Coefficients.tStat(2);  
        results(j).Lexical_pValue = lm.Coefficients.pValue(2);  
        results(j).Syntactic_beta = lm.Coefficients.Estimate(3);  
        results(j).Syntactic_SE = lm.Coefficients.SE(3);  
        results(j).Syntactic_tStat = lm.Coefficients.tStat(3);  
        results(j).Syntactic_pValue = lm.Coefficients.pValue(3);  
        results(j).Interaction_beta = lm.Coefficients.Estimate(4);  
        results(j).Interaction_SE = lm.Coefficients.SE(4);  
        results(j).Interaction_tStat = lm.Coefficients.tStat(4);  
        results(j).Interaction_pValue = lm.Coefficients.pValue(4);  
        results(j).Model_RMSE = lm.RMSE;  
        results(j).Model_Rsquared = lm.Rsquared.Ordinary;  
        results(j).Model_Adjusted_Rsquared = lm.Rsquared.Adjusted;  
        results(j).Model_pValue = coefTest(lm);  
    end  

    resultsTable = struct2table(results);  
    writetable(resultsTable, [groupbase 'sub-' num2str(i, '%02d') '_multiple_regression.xlsx']);  
end