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
             scheduler = rep("",n_app*n_env))

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
  
  simulations_tmp$scheduler <- scheduler[k]
  
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
simulations_out %>%
  group_by(Application) %>%
  summarise(avg_time = mean(time),
            avg_energy = mean(energy),
            sd_time = sd(time),
            sd_energy = sd(energy))
