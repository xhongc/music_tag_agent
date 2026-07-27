# 为已部署的 Music Tag Web 增加 Music Tag Agent

本文适用于已经通过 Docker Compose 部署 Music Tag Web 的用户。目标是在现有 `music-tag` 服务旁边新增一个 `music-tag-agent` 服务，并让 MTW 右下角的 AI 助手连接到该 Agent。

推荐优先使用环境变量部署 Agent。Agent 启动时会根据环境变量自动生成 OpenCode 配置文件，无需手动创建或挂载 `opencode.json`。用户只需要填写模型服务地址、API Key 和模型 ID。

## 1. 原始 Music Tag Web 配置

常见的默认 `docker-compose.yml` 类似下面这样：

```yaml
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
```

## 2. 增加 Agent 后的配置

在原 `docker-compose.yml` 中追加 `music-tag-agent` 服务，同时给 `music-tag` 服务增加 `AGENT_URL`：

```yaml
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
    environment:
      - AGENT_URL=http://music-tag-agent:9002
    restart: always

  music-tag-agent:
    image: xhongc/music_tag_agent:latest
    container_name: music-tag-agent
    depends_on:
      - music-tag  # 依赖于 music-tag mcp 服务
    ports:
      - "9002:9002"
    restart: unless-stopped
    environment:
      - OPENCODE_SERVER_USERNAME=admin
      - OPENCODE_SERVER_PASSWORD=admin123
      - OPENCODE_PROVIDER_ID=my
      - OPENCODE_PROVIDER_BASE_URL=https://api.deepseek.com/v1
      - OPENCODE_PROVIDER_API_KEY=sk-xxx
      - OPENCODE_MODEL_ID=deepseek-v4-flash
```

其中，下面这些路径需要替换为你自己的实际目录：

- `/path/to/your/music`：你的音乐目录。
- `/path/to/your/config`：MTW 配置数据目录。
- `/path/to/your/download`：下载目录。

## 3. 最小化环境变量

`music-tag` 容器只需要新增 1 个变量：

- `AGENT_URL`：MTW 访问 Agent 的地址。使用上面的 Compose 服务名时填写 `http://music-tag-agent:9002`。

`music-tag-agent` 容器只需要配置下面 6 个变量：

- `OPENCODE_SERVER_USERNAME`：Agent 登录账号。示例使用 `admin`。
- `OPENCODE_SERVER_PASSWORD`：Agent 登录密码。建议改成更复杂的密码，避免 9002 端口暴露后被他人调用模型 API。
- `OPENCODE_PROVIDER_ID`：模型服务的 provider 标识。示例使用 `my`，后续在 MTW 中填写同一个 provider。
- `OPENCODE_PROVIDER_BASE_URL`：OpenAI 兼容接口地址。DeepSeek 示例为 `https://api.deepseek.com/v1`。
- `OPENCODE_PROVIDER_API_KEY`：模型服务 API Key。把 `sk-xxx` 替换为你自己的 Key。
- `OPENCODE_MODEL_ID`：要使用的模型 ID。示例为 `deepseek-v4-flash`，需要和你的模型服务支持的模型名一致。

配置 `OPENCODE_SERVER_USERNAME` 和 `OPENCODE_SERVER_PASSWORD` 后，需要在 MTW 的 `系统设置 - API 管理` 中填写相同的 Agent 账号和密码。

注意：不要把真实 API Key 提交到 Git 仓库，也不要出现在截图或公开文档中。

## 4. 启动或更新服务

在 `docker-compose.yml` 所在目录执行：

```bash
docker compose up -d
```

如果你的环境使用旧版命令：

```bash
docker-compose up -d
```

查看容器状态：

```bash
docker ps
```

查看 Agent 日志：

```bash
docker logs -f music-tag-agent
```

## 5. 在 Music Tag Web 中启用 AI 助手

进入 MTW 后打开 `系统设置 - API 管理`：

- Agent 地址使用 `/opencode` 默认不要修改。
- Agent 账号填写 `OPENCODE_SERVER_USERNAME` 的值。
- Agent 密码填写 `OPENCODE_SERVER_PASSWORD` 的值。
- Provider ID 填写 `OPENCODE_PROVIDER_ID` 的值，例如 `my`。
- Model ID 填写 `OPENCODE_MODEL_ID` 的值，例如 `deepseek-v4-flash`。

保存后，右下角 AI 助手即可连接到 `music-tag-agent`。
