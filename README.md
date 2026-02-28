README: RSA Analysis of Syntactic and Lexical Processing
This repository contains code for Representational Similarity Analysis (RSA) examining neural representations of syntactic and lexical processing. 

Repository Structure
Neural_Calculate_RDM.m: Computes neural dissimilarity matrices for each ROI and participant
Correlation_RSA_Neural.m: Calculates Spearman correlations
Behavioral_Calculate_RDM.m: Constructs RDMs from behavioral linguistic complexity measures
RSA_syntactic_complexity_std.m: Performs RSA on syntactic RDMs for each ROI
Multiple_Regression_RSA_with_Interaction.m: Runs multiple regression RSA including lexical, syntactic predictors and their interaction
Writing_RSA_Results_syntactic_complexity_std.m: Aggregates syntactic regression results across participants
Writing_Multiple_Regression_Results_with_Interaction.m: Aggregates multiple regressionRSA results across participants
lex_syn_RDM.m: Computes correlation
Barplot_RSA_syntactic_complexity_std.R: Creates plots for syntactic regression betas
Barplot_Multiple_Regression_RSA_with_Interaction.R: Visualizes beta coefficients from multiple regression RSA models
Descriptive_Pearson.R: Generates correlation matrix of behavioral measures
