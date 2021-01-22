# metricbeat tools

Use for system monitor for wanchain.

```
wget https://raw.githubusercontent.com/wandevs/metricbeatConf/main/metricbeatInstall.sh  &&  chmod +x metricbeatInstall.sh  && ./metricbeatInstall.sh

sudo metricbeat modules list

sudo metricbeat modules enable XXXXX

sudo systemctl restart metricbeat

```

Config for nginx

```
$ sudo metricbeat modules enable nginx

$ sudo vi /etc/metricbeat/modules.d/nginx.yml

# Module: nginx
# Docs: https://www.elastic.co/guide/en/beats/metricbeat/6.8/metricbeat-module-nginx.html

- module: nginx
  metricsets:
    - stubstatus
  period: 10s

  # Nginx hosts
  hosts: ["http://127.0.0.1"]

  # Path to server status. Default server-status
  server_status_path: "nginx_status"

  #username: "user"
  #password: "secret"
```
$ sudo vi /etc/nginx/sites-enabled/default

	server_name _;
	location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
	}
  

