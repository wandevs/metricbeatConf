# metricbeat tools

Use for system monitor for wanchain.

```
wget https://raw.githubusercontent.com/wandevs/metricbeatConf/main/metricbeatInstall.sh  &&  chmod +x metricbeatInstall.sh  && ./metricbeatInstall.sh

sudo metricbeat modules list

sudo metricbeat modules enable XXXXX

sudo systemctl restart metricbeat

```
change password:
```
echo NEW_PASS_WORD | sudo metricbeat keystore add ES_PWD --stdin --force

sudo systemctl restart metricbeat
```
