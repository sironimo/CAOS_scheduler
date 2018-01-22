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