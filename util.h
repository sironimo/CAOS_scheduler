#ifndef SIMGRID_PROJECT_UTIL_H
#define SIMGRID_PROJECT_UTIL_H

#include <simgrid/simdag.h>

typedef struct _HostAttribute *HostAttribute;
struct _HostAttribute {
    /* Earliest time at which a host is ready to execute a task */
    double available_at;
    SD_task_t last_scheduled_task;
};

double sg_host_get_available_at(sg_host_t host);
void sg_host_set_available_at(sg_host_t host, double time);
SD_task_t sg_host_get_last_scheduled_task(sg_host_t host);
void sg_host_set_last_scheduled_task(sg_host_t host, SD_task_t task);

xbt_dynar_t get_ready_tasks(xbt_dynar_t tasks);
double finish_on_at(SD_task_t task, sg_host_t host);
sg_host_t SD_task_get_best_host(SD_task_t task);
void SD_task_schedule_on(SD_task_t task, sg_host_t host);

#endif //SIMGRID_PROJECT_UTIL_H
