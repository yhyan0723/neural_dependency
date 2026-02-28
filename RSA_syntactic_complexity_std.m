clc;    
clear;

subdir = [1:12];

filebase = '/path/sub'; 
groupbase = '/path'; 

Descriptive_Syntactic_RDM = load('/path/MDD_std_RDM.mat');   
Descriptive_Syntactic_RDM = Descriptive_Syntactic_RDM.stimulusRDM;  
  
ROIs = {'IFG_L', 'IFG_R', 'IFGorb_L', 'IFGorb_R', 'MFG_L', 'MFG_R', 'AntTemp_L', 'AntTemp_R', 'PostTemp_L', 'PostTemp_R'};   
  
results = struct;  
  
for i = subdir   
    for j = 1:length(ROIs)
        subFile = [filebase num2str(i, '%02d') '/Results_' ROIs{j} '/dissimilarity_matrix.mat'];   
  
        load(subFile);   
  
        index_matrix = tril(ones(size(dissimilarity_matrix)),-1);   
  
        Neural_RDM_Vector = dissimilarity_matrix(logical(index_matrix));   
        Descriptive_Syntactic_RDM_Vector = Descriptive_Syntactic_RDM(logical(index_matrix));   
  
        X = [Descriptive_Syntactic_RDM_Vector];   
  
        lm = fitlm(X, Neural_RDM_Vector, 'VarNames', {'Syntactic', 'Neural'});   
  
        results(j).ROI = ROIs{j};  
        results(j).Syntactic_beta = lm.Coefficients.Estimate(2);  
        results(j).Syntactic_SE = lm.Coefficients.SE(2);  
        results(j).Syntactic_tStat = lm.Coefficients.tStat(2);  
        results(j).Syntactic_pValue = lm.Coefficients.pValue(2);  
        results(j).Model_RMSE = lm.RMSE;  
        results(j).Model_Rsquared = lm.Rsquared.Ordinary;  
        results(j).Model_Adjusted_Rsquared = lm.Rsquared.Adjusted;  
        results(j).Model_pValue = coefTest(lm);  
    end  
  
    resultsTable = struct2table(results);  
    writetable(resultsTable, [groupbase '/sub-' num2str(i, '%02d') '_multiple_regression.xlsx']);  
end