----
## usage

1. 將此 docker image 存到本地端

    指令：
    ```
    docker pull ben19770209/nginx-rtmp-relay
    ```

2. 開兩台 container 作為 edge-server，用來接收 relay-server 轉傳過來的 streaming。

    指令：
    ```
    docker run -d --name rtmp-edge-1 -P -e RTMP_STREAM_NAMES=live ben19770209/nginx-rtmp-relay
    ```

    指令：
    ```
    docker run -d --name rtmp-edge-2 -P -e RTMP_STREAM_NAMES=live2 ben19770209/nginx-rtmp-relay
    ```

3. 查詢 edge-server container 在 network="bridge" 上的 ip 位置，提供給 relay-server 使用。

    (本機開發環境是將所有 relay-server 與 edge-server 都架設在同一台，因此彼此使用 docker network = "bridge" 做溝通。如果在 PROD 各 container 安裝在不同主機上，則應會使用不同 docker network 做溝通，這點要在注意。)

    指令：
    ```
    docker inspect -f {{.NetworkSettings.Networks.bridge.IPAddress}} rtmp-edge-1
    ```

    輸出：
    ```
    172.17.0.2
    ```
    
    指令：
    ```
    docker inspect -f {{.NetworkSettings.Networks.bridge.IPAddress}} rtmp-edge-2
    ```

    輸出：
    ```
    172.17.0.3
    ```

4. 查詢 edge-server container 開通 8080/tcp (看報表用) 與 1935/tcp (RTMP用) 給 host 的對外 port 是甚麼，便於開發者在本機 host 上可以透過 localhost:{post} 來瀏覽。

    指令：
    ```
    docker inspect -f {{.NetworkSettings.Ports}} rtmp-edge-1
    ```

    輸出： (run container 的參數 -P "大寫P" 會自動分配欲開通的 ports。若改用參數 -p 9999:1935 -p 8888:8080 (小寫p) 可自訂對外 ports。)
    ```
    map[1935/tcp:[{0.0.0.0 32773}] 8080/tcp:[{0.0.0.0 32772}]]
    ```
    
    指令：
    ```
    docker inspect -f {{.NetworkSettings.Ports}} rtmp-edge-2
    ```

    輸出：
    ```
    map[1935/tcp:[{0.0.0.0 32775}] 8080/tcp:[{0.0.0.0 32774}]]
    ```

5. 開一台 container 做為 relay-server，負責接收來自 publish 端的 streaming 再轉發給其他 edge-server。

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
    串流金鑰：mystream (可不填)
    ```

    OBS 2 的設定：
    ```
    伺服器名稱：rtmp://localhost/Virtual02
    串流金鑰：mystream (可不填)
    ```

7. 驗證

    * OBS 中可以於 "檢視 > 狀態" 確認直播狀態。

    * 使用 VLC 測試播放，"媒體 > 開啟網路串流" 打開 rtmp://localhost/Virtual01 ，應該可以看見 relay-server 上的 rtmp streaming。

    * 開瀏覽器 http://localhost:8080/stat ，觀看 relay-server 的報表，正常應可看到 Virtual01 > live streams > [EMPTY] (OBS中的串流金鑰 stream name) 這筆會有 4 個 clients。點選開啟後分別是：
    
        * publishing | 172.17.0.1 | (來自 OBS 的串流)
        * playing | 172.17.0.2/live/Virtual01 | (relay 到 edge-server 的串流)
        * playing | 172.17.0.3/live2/Virtual01 | (relay 到 edge-server 的串流)
        * playing | 172.17.0.1 | (本機 host 使用 VLC 播放)

    * 使用 VLC 測試播放，"媒體 > 開啟網路串流" 打開 rtmp://localhost:32773/live/Virtual01 ，應該可以看見 edge-server 上的 rtmp streaming。

    * 開瀏覽器 http://localhost:32772/stat ，觀看 edge-server 的報表，正常應可看到 live > live streams > Virtual01 (relay-server 以 application name 作為 stream name 轉送過來的) 這筆會有 2 個 clients。點選開啟後分別是：
    
        * publishing | 172.17.0.4 | (來自 relay-server 的串流)
        * playing | 172.17.0.1 | (本機 host 使用 VLC 播放)
      
