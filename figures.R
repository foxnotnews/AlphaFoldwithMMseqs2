library(ggplot2)
library("MASS")
library("car")
#data
setwd("C:/Users/carla/Documents/alphaFold")
data=read.csv("data_alphafold2_final_version.csv", sep=";")
full_data=read.csv("Alphafold_full_version.csv", sep=";")

#convert time to minutes
time_obj <- as.POSIXlt(data$TIME.mmseqs..min., format = "%H:%M:%S")
data$TIME.mmseqs..min. <- time_obj$hour * 60 + time_obj$min + time_obj$sec / 60

time_obj <- as.POSIXlt(data$TIME.ALPHAFOLD..min., format = "%H:%M:%S")
data$TIME.ALPHAFOLD..min. <- time_obj$hour * 60 + time_obj$min + time_obj$sec / 60

time_obj <- as.POSIXlt(data$Total_time, format = "%H:%M:%S")
data$Total_time <- time_obj$hour * 60 + time_obj$min + time_obj$sec / 60


#data
monomer=data[data$MODEL=="monomer",]
multimer=data[data$MODEL=="multimer",]


colors=rainbow(length(levels(as.factor(monomer$CPU))))
symbol=as.factor(monomer$File.name)
# Create the plot with points colored by CPU and legend on the right
#plot(
#  monomer$TIME.mmseqs..min., 
#  monomer$sensitivity, 
#  xlab = "Time in minutes", 
#  ylab = "sensitivity", 
#  main = "Time vs. sensitivtiy MMseq2 runs for monomers",
#  col = colors , # Generate colors dynamically
#  pch=symbol,
#  cex=2
#)
#legend("right", legend = levels(as.factor(monomer$CPU)),
#       title = "CPU",
#       fill = colors)

ggplot(monomer, aes(x = TIME.mmseqs..min., y = sensitivity, color = as.factor(CPU), shape = symbol)) +
  geom_point(size = 5) +
  labs(x = "Time in minutes", y = "Sensitivity", title = "Time vs. Sensitivity MMseqs2  for monomers") +
  scale_color_manual(values = colors) +  # Use the specified colors
  guides(color = guide_legend(title = "CPU"), shape = guide_legend(title = "Files")) +
  theme(plot.title = element_text(hjust = 0.5))
  


for (n in 1:5){
  print(median(monomer$TIME.mmseqs..min.[monomer$sensitivity==n]))
  data=monomer[monomer$sensitivity==n,]
  print(mean(data$TIME.mmseqs..min.[data$CPU==10]))
  print(mean(data$TIME.mmseqs..min.[data$CPU==12]))
}

data=monomer[monomer$sensitivity==5,]
mean(data$TIME.mmseqs..min.[data$TEMPLATE=="YES"])
mean(data$TIME.mmseqs..min.[data$TEMPLATE=="NO"])
mean(data$TIME.mmseqs..min.[data$CPU==10])
mean(data$TIME.mmseqs..min.[data$CPU==12])
max(data$TIME.mmseqs..min.)
#mutlimer

# Filter out rows with NA values
#valid_rows <- complete.cases(monomer$TIME.mmseqs..min., monomer$sensitivity)
#filtered_monomer <- monomer[valid_rows, ]
#
## Create the plot
#plot(
#  multimer$TIME.mmseqs..min., 
#  multimer$sensitivity, 
#  xlab = "Time in minutes", 
#  ylab = "Sensitivity", 
#  main = "Time vs. Sensitivity  MMseq2 runs for multimers",
#  col = colors,# Apply colors to points,
#  pch = 16
#)
## Add a legend on the right side
#legend(
#  "right",
#  legend = levels(as.factor(monomer$CPU)),
#  title = "CPU",
#  fill = colors,
#)



ggplot(multimer, aes(x = TIME.mmseqs..min., y = sensitivity, color = as.factor(CPU))) +
  geom_point(size = 5) +
  labs(x = "Time in minutes", y = "Sensitivity", title = "Time vs. Sensitivity MMseqs2  for multimer") +
  scale_color_manual(values = colors) +  # Use the specified colors
  guides(color = guide_legend(title = "CPU")) +
  theme(plot.title = element_text(hjust = 0.5))


for (n in 1:5){
  print(median(multimer$TIME.mmseqs..min.[multimer$sensitivity==n]))
  #data=multimer[multimer$sensitivity==n,]
  #print(mean(data$TIME.mmseqs..min.[data$CPU==10]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==15]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==12]))
}




#ALphafold

#monomer
# Create the scatter plot with cleaned data


# Create a color palette for the levels of the TEMPLATE variable
color_palette <- c("NO" = "red", "YES" = "blue")

ggplot(data = monomer, aes(x = as.factor(File.name), y = TIME.ALPHAFOLD..min.)) +
  geom_point(aes(color = TEMPLATE), pch = 16, size=5) + 
  scale_color_manual(values = color_palette) +  # Apply the color palette
  xlab("Files") +
  ylab("Time in minutes") +
  labs(title = "AlphaFold2 running time for monomers") +
  #theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))  # Center the plot title


#####
#multimer
ggplot(data = multimer, aes(x = as.factor(TEMPLATE), y = TIME.ALPHAFOLD..min.)) +
  geom_point(pch = 16, size=5) +
  xlab("TEMPLATE") +
  ylab("TIME") +
  labs(title = "AlphaFold2 running time for multimer" )+
  theme(plot.title = element_text(hjust = 0.5))


