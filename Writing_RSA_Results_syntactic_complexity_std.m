clc
clear

AllData = table();

for i = 1:12
    filename = sprintf('/path/sub-%02d_multiple_regression.xlsx', i);
      
    data = readtable(filename);
      
    IFG_L_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'IFG_L'));  
    IFG_R_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'IFG_R'));  
    IFGorb_L_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'IFGorb_L'));  
    IFGorb_R_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'IFGorb_R'));  
    MFG_L_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'MFG_L'));  
    MFG_R_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'MFG_R'));  
    AntTemp_L_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'AntTemp_L'));  
    AntTemp_R_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'AntTemp_R'));  
    PostTemp_L_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'PostTemp_L'));  
    PostTemp_R_Syntactic = data.Syntactic_beta(strcmp(data.ROI, 'PostTemp_R'));  
  
    Subjects = {sprintf('sub-%02d', i)};  
    T = table(Subjects, IFG_L_Syntactic, IFG_R_Syntactic, IFGorb_L_Syntactic, IFGorb_R_Syntactic, MFG_L_Syntactic, MFG_R_Syntactic, AntTemp_L_Syntactic, AntTemp_R_Syntactic, PostTemp_L_Syntactic, PostTemp_R_Syntactic);  
      
    AllData = [AllData; T];  
end  
  
writetable(AllData, '/path/Results_Betas.xlsx');