----
## usage

1. 將此 docker image 存到本地端

    指令：
    ```
    docker pull ben19770209/nginx-rtmp-relay
    ```

2. 開兩台 container 作為 edge server

    指令：
    ```
    docker run -d --name rtmp-edge-1 -P -e RTMP_STREAM_NAMES=live ben19770209/nginx-rtmp-relay
    ```

    指令：
    ```
    docker run -d --name rtmp-edge-2 -P -e RTMP_STREAM_NAMES=live2 ben19770209/nginx-rtmp-relay
    ```

3. 查詢 container 的網路位置

    指令：
    ```
    docker network inspect bridge
    ```

    輸出：
    ```
    [
        {
            "Name": "bridge",
            "Id": "786f1a774479f3112324ed3aaa8b50e4a54972ee6f6d902a595af5af1138798f",
            "Created": "2020-02-21T00:03:58.134741997Z",
            "Scope": "local",
            "Driver": "bridge",
            "EnableIPv6": false,
            "IPAM": {
                "Driver": "default",
                "Options": null,
                "Config": [
                    {
                        "Subnet": "172.17.0.0/16",
                        "Gateway": "172.17.0.1"
                    }
                ]
            },
            "Internal": false,
            "Attachable": false,
            "Ingress": false,
            "ConfigFrom": {
                "Network": ""
            },
            "ConfigOnly": false,
            "Containers": {
                "3034b8e29f4da05a62bb33873a6b928e5a277b4caa4198e16d67ebe09a2606e9": {
                    "Name": "rtmp-edge-2",
                    "EndpointID": "a5155d6085e1a06938eaec7dcea2172a16651ccec6493f996e17e9a9df8d6fc0",
                    "MacAddress": "02:42:ac:11:00:03",
                    "IPv4Address": "172.17.0.3/16",
                    "IPv6Address": ""
                },
                "7fd8811ba4c4e51ea904d6144b0f3c52b4c4109765c3b5a75cead2a3443bf277": {
                    "Name": "rtmp-edge-1",
                    "EndpointID": "8304b75783b8be12c3f73151b1869fbcc21c8a322e98dd425f3df3227bb0b270",
                    "MacAddress": "02:42:ac:11:00:02",
                    "IPv4Address": "172.17.0.2/16",
                    "IPv6Address": ""
                }
            },
            "Options": {
                "com.docker.network.bridge.default_bridge": "true",
                "com.docker.network.bridge.enable_icc": "true",
                "com.docker.network.bridge.enable_ip_masquerade": "true",
                "com.docker.network.bridge.host_binding_ipv4": "0.0.0.0",
                "com.docker.network.bridge.name": "docker0",
                "com.docker.network.driver.mtu": "1500"
            },
            "Labels": {}
        }
    ]
    ```

4. 查詢 container 的 port

    指令：
    ```
    docker ps
    ```

    輸出：
    ```
    CONTAINER ID        IMAGE                          COMMAND                CREATED              STATUS              PORTS                                              NAMES
    3034b8e29f4d        ben19770209/nginx-rtmp-relay   "/bin/sh -c /run.sh"   52 seconds ago       Up 51 seconds       0.0.0.0:32793->1935/tcp, 0.0.0.0:32792->8080/tcp   rtmp-edge-2
    7fd8811ba4c4        ben19770209/nginx-rtmp-relay   "/bin/sh -c /run.sh"   About a minute ago   Up About a minute   0.0.0.0:32791->1935/tcp, 0.0.0.0:32790->8080/tcp   rtmp-edge-1
    ```

5. 開一台 container 做為負責 relay 的 rtmp server

    指令：
    ```
    docker run -it --name myRtmpRelay -p 1935:1935 -p 8080:8080 -e RTMP_STREAM_NAMES=Virtual01,Virtual02 -e RTMP_PUSH_URLS=rtmp://172.17.0.2/live,rtmp://172.17.0.3/live2 -e RTMP_PUSH_ARGS="'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'" ben19770209/nginx-rtmp-relay
    ```

    輸出：
    ```
    Creating config
    Creating application Virtual01
    Pushing stream to rtmp://172.17.0.2/live/Virtual01 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    Pushing stream to rtmp://172.17.0.3/live2/Virtual01 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    Creating application Virtual02
    Pushing stream to rtmp://172.17.0.2/live/Virtual02 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    Pushing stream to rtmp://172.17.0.3/live2/Virtual02 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    Starting server...
    ```

    參數：
        
    * -e RTMP_STREAM_NAMES=Virtual01,Virtual02

    建立多個 rtmp application。
    
    ```
    rtmp://{url}:{port}/Virtual01
    rtmp://{url}:{port}/Virtual02
    ```

    * -e RTMP_PUSH_URLS=rtmp://172.17.0.2/live,rtmp://172.17.0.3/live2

    每個 rtmp application (Virtual01,Virtual02,...) 都會將收到的 streaming 做 push 到 {RTMP_PUSH_URLS}/{application name} 的動作。

    例：發佈到 rtmp://localhost/Virtual01 的 mystream，會被自動轉送到：

    ```
    rtmp://172.17.0.2/live/Virtual01
    rtmp://172.17.0.3/live2/Virtual01
    ```

    例：發佈到 rtmp://localhost/Virtual02 的 mystream，會被自動轉送到：

    ```
    rtmp://172.17.0.2/live/Virtual02
    rtmp://172.17.0.3/live2/Virtual02
    ```

    * -e RTMP_PUSH_ARGS="'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'"

    每個自動 push 到 edge server 時所要夾帶的參數。

    例：Virtual01 被轉送時，後面都會夾帶 flashVer 參數如下。

    ```
    rtmp://172.17.0.2/live/Virtual01 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    rtmp://172.17.0.3/live2/Virtual01 'flashVer=FMLE/3.0 (compatible; FMSc/1.0)'
    ```

6. 設定 OBS

    OBS 1 的設定：
    ```
    伺服器名稱：rtmp://localhost/Virtual01
    串流金鑰：mystream
    ```

    OBS 2 的設定：
    ```
    伺服器名稱：rtmp://localhost/Virtual02
    串流金鑰：mystream
    ```
