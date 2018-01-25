# Scheduler wraper

#Wrapper for round_robin code----
scheduler_fun <- function(app = "simple_app.xml", env="miniHPC.xml",
                        scheduler = "round_robin",
                        tmpfile = tempfile())
{
  command=paste(file.path(".",scheduler),env,app,">",tmpfile)
  system(command)
  read.table(tmpfile,header=TRUE)
}
