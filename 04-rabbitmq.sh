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
 
timestamp(){
    date +"%F %T"
}
 validate () 
{
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] {$2}..${R}failed${N}" | tee -a $logs_file
        exit 1
    else
        echo -e "$(timestamp) [INFO] {$2}..${G}success${N}" | tee -a $logs_file
    fi
}

echo "$(timestamp) [INFO] ===== script started execution =====" | tee -a $logs_file

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
validate $? "Adding rabbitmq repo"

dnf install erlang rabbitmq-server -y &>>$logs_file
validate $? "installing rabbitmq"

systemctl enable rabbitmq-server &>>$logs_file
systemctl start rabbitmq-server &>>$logs_file
validate $? "enable and start rabbitmq"

rabbitmqctl list_users  |  grep -qw "roboshop"
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123 &>>$logs_file
    validate $? "setup rabbitmq user for roboshop"
else
    echo "$(timestamp) [INFO] roboshop user already exists....${Y}skipping${N}" 
fi
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$logs_file
validate $? "setup rabbitmq permissions for roboshop"

echo "$(timestamp) [INFO] script completed in $SECONDS seconds" 
echo "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $logs_file

