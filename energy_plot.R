library(ggthemes)
library(ggplot2)
library(dplyr)


energy_simulations <- read.csv("data/energy_simulation.csv")
energy_simulations_micro <- read.csv("data/energy_simulation_micro.csv")


aggregated_energy_core <- energy_simulations %>%
  group_by(energy_core,Application) %>%
  summarise(avg_energy = median(energy),
            first_quant_energy = quantile(energy,0.25),
            third_quant_energy = quantile(energy,0.75))

aggregated_energy_micro <- energy_simulations_micro %>%
  group_by(Application) %>%
  summarise(avg_energy = median(energy),
            first_quant_energy = quantile(energy,0.25),
            third_quant_energy = quantile(energy,0.75))

plot <- merge(aggregated_energy_core,aggregated_energy_micro,by = "Application")
plot$norm <- plot$avg_energy.x/plot$avg_energy.y

ggplot(plot, aes(x=energy_core, y=norm)) +
  geom_point()  +
  geom_smooth(col = "green") + 
  geom_vline(xintercept  = 0.9, linetype = "dotted") +
  #geom_errorbar(aes(ymin=first_quant_energy/aggregated_energy_micro$first_quant_energy, ymax=third_quant_energy/aggregated_energy_micro$third_quant_energy), colour="black", width=.1) +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Normalized Energy') + xlab("Power by Core [W]")
ggsave(filename = "graphs/energy_core.pdf", device = "pdf", scale = 0.8)
