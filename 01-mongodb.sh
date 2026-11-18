#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/shell-practice"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
if [ $user_id -ne 0 ]; then
  echo "please run this script with sudo access.."
  exit 1
fi

mkdir -p $logs_folder

echo "script started execution at $(date +"%F %T")" &>>$logs_file
 
 validate () 
{
    if [ $1 -ne 0 ]; then
        echo -e "{$2}..${R}failed${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "{$2}..${G}success${N}" | tee -a $logs_file
    fi
}

cp mongodb.repo /etc/yum.repos.d/mongodb.repo 
validate $? "Adding mongo repo"

dnf install mongodb-org -y
validate $? "Install mongodb"

systemctl enable mongod
systemctl start mongod
validate $? "enable and start mongodb"