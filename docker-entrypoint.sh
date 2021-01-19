#!/bin/bash

if [ ! -f "/var/lib/mysql/ibdata1" ]; then
    echo "- Initializing database"
    sudo -u mysql /usr/bin/mysql_install_db --force &> /dev/null

    echo "- Updating MySQL directory permissions"
    chown -R -f mysql:mysql /var/lib/mysql
    chown -R -f mysql:mysql /var/run/mariadb
fi

if [ ! -d "/var/lib/mysql/slurm_acct_db" ]; then
    sudo -u mysql /usr/bin/mysqld_safe --datadir="/var/lib/mysql" &

    for count in {30..0}; do
        if echo "SELECT 1" | mysql &> /dev/null; then
            break
        fi
        echo "- Starting MariaDB to create Slurm account database"
        sleep 1
    done

    if [[ "$count" -eq 0 ]]; then
        echo >&2 "MariaDB did not start"
        exit 1
    fi
    
    echo "- Creating Slurm acct database"
    mysql -u root -NBe "CREATE DATABASE slurm_acct_db"
    mysql -u root -NBe "CREATE USER 'slurm'@'localhost'"
    mysql -u root -NBe "SET PASSWORD for 'slurm'@'localhost' = password('password')"
    mysql -u root -NBe "GRANT USAGE ON *.* to 'slurm'@'localhost'"
    mysql -u root -NBe "GRANT ALL PRIVILEGES on slurm_acct_db.* to 'slurm'@'localhost'"
    mysql -u root -NBe "FLUSH PRIVILEGES"
    echo "- Slurm acct database created. Stopping MariaDB"
    sudo killall mysqld
    for count in {30..0}; do
        if echo "SELECT 1" | mysql &> /dev/null; then
            sleep 1
        else
            break
        fi
    done
    if [[ "$count" -eq 0 ]]; then
        echo >&2 "MariaDB did not stop"
        exit 1
    fi
fi

chown -R -f slurm:slurm /var/spool/slurmd /var/run/slurmd /var/lib/slurmd /var/log/slurm

echo "- Starting all Slurm processes under supervisord"
sudo /usr/bin/supervisord --configuration /etc/supervisord.conf

sudo sed -i s/ernie/$(< /etc/hostname)/ /etc/slurm/slurm.conf 

# The following is not needed in slurm > 20.02 (the cluster is created
# automatically if it doesn't exist)
echo "Slurm daemons are starting up..."
for count in {30..0}; do
    if sudo supervisorctl status | grep -v RUNNING > /dev/null; then
        sleep 1
    else
        break
    fi
done
if [[ "$count" -eq 0 ]]; then
    echo >&2 "Daemons did not start"
    exit 1
fi

# Give a few more seconds for daemons to actually become responsive.
echo "Slurm is initializing..."
sleep 5
echo "Creating cluster..."
yes | sudo sacctmgr add cluster linux > /dev/null
sudo supervisorctl restart slurmctld > /dev/null
# Ensure slurmctld becomes responsive again
sleep 3

exec "$@"
