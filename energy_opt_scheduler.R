# Assume that one wants to minimize energy:
# vary the energy per core in microHPC to show where is the "threshold"
# (up to some energy value, it is better to use microHPC,
#   after it is better to use miniHPC).

library(dplyr)

#load scheduler
source("scheduler/scheduler.R")
source("energy_env/miniHPC_energy.R")
scheduler <- list("decreasing_time",
                  "decreasing_time_energy",
                  "critical_path",
                  "critical_path_energy")

#Get Applications from folder app----
apps <- grep(pattern = "xml",list.files("app"),value = T)
app <- paste0("app/", apps)
n_app <- length(apps)

#Get Environments from folder env----
envs <- seq(from = 5, to = 25,by = 5)
n_env <- length(envs)

#Create empty Data.Frame----
simulations <-
  data.frame(Application = rep(gsub(pattern = ".xml",replacement = "",x = apps), 
                               times = n_env),
             idle = rep(envs,
                               each = n_app),
             app_sim = rep(app, 
                           times = n_env),
             time = rep(0,n_app*n_env),
             energy = rep(0,n_app*n_env),
             Scheduler = rep("",n_app*n_env))

simulations_out <- simulations[0,]




#Run Simulation for every App----
for (k in 1:length(scheduler)) {
  
  simulations_tmp <- simulations
  
  for(i in 1:(n_app*n_env)){
    
      change_energy_comb(base_power = simulations_tmp$idle[i])
    
    out <- scheduler_fun(scheduler = scheduler[[k]],
               app = simulations$app_sim[i],
               env = "energy_env/combined_energy.xml")
    
    simulations_tmp$time[i] <- out$Runtime
    simulations_tmp$energy[i] <- out$Energy
    
  }
  
  simulations_tmp$Scheduler <- scheduler[[k]]
  
  simulations_out <- rbind(simulations_out,simulations_tmp)
  
}

dec_time <- simulations_out %>%
  filter(Scheduler == "decreasing_time") %>%
  inner_join(simulations_out %>%
         filter(Scheduler == "decreasing_time_energy"),
       c("Application", "idle", "app_sim"),
      suffix = c("","_energy")) %>%
  mutate(norm_energy = energy_energy/energy, scheduler = "decreasing_time")

critical_path <- simulations_out %>%
  filter(Scheduler == "critical_path") %>%
  inner_join(simulations_out %>%
               filter(Scheduler == "critical_path_energy"),
             c("Application", "idle", "app_sim"),
             suffix = c("","_energy")) %>%
  mutate(norm_energy = energy_energy/energy, scheduler = "critical_path")

comb <- rbind(dec_time, critical_path)

aggregated <- comb %>%
  group_by(idle, Scheduler) %>%
  summarise(avg_energy = mean(norm_energy),
            min_energy = min(norm_energy),
            max_energy = max(norm_energy))

ggplot(aggregated, aes(x=idle, y=avg_energy, color = Scheduler, group = Scheduler)) +
  geom_line()  +
  geom_ribbon(aes(x=idle, ymin=min_energy, ymax = max_energy, color =NA),alpha=0.1, inherit.aes = F) +
  annotate(geom = "text",label = c("min", "max"),
           x = c(15,15),
           y = c(aggregated$min_energy[5]+0.07,
                 aggregated$max_energy[5]-0.07)) +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text(), axis.text.x = element_text(angle = 30, hjust = 1)) + 
  ylab('Normalized Energy') +
  xlab('Idle Power [W]')
ggsave(filename = "graphs/idle_power.pdf", device = "pdf", scale = 0.8)


# Save simulations
write.csv(simulations_out, "data/idle_simulation.csv", row.names = F)
