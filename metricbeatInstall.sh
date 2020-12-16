#!/bin/bash
# Org: Wanchain
# Author:Guo Wei
# metricbeat installation 

version='6.8.9' #get from http://log.wanchain.org:5601/app/kibana#/home/tutorial/kibanaMetrics?_g=()
metricbeat_yml='https://raw.githubusercontent.com/Nevquit/metricbeatConf/main/metricbeat-v1.yml'
#Input ES password
echo 'Enter the password of elastic:'
read -s ES_PWD
echo 'Confirm the password of elastic::'
read -s ES_PWD2
echo ''

if [ ${ES_PWD} != ${ES_PWD2} ]
then
    echo 'Passwords mismatched'
    exit
fi

#Save the user and password in keystore
echo $ES_PWD   | sudo metricbeat keystore add ES_PWD --stdin --force

echo "############## Download&Install metricbeat "$version" ..."
cd ~/download
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-$version-amd64.deb
sudo dpkg -i metricbeat-$version-amd64.deb

echo "############## Download metricbeat.yml ..."
wget $metricbeat_yml
sudo cp -f metricbeat-v1.yml /etc/metricbeat/metricbeat.yml

echo "################### start metricbeat service ..."
sudo systemctl enable metricbeat
sudo systemctl start metricbeat
