# Assume that one wants to minimize energy:
# vary the energy per core in microHPC to show where is the "threshold"
# (up to some energy value, it is better to use microHPC,
#   after it is better to use miniHPC).


#load scheduler
source("scheduler/scheduler.R")
source("energy_env/miniHPC_energy.R")
scheduler <- list("round_robin",
                  "minmin",
                  "decreasing_time",
                  "critical_path",
                  "critical_path_energy",
                  "decreasing_time_energy")

#Get Applications from folder app----
apps <- grep(pattern = "xml",list.files("app"),value = T)
app <- paste0("app/", apps)
n_app <- length(apps)

#Get Environments from folder env----
envs <- seq(from = 3.5, to = 0.5,by = -0.5)
n_env <- length(envs)

#Create empty Data.Frame----
simulations <-
  data.frame(Application = rep(gsub(pattern = ".xml",replacement = "",x = apps), 
                               times = n_env),
             energy_core = rep(envs,
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
    
    change_energy(energy_by_core = simulations_tmp$energy_core[i])
    
    out <- scheduler_fun(scheduler = scheduler[[k]],
               app = simulations$app_sim[i],
               env = "energy_env/miniHPC_energy.xml")
    
    simulations_tmp$time[i] <- out$Runtime
    simulations_tmp$energy[i] <- out$Energy
    
  }
  
  simulations_tmp$Scheduler <- scheduler[[k]]
  
  simulations_out <- rbind(simulations_out,simulations_tmp)
  
}




# Simulate microHPC

simulations_micro <-
  data.frame(Application = gsub(pattern = ".xml",replacement = "",x = apps),
             app_sim = app,
             time = rep(0,n_app),
             energy = rep(0,n_app),
             Scheduler = rep("",n_app))

simulations_out_micro <- simulations_micro[0,]

#Run Simulation for every App----
for (k in 1:length(scheduler)) {
  
  simulations_tmp_micro <- simulations_micro
  
  for(i in 1:(n_app)){
    
    out <- scheduler_fun(scheduler = scheduler[[k]],
                         app = simulations_micro$app_sim[i],
                        env = "env/microHPC.xml")
    
    simulations_tmp_micro$time[i] <- out$Runtime
    simulations_tmp_micro$energy[i] <- out$Energy
    
  }
  
  simulations_tmp_micro$Scheduler <- scheduler[[k]]
  
  simulations_out_micro <- rbind(simulations_out_micro,simulations_tmp_micro)
  
}


# Save simulations
write.csv(simulations_out, "data/energy_simulation.csv", row.names = F)
write.csv(simulations_out_micro, "data/energy_simulation_micro.csv", row.names = F)
