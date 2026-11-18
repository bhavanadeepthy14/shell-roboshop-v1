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

dnf module enable maven:3.9 -y &>>$logs_file
dnf install maven java-25-openjdk-devel -y &>>$logs_file
validate $? "installing maven and java"

alternatives --set java /usr/lib/jvm/java-25-openjdk/bin/java 
validate $? "setting java 25 as default java version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "setting JAVA_HOME for maven"

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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>>$logs_file
validate $? "downloading shipping"

cd /app
unzip /tmp/shipping.zip &>>$logs_file
validate $? "unzipping shipping"

mvn clean package &>>$logs_file
validate $? "installing java dependencies" 

mv target/shipping.jar shipping.jar
validate $? "moving shipping jar file"

sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service"
cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service
validate $? "copying shipping systemd service file"

dnf install mysql -y
validate $? "installing mysql client"

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
validate $? "loading shipping data"


systemctl daemon-reload &>>$logs_file
systemctl enable shipping &>>$logs_file
systemctl start shipping &>>$logs_file
validate $? "enable and start shipping service"

systemctl restart shipping
validate $? "restarting shipping"


echo "$(timestamp) [INFO] script completed in $SECONDS seconds" 
echo "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $logs_file

