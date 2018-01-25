# Scheduler wraper

#Wrapper for round_robin code----
round_robin <- function(app = "simple_app.xml", env="miniHPC.xml",
                        exec = file.path(".","round_robin"),
                        tmpfile = tempfile())
{
  command=paste(exec,env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}

#Wrapper for minmin code----
minmin <- function(app = "simple_app.xml", env="miniHPC.xml",
                   exec = file.path(".","minmin"),
                   tmpfile = tempfile())
{
  command=paste(exec,env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}

#Wrapper for critical_path code----
critical_path <- function(app = "simple_app.xml", env="miniHPC.xml",
                   exec = file.path(".","critical_path"),
                   tmpfile = tempfile())
{
  command=paste(exec,env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}


#Wrapper for decreasing_time code----
decreasing_time <- function(app = "simple_app.xml", env="miniHPC.xml",
                          exec = file.path(".","decreasing_time"),
                          tmpfile = tempfile())
{
  command=paste(exec,env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}