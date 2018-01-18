#include <simgrid/simdag.h>
#include <simgrid/plugins/energy.h>
#include <xbt.h>

/* bare-bones round-robin scheduler:
* cycles through workstations and distributes tasks
*  
* Usage:
*  ./round_robin env.xml app.xml
*/
int main(int argc, char **argv) {
  sg_host_energy_plugin_init();
  SD_init(&argc, argv);
  
  xbt_dynar_t tasks = SD_daxload(argv[2]);
  
  SD_create_environment(argv[1]);
  int nworkstations = SD_workstation_get_number();
  SD_workstation_t * workstations = SD_workstation_get_list();
  
  int cpt,k=0;
  SD_task_t task;
  
  xbt_dynar_foreach(tasks, k, task)
    if (SD_task_get_kind(task) == SD_TASK_COMP_SEQ){
      SD_task_schedulel(task, 1, workstations[cpt]);
      cpt = (cpt + 1) % nworkstations;
    }
    
    SD_simulate(-1);
    
    int total_nhosts = sg_host_count();
    sg_host_t *hosts = sg_host_list();
    
    double total_energy = 0;
    for (int cursor = 0; cursor < total_nhosts; cursor++) {
      total_energy += sg_host_get_consumed_energy(hosts[cursor]);
    }
    
    
    printf("Runtime Energy\n");
    printf("%f %f\n", SD_get_clock(), total_energy);
    
    return 0;
}