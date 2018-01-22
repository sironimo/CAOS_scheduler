#load libraries
library(ggplot2)
library(reshape2)
library(ggthemes)
library(dplyr)

#load scheduler
source("scheduler/scheduler.R")
scheduler <- list("round_robin", "minmin")

#Get Applications from folder app----
apps <- list.files("app")
app <- paste0("app/", apps)
n_app <- length(apps)

#Get Environments from folder env----
envs <- list.files("env")
env <- paste0("env/", envs)
n_env <- length(envs)

#Create empty Data.Frame----
simulations <-
  data.frame(Application = rep(gsub(pattern = ".xml",replacement = "",x = apps), 
                       times = n_env),
             Environment = rep(gsub(pattern = ".xml",replacement = "",x = envs),
                       each = n_app),
             app_sim = rep(app, 
                       times = n_env),
             env_sim = rep(env,
                       each = n_app),
             time = rep(0,n_app*n_env),
             energy = rep(0,n_app*n_env),
             Scheduler = rep("",n_app*n_env))

simulations_out <- simulations[0,]




#Run Simulation for every App----
for (k in 1:length(scheduler)) {
  
  fun <- get(scheduler[[k]])
  simulations_tmp <- simulations
  
  for(i in 1:(n_app*n_env)){
    
    out <- fun(app = simulations$app_sim[i],
                       env = simulations$env_sim[i])
    
    simulations_tmp$time[i] <- out$Runtime
    simulations_tmp$energy[i] <- out$Energy
    
  }
  
  simulations_tmp$Scheduler <- scheduler[[k]]
  
  simulations_out <- rbind(simulations_out,simulations_tmp)
  
}  

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


#Plot Energy/Time Consumtion----
ggplot(simulations_out, aes(x=Application, y=ratio, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy/Time [J/s]')
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

