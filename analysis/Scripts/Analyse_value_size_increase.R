# Required Libraries
library(ggplot2)
library(tidyverse)

# Setting working directory
setwd("~/Documents/Git_Repos/Develop/YCSB-IVS/analysis")

# Read output data
data = read.csv("all_experiments.csv")
head(data)

# Latency for READ
READ_data = data %>%
              filter(Phase=="run",Operation=="READ") %>%
              group_by(Run,Extend)
              
# Plot average latency (us)  
READ_data %>%
mutate(Extendprop=Run*0.1+0.1) %>%
ggplot() +
  geom_line(aes(x=Extendprop,y=AverageLatency.us.,colour = Extend)) +
  ggtitle("Average Latency (in us) for READ Operations")
  

# Latency for UPDATE
UPDATE_data = data %>%
  filter(Phase=="run",Operation=="UPDATE") %>%
  group_by(Run,Extend)

# Plot average latency (us)  
UPDATE_data %>%
  mutate(Extendprop=Run*0.1+0.1) %>%
  ggplot() +
  geom_line(aes(x=Extendprop,y=AverageLatency.us.,colour = Extend)) +
  ggtitle("Average Latency (in us) for UPDATE Operations")
