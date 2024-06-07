# Required Libraries
library(ggplot2)
library(tidyverse)
library(zoo)

# Setting working directory
setwd("~/Documents/Git_Repos/Develop/YCSB-IVS/analysis")

# Read output data
data = read.csv("all_experiments.csv")
head(data)

# Replace 0 values with non-zero value correspond to the experiment
repeat_non_zero = function(column) {
  n = length(column)
  status = rep(0,n)
  for (i in 1:n) {
    if (column[i] != 0 && status[i] == 0) {
      if (i + 1 <= n && column[i + 1] == 0 && status[i + 1] == 0) {
        column[i + 1] = column[i]
        status[i + 1] = 1
      }
      if (i + 2 <= n && column[i + 2] == 0 && status[i + 2] == 0) {
        column[i + 2] = column[i]
        status[i + 2] = 1
      }
    }
  }
  return(column)
}


data = data %>%
  select(-Insertprop) %>%
  mutate(Extendvaluesize = repeat_non_zero(Extendvaluesize)) %>%
  mutate(Extendprop = repeat_non_zero(Extendprop))
  
# Latency for READ
READ_data = data %>%
              filter(Phase=="run",Operation=="READ")
              
# Plot average latency (us)  
ggplot(READ_data, aes(x = Extendprop, y = Extendvaluesize, fill = AverageLatency.us.)) +
  geom_tile() +
  scale_fill_gradient(low = "yellow", high = "purple") +
  geom_text(aes(label = sprintf("%.2f", AverageLatency.us.)), size = 3, color = "black") +
  labs(
    title = "Heatmap of Average Latency for READ",
    x = "Extendprop",
    y = "Extendvaluesize",
    fill = "Avg Latency (us)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
  

# Latency for UPDATE
UPDATE_data = data %>%
  filter(Phase=="run",Operation=="UPDATE") 

# Plot average latency (us)  
ggplot(UPDATE_data, aes(x = Extendprop, y = Extendvaluesize, fill = AverageLatency.us.)) +
  geom_tile() +
  scale_fill_gradient(low = "yellow", high = "purple") +
  geom_text(aes(label = sprintf("%.2f", AverageLatency.us.)), size = 3, color = "black") +
  labs(
    title = "Heatmap of Average Latency for UPDATE",
    x = "Extendprop",
    y = "Extendvaluesize",
    fill = "Avg Latency (us)"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))
