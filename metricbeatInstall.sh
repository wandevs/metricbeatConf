#!/bin/bash
# Org: Wanchain
# Author:Guo Wei
# metricbeat installation 

version='6.8.9' #get from http://log.wanchain.org:5601/app/kibana#/home/tutorial/kibanaMetrics?_g=()
metricbeat_yml='https://raw.githubusercontent.com/wandevs/metricbeatConf/main/metricbeat-v1.yml'

#Clean env
echo "################### Clean env############"
sudo systemctl stop metricbeat
sudo dpkg -l metricbeat
sudo dpkg -r metricbeat
sudo dpkg -P metricbeat

#Input ES password
echo 'Enter the password of elastic:'
read -s PWD
echo 'Confirm the password of elastic:'
read -s PWD2
echo ''
echo 'Enter hostname displyaed in elastic'
read host

if [ ${PWD} != ${PWD2} ]
then
    echo 'Passwords mismatched'
    exit
fi

echo "############## Download&Install metricbeat "$version" ..."
cd ~/download
curl -L -O https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-$version-amd64.deb
sudo dpkg -i metricbeat-$version-amd64.deb

#Save the user and password in keystore
echo $PWD   | sudo metricbeat keystore add ES_PWD --stdin --force
echo $host   | sudo metricbeat keystore add HS_node --stdin --force


echo "############## Download metricbeat.yml ..."
wget $metricbeat_yml
sudo cp -f metricbeat-v1.yml /etc/metricbeat/metricbeat.yml

echo "################### start metricbeat service ..."
sudo systemctl enable metricbeat
sudo systemctl start metricbeat
