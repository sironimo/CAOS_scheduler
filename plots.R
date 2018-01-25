
library(ggthemes)
library(ggplot2)
library(dplyr)
#library(reshape2)

simulations_out <- read.csv("data/simulations.csv")


#Energy / Time ratio----
simulations_out$ratio <- simulations_out$energy/simulations_out$time


#Plot Times----
ggplot(simulations_out, aes(x=Application, y=time, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Time [s]')
ggsave(filename = "graphs/round_robin_time.pdf", device = "pdf", scale = 0.8)


#Plot Energy Consumtion----
ggplot(simulations_out, aes(x=Application, y=energy, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy [J]')
ggsave(filename = "graphs/round_robin_energy.pdf", device = "pdf", scale = 0.8)


#Plot Energy/Time Consumption----
ggplot(simulations_out, aes(x=Application, y=ratio, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy/Time [J/s]')
ggsave(filename = "graphs/round_robin_energy_time.pdf", device = "pdf", scale = 0.8)

#Plot Time----
ggplot(simulations_out, aes(x=Scheduler, y=time, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Time [s]')
ggsave(filename = "graphs/round_robin_energy_time.pdf", device = "pdf", scale = 0.8)


#Calculate avg, sd, etc.----
aggregated <- simulations_out %>%
  group_by(Scheduler) %>%
  summarise(avg_time = median(time),
            first_quant_time = quantile(time,0.25),
            third_quant_time = quantile(time,0.75),
            avg_energy = median(energy),
            first_quant_energy = quantile(energy,0.25),
            third_quant_energy = quantile(energy,0.75))

#Compare Scheduling Algorithms----
conversion <- 1/60/60
aggregated$avg_time <- aggregated$avg_time*conversion
aggregated$first_quant_time <- aggregated$first_quant_time*conversion
aggregated$third_quant_time <- aggregated$third_quant_time*conversion

aggregated$avg_energy <- aggregated$avg_energy*2.77778e-7
aggregated$first_quant_energy <- aggregated$first_quant_energy*2.77778e-7
aggregated$third_quant_energy <- aggregated$third_quant_energy*2.77778e-7

ggplot(aggregated, aes(x=Scheduler, y=avg_time, fill = Scheduler, group = Scheduler)) +
  geom_bar(stat='identity', position='dodge')  +
  geom_errorbar(aes(ymin=first_quant_time, ymax=third_quant_time),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Time [h]') 
ggsave(filename = "graphs/scheduling_compare.pdf", device = "pdf", scale = 0.8)

ggplot(aggregated, aes(x=Scheduler, y=avg_energy, fill = Scheduler, group = Scheduler)) +
  geom_bar(stat='identity', position='dodge')  +
  geom_errorbar(aes(ymin=first_quant_energy, ymax=third_quant_energy),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy [kWh]') 
ggsave(filename = "graphs/scheduling_compare.pdf", device = "pdf", scale = 0.8)


ggplot(aggregated, aes(x=Scheduler, y=avg_energy/avg_time, fill = Scheduler, group = Scheduler)) +
  geom_bar(stat='identity', position='dodge')  +
  geom_errorbar(aes(ymin=first_quant_energy/first_quant_time, ymax=third_quant_energy/third_quant_time),
                width=.2,                    # Width of the error bars
                position=position_dodge(.9)) +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy [kW]') 
ggsave(filename = "graphs/scheduling_compare.pdf", device = "pdf", scale = 0.8)


#Compare Cluster ----
#Calculate avg, sd, etc.----
aggregated_cluster <- simulations_out %>%
  group_by(Environment) %>%
  summarise(avg_time = median(time),
            first_quant_time = quantile(time,0.25),
            third_quant_time = quantile(time,0.75),
            avg_energy = median(energy),
            first_quant_energy = quantile(energy,0.25),
            third_quant_energy = quantile(energy,0.75))

aggregated_cluster$avg_time <- aggregated_cluster$avg_time*conversion
aggregated_cluster$first_quant_time <- aggregated_cluster$first_quant_time*conversion
aggregated_cluster$third_quant_time <- aggregated_cluster$third_quant_time*conversion

aggregated_cluster$avg_energy <- aggregated_cluster$avg_energy*2.77778e-7
aggregated_cluster$first_quant_energy <- aggregated_cluster$first_quant_energy*2.77778e-7
aggregated_cluster$third_quant_energy <- aggregated_cluster$third_quant_energy*2.77778e-7

aggregated_cluster$norm_time <- aggregated_cluster$avg_time/aggregated_cluster$avg_time[aggregated_cluster$Environment=="miniHPC"]
aggregated_cluster$norm_energy <- aggregated_cluster$avg_energy/aggregated_cluster$avg_energy[aggregated_cluster$Environment=="miniHPC"]


ggplot(aggregated_cluster, aes(x=Environment, y=norm_time, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Normalized Time') 
ggsave(filename = "graphs/scheduling_compare.pdf", device = "pdf", scale = 0.8)

ggplot(aggregated_cluster, aes(x=Environment, y=norm_energy, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Normalized Energy') 
ggsave(filename = "graphs/scheduling_compare.pdf", device = "pdf", scale = 0.8)

