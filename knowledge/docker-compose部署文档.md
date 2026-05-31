Docker Compose 部署
DockerCompose命令


Copy
version: '3'

services:
  music-tag:
    image: xhongc/music_tag_web:latest
    container_name: music-tag-web
    ports:
      - "8002:8002"
    volumes:
      - /path/to/your/music:/app/media
      - /path/to/your/config:/app/data
      - /path/to/your/download:/app/download
    restart: always
将 /path/to/your/music 替换为你的 NAS 上音乐文件夹的绝对路径。

将 /path/to/your/config 替换为你新建的一个目录路径，用于存放应用程序的配置文件。

/path/to/your/download 替换为你新下载音乐的目录，不与媒体库重复和重合，用于后台刮削监控目录