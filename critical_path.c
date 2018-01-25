#include <string.h>
#include <simgrid/simdag.h>
#include <simgrid/plugins/energy.h>
#include <stdio.h>
#include "util.h"

XBT_LOG_NEW_DEFAULT_CATEGORY(scheduler, "Logging specific to this scheduler");

/*
 * getter and setter for critical values.
 * (We give each task a pointer into a preallocated array as user data.)
 */
double SD_task_get_critical_value(SD_task_t task) {
    return *(double*)SD_task_get_data(task);
}

void SD_task_set_critical_value(SD_task_t task, double val) {
    *(double*)SD_task_get_data(task) = val;
}

/*
 * Uses a backflow algorithm to compute the critical value for each task.
 */
void backflow_critical_values(xbt_dynar_t dax, double *critical_values) {
    xbt_dynar_t current_level = xbt_dynar_new(sizeof(SD_task_t), NULL);
    xbt_dynar_t new_level = xbt_dynar_new(sizeof(SD_task_t), NULL);

    // identify end nodes
    {
        unsigned int i;
        SD_task_t t;
        xbt_dynar_foreach(dax, i, t) {
            xbt_dynar_t children = SD_task_get_children(t);
            SD_task_set_data(t, critical_values + i);
            if (xbt_dynar_is_empty(children)) {
                xbt_dynar_push(current_level, &t);
                critical_values[i] = SD_task_get_amount(t);
            }
            xbt_dynar_free_container(&children);
        }
    }

    while (!xbt_dynar_is_empty(current_level)) {
        {
            SD_task_t w;
            unsigned int i;
            xbt_dynar_foreach(current_level, i, w) {
                xbt_dynar_t parents = SD_task_get_parents(w);
                // Find the longest path to each parent and update the level.
                {
                    unsigned int j;
                    SD_task_t t;
                    xbt_dynar_foreach(parents, j, t) {
                        double amount = SD_task_get_critical_value(w) + SD_task_get_amount(t);
                        if (!xbt_dynar_member(new_level, &t)) {
                            xbt_dynar_push(new_level, &t);
                        }
                        if (amount > SD_task_get_critical_value(t)) {
                            SD_task_set_critical_value(t, amount);
                        }
                    }
                }
                xbt_dynar_free_container(&parents);
            }
        }
        //Exchange levels
        xbt_dynar_reset(current_level);
        {
            SD_task_t w;
            unsigned int i;
            xbt_dynar_foreach(new_level, i, w) {
                xbt_dynar_push(current_level, &w);
            }
        }
        xbt_dynar_reset(new_level);
    }

    xbt_dynar_free_container(&new_level);
    xbt_dynar_free_container(&current_level);
}

/*
 * Critical Path Algorithm as described here
 * http://www.ctl.ua.edu/math103/scheduling/scheduling_algorithms.htm
 */
int main(int argc, char **argv) {
    sg_host_energy_plugin_init();
    SD_init(&argc, argv);

    xbt_assert(argc > 2, "Usage: %s platform_file dax_file \n"
            "\tExample: %s simulacrum_7_hosts.xml Montage_25.xml", argv[0], argv[0]);

    SD_create_environment(argv[1]);

    size_t total_nhosts = sg_host_count();
    sg_host_t *hosts = sg_host_list();

    for (int cursor = 0; cursor < total_nhosts; cursor++)
        sg_host_user_set(hosts[cursor], xbt_new0(struct _HostAttribute, 1));

    xbt_dynar_t dax = SD_daxload(argv[2]);
    /* set watch points on completion of tasks such that when calling
     *      SD_simulate_with_update(-1.0, changed_tasks);
     * the simulation runs until the first task is completed.
     */
    {
        unsigned int cursor;
        SD_task_t task;
        xbt_dynar_foreach(dax, cursor, task) {
            SD_task_watch(task, SD_DONE);
        }
    }

    /* allocate space for critical values and compute them */
    double *critical_values = calloc(xbt_dynar_length(dax), sizeof(double));
    backflow_critical_values(dax, critical_values);

    /* Schedule the root first */
    {
        SD_task_t root;
        xbt_dynar_get_cpy(dax, 0, &root);
        sg_host_t host = SD_task_get_best_host(root);
        SD_task_schedulel(root, 1, host);
    }
    xbt_dynar_t changed_tasks = xbt_dynar_new(sizeof(SD_task_t), NULL);
    SD_simulate_with_update(-1.0, changed_tasks);

    while (!xbt_dynar_is_empty(changed_tasks)) {
        xbt_dynar_t ready_tasks = get_ready_tasks(dax);
        xbt_dynar_reset(changed_tasks);

        // If there are no ready tasks, advance simulation
        if (xbt_dynar_is_empty(ready_tasks)) {
            xbt_dynar_free_container(&ready_tasks);
            SD_simulate_with_update(-1.0, changed_tasks);
            continue;
        }

        // select task with highest critical value and schedule it on best host
        double critical_value = -1;
        SD_task_t selected_task = NULL;

        {
            unsigned int cursor;
            SD_task_t task;
            xbt_dynar_foreach(ready_tasks, cursor, task) {
                if (critical_value < SD_task_get_critical_value(task)) {
                    selected_task = task;
                    critical_value = SD_task_get_critical_value(task);
                }
            }
        }

        sg_host_t selected_host = SD_task_get_best_host(selected_task);
        XBT_INFO("Schedule %s on %s", SD_task_get_name(selected_task), sg_host_get_name(selected_host));
        SD_task_schedule_on(selected_task, selected_host);

        xbt_dynar_free_container(&ready_tasks);
        xbt_dynar_reset(changed_tasks);
        SD_simulate_with_update(-1.0, changed_tasks);
    }

    xbt_dynar_free_container(&changed_tasks);

    double total_energy = 0;
    for (int cursor = 0; cursor < total_nhosts; cursor++)
        total_energy += sg_host_get_consumed_energy(hosts[cursor]);

    printf("Runtime Energy\n%f %f\n", SD_get_clock(), total_energy);

    {
        unsigned int cursor;
        SD_task_t task;
        xbt_dynar_foreach(dax, cursor, task) {
            SD_task_destroy(task);
        }
    }
    xbt_dynar_free_container(&dax);

    for (unsigned int cursor = 0; cursor < total_nhosts; cursor++) {
        free(sg_host_user(hosts[cursor]));
        sg_host_user_set(hosts[cursor], NULL);
    }

    free(critical_values);

    xbt_free(hosts);
    return 0;
}