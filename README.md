# Hei.PrometheusFileBaseServiceDiscover
监控解决方案prometheus，基于文件的服务发现配置脚本，使用OpenResty+Lua实现



# 背景

prometheus可以使用Consul、k8s等方式做服务发现，也可以基于文件配置的服务发现。

基于文件配置服务发现需要手动去修改文件，然后prometheus再去刷新文件配置这样，而如果我们服务很多，我想用Rest接口Post请求配置，直接修改文件。这样就可以程序在启动时调用注册接口，程序停止时调用撤销注册接口，就可以做到一个粗糙版本的服务发现了。

我选用的是OpenResty+Lua实现。



# 部署

## prometheus配置

```
scrape_configs:
- job_name: 'file_ds'
  file_sd_configs:
  - refresh_interval: 10s #10秒刷新一次
    files:
     /etc/prometheus/*.yml
```



## OpenResty

```
 location /prometheus {
	   content_by_lua_file /home/website/prometheus/prometheus-filebase-servicediscover.lua;  
 }

error_log   /var/log/nginx/prometheus.error.log   debug; #开始跑的时候建议把debug日志打开
```



# 使用

## 注册服务

```
curl --location --request POST 'http://172.16.3.117:81/prometheus?target=2' \
--header 'Content-Type: application/json' \
--data-raw '  {
    "type":"registe",
    "targets": ["172.16.3.119:91012", "172.16.3.117:91221"],
    "labels": {
      "env": "dev",
      "app": "container3"
    }
  }'
```

响应：

```
{
    "status": 200,
    "message": "注册配置成功"
}
```



## 注销服务

```
curl --location --request POST 'http://172.16.3.117:81/prometheus?target=2' \
--header 'Content-Type: application/json' \
--data-raw '  {
    "type":"deregiste",
    "targets": ["172.16.3.119:91012", "172.16.3.117:91221"],
    "labels": {
      "env": "dev",
      "app": "container3"
    }
  }'
```
响应：

```
{
    "status": 200,
    "message": "注销配置成功"
}
```

