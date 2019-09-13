#! /bin/sh
BENCH_HOME=/home/frappe/${BENCH_NAME}
cd ${BENCH_HOME}
SUCCESS=0

sudo nginx
# Check if specific worker is specified then start bench with args
if [ $# -ne 0 ]
then
    echo "Starting bench with args - $@"
    sudo supervisorctl start $@ >> $BENCH_LOG_FILE 2>&1 &
    BENCH_PID=`echo $!`
else
    sudo supervisorctl start all >> $BENCH_LOG_FILE 2>&1 &
    BENCH_PID=`echo $!`
fi

echo $BENCH_PID > $BENCH_HOME/${BENCH_NAME}.pid
echo "Bench started with Process ID - ${BENCH_PID}"
ps -eaf | grep ${BENCH_PID}
echo "run $@"

echo "Looking for postboot_scripts"
if [ -d $BENCH_HOME/postboot_scripts ]
then
    for file in ${BENCH_HOME}/postboot_scripts/*.sh
    do
        echo "Executing $file..."
        . "$file"
        if [ $? -ne 0 ]
        then
            echo "$file execution failed. Exiting..."
            SUCCESS=1
            break
        fi
    done
fi
if [ $SUCCESS -ne 0 ]
then
    echo "One of the post boot scripts failed... Please check logs for more information"
fi

tail -F /home/frappe/docker-bench/logs/console.log -F /home/frappe/docker-bench/logs/access.log \
    -F /home/frappe/docker-bench/logs/bench.log -F /home/frappe/docker-bench/logs/frappe.log
