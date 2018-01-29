#include <simgrid/plugins/energy.h>
#include "util.h"

/*
 * Host Attribute stuff
 */
double sg_host_get_available_at(sg_host_t host) {
    HostAttribute attr = (HostAttribute) sg_host_user(host);
    return attr->available_at;
}

void sg_host_set_available_at(sg_host_t host, double time) {
    HostAttribute attr = (HostAttribute) sg_host_user(host);
    attr->available_at = time;
    sg_host_user_set(host, attr);
}

SD_task_t sg_host_get_last_scheduled_task(sg_host_t host) {
    HostAttribute attr = (HostAttribute) sg_host_user(host);
    return attr->last_scheduled_task;
}

void sg_host_set_last_scheduled_task(sg_host_t host, SD_task_t task) {
    HostAttribute attr = (HostAttribute) sg_host_user(host);
    attr->last_scheduled_task = task;
    sg_host_user_set(host, attr);
}

/*
 * task estimation stuff
 */

// return all schedulable tasks (i.e. their dependencies are met).
xbt_dynar_t get_ready_tasks(xbt_dynar_t tasks) {
    xbt_dynar_t ready_tasks = xbt_dynar_new(sizeof(SD_task_t), NULL);
    {
        unsigned int i = 0;
        SD_task_t task = NULL;
        xbt_dynar_foreach(tasks, i, task) {
            if (SD_task_get_kind(task) == SD_TASK_COMP_SEQ && SD_task_get_state(task) == SD_SCHEDULABLE) {
                xbt_dynar_push(ready_tasks, &task);
            }
        }
    }
    return ready_tasks;
}

// return the time task would finish on host
double predict_finish_time(SD_task_t task, sg_host_t host) {
    double result;

    xbt_dynar_t parents = SD_task_get_parents(task);

    if (!xbt_dynar_is_empty(parents)) {
        unsigned int i;
        double data_available = 0.;
        double redist_time = 0;
        double last_data_available;
        /* compute last_data_available */
        SD_task_t parent;
        last_data_available = -1.0;
        xbt_dynar_foreach(parents, i, parent) {
            /* normal case, if somehow we can't estimate the redistribution time because
             * of null pointers we set data_available = 0
             */
            if (SD_task_get_kind(parent) == SD_TASK_COMM_E2E) {
                xbt_dynar_t grand_parents = SD_task_get_parents(parent);
                if(xbt_dynar_is_empty(grand_parents)) {
                    data_available = 0;
                } else {
                    SD_task_t grand_parent;
                    xbt_dynar_get_cpy(grand_parents, 0, &grand_parent);
                    sg_host_t *grand_parent_host = SD_task_get_workstation_list(grand_parent);
                    /* Estimate the redistribution time from this parent */
                    if(grand_parent_host) {
                        redist_time = sg_host_route_latency(*grand_parent_host, host) +
                                      SD_task_get_amount(parent) / sg_host_route_bandwidth(*grand_parent_host, host);
                        data_available = SD_task_get_finish_time(grand_parent) + redist_time;
                    } else {
                        data_available = 0;
                    }
                }
                xbt_dynar_free_container(&grand_parents);
            }

            /* no transfer, control dependency */
            if (SD_task_get_kind(parent) == SD_TASK_COMP_SEQ) {
                data_available = SD_task_get_finish_time(parent);
            }

            if (last_data_available < data_available)
                last_data_available = data_available;
        }

        xbt_dynar_free_container(&parents);

        result = MAX(sg_host_get_available_at(host), last_data_available) +
                 SD_task_get_amount(task) / sg_host_speed(host);
    } else {
        xbt_dynar_free_container(&parents);

        result = sg_host_get_available_at(host) + SD_task_get_amount(task) / sg_host_speed(host);
    }
    return result;
}

//predict energy consumption of task on host
double predict_energy_consumption(SD_task_t task, sg_host_t host) {
    int n = sg_host_get_nb_pstates(host);
    double watts = sg_host_get_wattmax_at(host, n-1);
    return predict_finish_time(task, host) * watts;
}

// return host which minimises finish time for given task
sg_host_t SD_task_get_fastest_host(SD_task_t task) {
    sg_host_t *hosts = sg_host_list();
    size_t nhosts = sg_host_count();
    sg_host_t best_host = hosts[0];
    double min_EFT = predict_finish_time(task, hosts[0]);

    for (int i = 1; i < nhosts; i++) {
        double EFT = predict_finish_time(task, hosts[i]);

        if (EFT < min_EFT) {
            min_EFT = EFT;
            best_host = hosts[i];
        }
    }
    xbt_free(hosts);
    return best_host;
}

sg_host_t SD_task_get_cheapest_host(SD_task_t task) {
    sg_host_t *hosts = sg_host_list();
    size_t nhosts = sg_host_count();
    sg_host_t best_host = hosts[0];
    double min_EFT = predict_energy_consumption(task, hosts[0]);

    for (int i = 1; i < nhosts; i++) {
        double EFT = predict_energy_consumption(task, hosts[i]);

        if (EFT < min_EFT) {
            min_EFT = EFT;
            best_host = hosts[i];
        }
    }
    xbt_free(hosts);
    return best_host;
}



// call schedulel(task,1,host) and update host attributes
void SD_task_schedule_on(SD_task_t task, sg_host_t host) {
    // let host run full speed
    int n = sg_host_get_nb_pstates(host);
    sg_host_set_pstate(host, n-1);

    SD_task_schedulel(task, 1, host);

    /*
     * SimDag allows tasks to be executed concurrently when they can by default.
     * Yet schedulers take decisions assuming that tasks wait for resource availability to start.
     * The solution (well crude hack is to keep track of the last task scheduled on a host and add a special type of
     * dependency if needed to force the sequential execution meant by the scheduler.
     * If the last scheduled task is already done, has failed or is a predecessor of the current task, no need for a
     * new dependency
    */

    SD_task_t last_scheduled_task = sg_host_get_last_scheduled_task(host);
    if (last_scheduled_task && (SD_task_get_state(last_scheduled_task) != SD_DONE) &&
        (SD_task_get_state(last_scheduled_task) != SD_FAILED) &&
        !SD_task_dependency_exists(sg_host_get_last_scheduled_task(host), task))
        SD_task_dependency_add("resource", NULL, last_scheduled_task, task);

    sg_host_set_last_scheduled_task(host, task);
    sg_host_set_available_at(host, predict_finish_time(task, host));
}