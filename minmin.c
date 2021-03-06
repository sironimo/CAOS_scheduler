#include <string.h>
#include <simgrid/simdag.h>
#include <simgrid/plugins/energy.h>
#include <stdio.h>
#include "util.h"

XBT_LOG_NEW_DEFAULT_CATEGORY(scheduler, "Logging specific to this SimDag example");

/*
 * Min-Min Algorithm basically copied from the SimGrid examples and described here
 * http://simgrid.gforge.inria.fr/tutorials/simdag-101.pdf
 */
int main(int argc, char **argv) {
    sg_host_energy_plugin_init();
    SD_init(&argc, argv);

    xbt_assert(argc > 2, "Usage: %s platform_file dax_file \n"
            "\tExample: %s simulacrum_7_hosts.xml Montage_25.xml", argv[0], argv[0]);

    SD_create_environment(argv[1]);

    size_t total_nhosts = sg_host_count();
    sg_host_t *hosts = sg_host_list();

    for (unsigned int cursor = 0; cursor < total_nhosts; cursor++)
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

    /* Schedule the root first */
    {
        SD_task_t root;
        xbt_dynar_get_cpy(dax, 0, &root);
        sg_host_t host = SD_task_get_fastest_host(root);
        SD_task_schedulel(root, 1, host);
    }
    xbt_dynar_t changed_tasks = xbt_dynar_new(sizeof(SD_task_t), NULL);
    SD_simulate_with_update(-1.0, changed_tasks);

    while (!xbt_dynar_is_empty(changed_tasks)) {
        /* Get the set of ready tasks */
        xbt_dynar_t ready_tasks = get_ready_tasks(dax);
        xbt_dynar_reset(changed_tasks);

        if (xbt_dynar_is_empty(ready_tasks)) {
            xbt_dynar_free_container(&ready_tasks);
            /* there is no ready task, let advance the simulation */
            SD_simulate_with_update(-1.0, changed_tasks);
            continue;
        }

        /* For each ready task:
         * get the host that minimizes the completion time.
         * select the task that has the minimum completion time on its best host.
         */
        SD_task_t selected_task = NULL;
        sg_host_t selected_host = NULL;
        double min_finish_time = -1;
        {
            unsigned int cursor;
            SD_task_t task;
            xbt_dynar_foreach(ready_tasks, cursor, task) {
                sg_host_t host = SD_task_get_fastest_host(task);
                double finish_time = predict_finish_time(task, host);
                if (min_finish_time < 0 || finish_time < min_finish_time) {
                    min_finish_time = finish_time;
                    selected_task = task;
                    selected_host = host;
                }
            }
        }

        XBT_INFO("Schedule %s on %s", SD_task_get_name(selected_task), sg_host_get_name(selected_host));
        SD_task_schedule_on(selected_task, selected_host);

        xbt_dynar_free_container(&ready_tasks);
        xbt_dynar_reset(changed_tasks);
        SD_simulate_with_update(-1.0, changed_tasks);
    }

    double total_energy = 0;
    for (unsigned int cursor = 0; cursor < total_nhosts; cursor++)
        total_energy += sg_host_get_consumed_energy(hosts[cursor]);

    printf("Runtime Energy\n%f %f\n", SD_get_clock(), total_energy);

    xbt_dynar_free_container(&changed_tasks);

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

    xbt_free(hosts);
    return 0;
}
