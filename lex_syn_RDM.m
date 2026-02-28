clc
clear

Descriptive_Lexical_RDM = load('/path/');
Descriptive_Lexical_RDM = Descriptive_Lexical_RDM.stimulusRDM;   
Descriptive_Syntactic_RDM = load('/path/');
Descriptive_Syntactic_RDM = Descriptive_Syntactic_RDM.stimulusRDM; 

index_matrix = tril(ones(size(Descriptive_Lexical_RDM)),-1);   

Descriptive_Lexical_RDM_Vector = Descriptive_Lexical_RDM(logical(index_matrix));   
Descriptive_Syntactic_RDM_Vector = Descriptive_Syntactic_RDM(logical(index_matrix));   

[r, p] = corr(Descriptive_Lexical_RDM_Vector, Descriptive_Syntactic_RDM_Vector, 'Type', 'Pearson');

fprintf('Pearson correlation coefficient: %.4f\n', r);
fprintf('p-value: %.4f\n', p);