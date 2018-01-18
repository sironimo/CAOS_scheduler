#load libraries
library(ggplot2)
library(reshape2)
library(ggthemes)


#Wrapper for round_robin code----
round_robin <- function(app = "simple_app.xml", env="miniHPC.xml",
                     exec = file.path(".","round_robin"),
                     tmpfile = tempfile())
{
  command=paste(exec,env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}


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
             energy = rep(0,n_app*n_env))


#Run Simulation for every App----
for(i in 1:(n_app*n_env)){
  
  out <- round_robin(app = simulations$app_sim[i],
                     env = simulations$env_sim[i])
  
  
  simulations$time[i] <- out$Runtime
  simulations$energy[i] <- out$Energy
  
}

#Energy / Time ratio----
simulations$ratio <- simulations$energy/simulations$time



#Plot Times----
ggplot(simulations, aes(x=Application, y=time, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Time [s]')
ggsave(filename = "graphs/round_robin_time.jpeg")

#Plot Energy Consumtion----
ggplot(simulations, aes(x=Application, y=energy, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy [Joules]')
ggsave(filename = "graphs/round_robin_energy.jpeg")

#Plot Energy/Time Consumtion----
ggplot(simulations, aes(x=Application, y=ratio, fill = Environment, group = Environment)) +
  geom_bar(stat='identity', position='dodge')  +
  theme_fivethirtyeight() + scale_fill_pander() + 
  theme(axis.title = element_text()) + 
  ylab('Energy/Time [Joules/s]')
ggsave(filename = "graphs/round_robin_energy_time.jpeg")
