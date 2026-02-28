install.packages(c("readxl", "psych"))  
library(readxl)  
library(psych)  

data <- read_excel("/path/")  

dl_summary <- summary(data$DL)  
dl_describe <- describe(data$DL)  

sl_summary <- summary(data$SL)  
sl_describe <- describe(data$SL)  

mdd_summary <- summary(data$MDD)  
mdd_describe <- describe(data$MDD)  

print(paste("DL column summary: ", dl_summary))  
print(paste("DL column description: ", dl_describe))  

print(paste("SL column summary: ", sl_summary))  
print(paste("SL column description: ", sl_describe))  

print(paste("MDD column summary: ", mdd_summary))  
print(paste("MDD column description: ", mdd_describe))  

library(readxl)  
library(corrplot)  
library(ggplot2)  
library(reshape2)  

data <- read_excel("/path/")    

data_selected <- data[, c("DL", "SL", "MDD")]    

correlation_matrix <- cor(data_selected, method = "pearson")    

corrplot(correlation_matrix, method = "circle",     
         addCoef.col = "white", 
         number.cex = 1.5, 
         number.digits = 3, 
         sig.level = 0.05, 
         insig = "blank", 
         cl.pos = "r", 
         tl.col = "black", 
         tl.cex = 1.5, 
         cl.cex = 1.2  
)