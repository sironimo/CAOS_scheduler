#include <simdag/simdag.h>
#include <xbt.h>


int main(int argc, char **argv){
    SD_init(&argc, argv);
    
    SD_task_t c1, c2, c3, t1, tmp;
    unsigned int ctr;
    xbt_dynar_t tasks = xbt_dynar_new(sizeof(SD_task_t), &xbt_free);

    // computing tasks
    c1 = SD_task_create_comp_seq("c1", NULL, 1e9);
    c2 = SD_task_create_comp_seq("c2", NULL, 5e9);
    c3 = SD_task_create_comp_seq("c3", NULL, 2e9);

    //transfer tasks
    t1 = SD_task_create_comm_e2e("t1", NULL, 5e8);

    //dependencies
    SD_task_dependency_add("c1-t1", NULL, c1, t1);
    SD_task_dependency_add("t1-c3", NULL, t1, c3);
    SD_task_dependency_add("c2-c3", NULL, c2, c3);
    
    xbt_dynar_push(tasks, &c1);
    xbt_dynar_push(tasks, &c2);
    xbt_dynar_push(tasks, &c3);
    xbt_dynar_push(tasks, &t1);

    xbt_dynar_foreach(tasks, ctr, tmp) {
        SD_task_dump(tmp);
        SD_task_destroy(tmp);
    }

    xbt_dynar_free_container(&tasks);

    SD_exit();
    return 0;
}
