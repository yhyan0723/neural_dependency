library(readxl)  
library(ggplot2)  
library(ggpubr)  
library(ggbeeswarm)  
library(extrafont)  
library(writexl)  
library(tidyr)

font_import(pattern = "Times New Roman", prompt = FALSE)

syntacticColor <- rgb(255/255, 150/255, 0/255, alpha = 1) 
barColor1 <- rgb(4/255, 73/255, 255/255, alpha = 1)     
scatterColor <- rgb(0/255, 150/255, 0/255, alpha = 1)   

filename1 <- "/path/"  
data1 <- read_excel(filename1)  

data_long1 <- tidyr::pivot_longer(data1, -Subjects, names_to = "ROI", values_to = "Value")  

data_long1$ROI <- factor(data_long1$ROI, levels = colnames(data1)[-1])  

significance <- sapply(levels(data_long1$ROI), function(roi) {  
  p_value <- t.test(data_long1[data_long1$ROI == roi, "Value"], mu = 0)$p.value  
  return(ifelse(p_value < 0.05, "*", ""))  
})  

p_values <- sapply(levels(data_long1$ROI), function(roi) {  
  p_value <- t.test(data_long1[data_long1$ROI == roi, "Value"], mu = 0)$p.value  
  return(p_value)  
})  

L1 <- ggplot(data_long1, aes(x = ROI, y = Value)) +  
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey") +  
  geom_vline(xintercept = seq(3.5, 27.5, by = 3), color = "grey") +  
  theme_bw() +  
  theme(axis.text.x = element_text(angle = 45, hjust = 1, family = "Times New Roman"),  
        axis.text.y = element_text(family = "Times New Roman"),  
        axis.title.x = element_text(family = "Times New Roman"),  
        axis.title.y = element_text(family = "Times New Roman"),  
        panel.grid.major = element_blank(),  
        panel.grid.minor = element_blank()) +  
  ylab("Beta") +  
  xlab("L1-Descriptive") +  
  ylim(-0.01, 0.01) 

for (roi in levels(data_long1$ROI)) {        
  data_roi <- data_long1[data_long1$ROI == roi, ]        
  if (grepl("Lexical$", roi)) {        
    L1 <- L1 +           
      geom_violin(data = data_roi, fill = "white", color = syntacticColor, width = 0.5, position = position_dodge(0.9)) +
      geom_bar(data = data_roi, aes(fill = "white"), color = "black", size = 0.4, alpha = 0, stat = "summary", fun = "mean", position = position_dodge(0.9), width = 0.5) +          
      geom_beeswarm(data = data_roi, color = syntacticColor, size = 0.1)          
  } else if (grepl("Syntactic$", roi)) {          
    L1 <- L1 +           
      geom_violin(data = data_roi, fill = "white", color = barColor1, width = 0.5, position = position_dodge(0.9)) +
      geom_bar(data = data_roi, aes(fill = "white"), color = "black", size = 0.4, alpha = 0, stat = "summary", fun = "mean", position = position_dodge(0.9), width = 0.5) +          
      geom_beeswarm(data = data_roi, color = barColor1, size = 0.1)          
  } else if (grepl("Interaction$", roi)) {          
    L1 <- L1 +           
      geom_violin(data = data_roi, fill = "white", color = scatterColor, width = 0.5, position = position_dodge(0.9)) +
      geom_bar(data = data_roi, aes(fill = "white"), color = "black", size = 0.4, alpha = 0, stat = "summary", fun = "mean", position = position_dodge(0.9), width = 0.5) +          
      geom_beeswarm(data = data_roi, color = scatterColor, size = 0.1)          
  }          
}   

L1 <- L1 + stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2, color = "black")  

for (roi in names(significance)) {  
  if (significance[roi] == "*") {  
    L1 <- L1 + annotate("text", x = roi, y = -0.009,  
                        label = "*", color = "black", vjust = 1, size = 6)  
  }  
}  

print(p_values)  
print(L1)  

ggsave(
  filename = "/path/", 
  plot = L1, width = 10, height = 2.5, dpi = 300)

p_values_path <- "/path/"
p_values_df <- data.frame(ROI = levels(data_long1$ROI), p_value = p_values)
write_xlsx(p_values_df, path = p_values_path)