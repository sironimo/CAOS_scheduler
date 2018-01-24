#include <simgrid/simdag.h>
#include <simgrid/plugins/energy.h>
#include <xbt.h>

XBT_LOG_NEW_DEFAULT_CATEGORY(scheduler, "Logging specific to this scheduler");

/* bare-bones round-robin scheduler:
 * cycles through hosts and distributes tasks
 *  
 * Usage:
 *  ./round_robin env.xml app.xml
 */
int main(int argc, char **argv) {
    sg_host_energy_plugin_init();
    SD_init(&argc, argv);

    xbt_assert(argc > 2, "Usage: %s platform_file dax_file \n"
            "\tExample: %s simulacrum_7_hosts.xml Montage_25.xml", argv[0], argv[0]);

    xbt_dynar_t dax = SD_daxload(argv[2]);

    SD_create_environment(argv[1]);

    size_t total_nhosts = sg_host_count();
    sg_host_t *hosts = sg_host_list();

    {
        unsigned int cpt = 0, k = 0;
        SD_task_t task;

        xbt_dynar_foreach(dax, k, task) {
            if (SD_task_get_kind(task) == SD_TASK_COMP_SEQ) {
                XBT_INFO("Schedule %s on %s", SD_task_get_name(task), sg_host_get_name(hosts[cpt]));
                SD_task_schedulel(task, 1, hosts[cpt]);
                cpt = (cpt + 1) % total_nhosts;
            }
        }
    }

    SD_simulate(-1);

    double total_energy = 0;
    for (int cursor = 0; cursor < total_nhosts; cursor++) {
        total_energy += sg_host_get_consumed_energy(hosts[cursor]);
    }

    printf("Runtime Energy\n%f %f\n", SD_get_clock(), total_energy);

    {
        unsigned int cursor;
        SD_task_t task;
        xbt_dynar_foreach(dax, cursor, task) {
            SD_task_destroy(task);
        }
    }
    xbt_dynar_free_container(&dax);

    xbt_free(hosts);
    return 0;
}
