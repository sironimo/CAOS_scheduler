
#load scheduler
source("scheduler/scheduler.R")
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
  
  simulations_tmp <- simulations
  
  for(i in 1:(n_app*n_env)){
    
    out <- scheduler_fun(scheduler = scheduler[[k]],
                         app = simulations$app_sim[i],
                       env = simulations$env_sim[i])
    
    simulations_tmp$time[i] <- out$Runtime
    simulations_tmp$energy[i] <- out$Energy
    
  }
  
  simulations_tmp$Scheduler <- scheduler[[k]]
  
  simulations_out <- rbind(simulations_out,simulations_tmp)
  
}  

# Save simulations
write.csv(simulations_out, "data/simulations.csv", row.names = F)
