#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/shell-practice"
logs_file="${logs_folder}/${0}.log"
domain_name="daws99.store"
scripts_dir=$(dirname "$(realpath "$0")")
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

dnf module disable nodejs -y &>>$logs_file
dnf module enable nodejs:24 -y &>>$logs_file
dnf install nodejs -y &>>$logs_file
validate $? "installing nodejs"

id roboshop &>>$logs_file
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$logs_file
validate $? "creating roboshop system user"
else
    echo -e "$(timestamp) [INFO] system user roboshop already exists....${Y}skipping${N}" 
fi

rm -rf /app 
validate $? "removing old code"

mkdir -p /app
validate $? "creating app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>>$logs_file
validate $? "downloading catalogue"

cd /app
unzip /tmp/catalogue.zip &>>$logs_file
validate $? "unzipping catalogue"

npm install &>>$logs_file
validate $? "installing nodejs dependencies" 

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/catalogue.service"
cp "$scripts_dir/catalogue.service" /etc/systemd/system/catalogue.service
validate $? "copying catalogue systemd service file"

systemctl daemon-reload &>>$logs_file
systemctl enable catalogue &>>$logs_file
systemctl start catalogue &>>$logs_file
validate $? "enable and start catalogue service"

cp "$scripts_dir/mongo.repo" /etc/yum.repos.d/mongo.repo
validate $? "Adding Mongo repo"

dnf install mongodb-mongosh -y &>>$logs_file
validate $? "installing mongodb client"


echo "$(timestamp) [INFO] script completed in $SECONDS seconds" 
echo "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $logs_file

