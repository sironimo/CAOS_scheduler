#include <string.h>
#include <simgrid/simdag.h>
#include <stdio.h>

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
 * Estimate the time needed to execute critical path on fastest host.
 */
int main(int argc, char **argv) {
    SD_init(&argc, argv);

    xbt_assert(argc > 2, "Usage: %s platform_file dax_file \n"
            "\tExample: %s simulacrum_7_hosts.xml Montage_25.xml", argv[0], argv[0]);

    SD_create_environment(argv[1]);

    size_t total_nhosts = sg_host_count();
    sg_host_t *hosts = sg_host_list();
    sg_host_t host = NULL;

    double max_speed = -1.0;
    for (int cursor = 0; cursor < total_nhosts; cursor++) {
        if( max_speed < 0 || sg_host_speed(hosts[cursor]) > max_speed) {
            max_speed = sg_host_speed(hosts[cursor]);
            host = hosts[cursor];
        }
    }

    xbt_dynar_t dax = SD_daxload(argv[2]);

    XBT_INFO("Fastest host is %s", sg_host_get_name(host));

    /* allocate space for critical values and compute them */
    double *critical_values = calloc(xbt_dynar_length(dax), sizeof(double));
    backflow_critical_values(dax, critical_values);

    /* Schedule the root first */
    SD_task_t root;
    xbt_dynar_get_cpy(dax, 0, &root);
    double finish_time = 0;

    xbt_dynar_t children = SD_task_get_children(root);
    while(!xbt_dynar_is_empty(children)) {
        double critical_value = -1.0;
        SD_task_t next_task = NULL;
        {
            unsigned int cursor;
            SD_task_t task;
            xbt_dynar_foreach(children, cursor, task) {
                if( critical_value < 0 || SD_task_get_critical_value(task) > critical_value ) {
                    next_task = task;
                    critical_value = SD_task_get_critical_value(task);
                }
            }
        }

        finish_time += SD_task_get_amount(next_task)/ sg_host_speed(host);

        root = next_task;
        xbt_dynar_free_container(&children);
        children = SD_task_get_children(root);
    }

    printf("Runtime Energy\n%f %f\n", finish_time, -1.0);
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