#!/usr/bin/env bash

#SBATCH --job-name=check_running_server

echo -e "Server:\n"
#check if server is running
ping -c 2 130.92.9.53

echo -e "Website:\n"
#check again if server is running
ping -c 2 130.92.121.14

#check if server component needed for website are running
ps aux | grep -e gunicorn -e http-server

echo -e "jobs running \n"
squeue