################################################################
#TOTAL TIME monomer
plot(
  monomer$Total_time, 
  monomer$sensitivity, 
  xlab = "Total Time in minutes", 
  ylab = "sensitivity", 
  main = "AlphFold2 with MMseqs2 Monomer",
  col = colors , # Generate colors dynamically
  pch=as.numeric(as.factor(monomer$File.name))
)
legend("right", legend = levels(as.factor(monomer$CPU)),
       title = "CPU", fill = colors)





ggplot(data = monomer, aes(x = Total_time, y = sensitivity, pch = as.numeric(as.factor(File.name)),
                           color = as.factor(CPU))) +
  geom_point(aes(shape = as.factor(File.name)), size = 5) +
  xlab("Total Time in minutes") +
  ylab("Sensitivity") +
  labs(title = "AlphaFold2 with MMseqs2 for monomers") +
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_color_manual(values = colors) +
  scale_shape_manual(values = 1:length(unique(monomer$File.name)),
                     labels = unique(monomer$File.name),
                     name = "File Name") +
  guides(color = guide_legend(title = "CPU"),
         shape = guide_legend(title = "File Name"))


for (n in 1:5){
  print(median(monomer$Total_time[monomer$sensitivity==n], na.rm = T))
  #data=multimer[multimer$sensitivity==n,]
  #print(mean(data$TIME.mmseqs..min.[data$CPU==10]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==15]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==12]))
}
monomer$Total_time[monomer$sensitivity==2]

#multimer
ggplot(data = multimer, aes(x = Total_time, y = sensitivity, color = as.factor(CPU))) +
  geom_point(shape = 16, size=5) +
  xlab("Total Time in minutes") +
  ylab("Sensitivity") +
  labs(title = "AlphaFold2 with MMseqs2 for multimer") +
  theme(plot.title = element_text(hjust = 0.5)) +
  guides(color = guide_legend(title = "CPU")) +
  scale_color_manual(values = colors)




for (n in 1:5){
  print(median(multimer$Total_time[multimer$sensitivity==n]))
  #data=multimer[multimer$sensitivity==n,]
  #print(mean(data$TIME.mmseqs..min.[data$CPU==10]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==15]))
  #print(mean(data$TIME.mmseqs..min.[data$CPU==12]))
}



#FULL ALPHAFOLD
full_monomer=full_data[full_data$model=="monomer",]
full_multimer=full_data[full_data$model=="multimer",]

median(full_multimer$TIME_alphafold[full_monomer$template=="NO"])
median(full_multimer$TIME_alphafold[full_monomer$template=="YES"])

#####FOR NOW
ggplot(data = full_monomer, aes(x = TIME_alphafold, y = file_name,  color = as.factor(template))) +
  geom_point( pch = 16, size=5) +
  xlab("Time in minutes") +
  ylab("Files") +
  labs(title = "Alphafold2 without MMseqs2 for monomers")+
  guides(color = guide_legend(title = "template"))+
  #theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))



ggplot(data = full_multimer, aes(x = as.factor(template), y = TIME_alphafold , color = as.factor(template))) +
  geom_point( pch = 16, size=5) +
  xlab("TEMPLATE") +
  ylab("TIME in minutes") +
  labs(title = "Alphafold2 without MMseqs2 for multimer")+
  #theme_minimal() +
  guides(color = guide_legend(title = "template"))+ 
  theme(plot.title = element_text(hjust = 0.5))

t.test(multimer$TIME.ALPHAFOLD..min.[multimer$TEMPLATE=="NO"], multimer$TIME.ALPHAFOLD..min.[multimer$TEMPLATE=="YES"])

qqPlot(multimer$TIME.ALPHAFOLD..min.)

###TEST?????

mean(full_monomer$TIME_alphafold, na.rm = T)

mean(full_multimer$TIME_alphafold)

lm(monomer$Total_time ~ full_monomer$TIME_alphafold )
anova(aov(monomer$Total_time ~full_monomer$TIME_alphafold))

t.test(monomer$TIME.ALPHAFOLD..min., full_monomer$TIME_alphafold)

library(dplyr)


# Assuming 'monomer' is your data frame
qqPlot(monomer$Total_time, main='Normal')
qqPlot(full_monomer$TIME_alphafold)
shapiro.test(full_monomer$TIME_alphafold)

wilcox.test(monomer$Total_time, full_monomer$TIME_alphafold)

MONOMER_yes=median(monomer$TIME.ALPHAFOLD..min.[monomer$TEMPLATE=="NO"])
MONOMER_no=median(monomer$TIME.ALPHAFOLD..min.[monomer$TEMPLATE=="YES"], na.rm = T)

median(full_multimer$TIME_alphafold)

anova_result <- aov(cbind(monomer$Total_time, full_monomer$TIME_alphafold) ~ monomer$sensitivity)




# Print the ANOVA summary
summary(anova_result)

multimer_no=median(multimer$TIME.ALPHAFOLD..min.[multimer$TEMPLATE=="NO"], na.rm = T)
multimer_yes=mean(multimer$TIME.ALPHAFOLD..min.[multimer$TEMPLATE=="YES"], na.rm = T)
