## 安装
安装 OpenCode 最简单的方法是通过安装脚本。

```bash
curl -fsSL https://opencode.ai/install | bash
```

你也可以使用以下方式安装：

### 使用 Node.js

```bash
npm install -g opencode-ai
```

### 在 macOS 和 Linux 上使用 Homebrew

```bash
brew install anomalyco/tap/opencode
```

我们推荐使用 OpenCode tap 以获取最新版本。官方的 `brew install opencode` formula 由 Homebrew 团队维护，更新频率较低。

### 在 Arch Linux 上安装

```bash
sudo pacman -S opencode           # Arch Linux (Stable)
paru -S opencode-bin              # Arch Linux (Latest from AUR)
```

### Windows

推荐使用 WSL，以获得更好的性能和完整功能支持。

```bash
choco install opencode
scoop install opencode
npm install -g opencode-ai
mise use -g github:anomalyco/opencode
```

### 使用 Docker

```bash
docker run -it --rm ghcr.io/anomalyco/opencode
```

你也可以从 Releases 页面直接下载二进制文件。

## `opencode serve` 启动命令

`opencode serve` 会启动一个无界面的 HTTP 服务器，并暴露 OpenAPI 端点供客户端调用。

### 用法

```bash
opencode serve [--port <number>] [--hostname <string>] [--cors <origin>]
```

### 选项

- `--port`：监听端口，默认 `4096`
- `--hostname`：监听主机名，默认 `127.0.0.1`
- `--mdns`：启用 mDNS 发现
- `--mdns-domain`：自定义 mDNS 域名，默认 `opencode.local`
- `--cors`：额外允许的浏览器来源，可重复传递

```bash
opencode serve --cors http://localhost:5173 --cors https://app.example.com
```

### 认证

设置 `OPENCODE_SERVER_PASSWORD` 可以启用 HTTP Basic Auth，默认用户名为 `opencode`，也可以通过 `OPENCODE_SERVER_USERNAME` 覆盖。

```bash
OPENCODE_SERVER_PASSWORD=your-password opencode serve
```

## Docker 镜像构建

项目内已经提供了轻量化 `Dockerfile`，用于在容器中直接启动 `opencode serve`。

### 构建镜像

```bash
docker build -t ai_story-agent .
```

### 多架构构建

使用 Buildx 可以构建 `linux/amd64` 和 `linux/arm64` 多架构镜像。

本地测试单架构镜像：

```bash
docker buildx build \
  --platform linux/amd64 \
  -t ai_story-agent:latest \
  --load \
  .
```

推送多架构镜像到仓库：

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t your-registry/ai_story-agent:latest \
  --push \
  .
```

普通 `docker build` 时如果没有显式传入 `TARGETARCH`，`Dockerfile` 也会回退到 `uname -m` 自动识别当前构建架构。

### 运行容器

```bash
docker run --rm -p 9002:9002 \
  -e OPENCODE_SERVER_PASSWORD=your-password \
  ai_story-agent
```

### 可选环境变量

- `OPENCODE_PORT`：服务监听端口，默认 `9002`
- `OPENCODE_HOSTNAME`：服务监听地址，默认 `0.0.0.0`
- `OPENCODE_CORS`：以逗号分隔的 CORS 来源列表，例如 `http://localhost:5173,https://app.example.com`
- `OPENCODE_MDNS`：设置为任意非空值时启用 `--mdns`
- `OPENCODE_MDNS_DOMAIN`：对应 `--mdns-domain`
- `OPENCODE_SERVER_PASSWORD`：启用 Basic Auth
- `OPENCODE_SERVER_USERNAME`：自定义 Basic Auth 用户名
- `OPENCODE_CONFIG_FILE`：配置文件写入路径，默认 `/home/opencode/.config/opencode/opencode.json`
- `OPENCODE_CONFIG_TEMPLATE`：配置模板，默认 `compatible`；也支持 `openai-compatible`
- `OPENCODE_PROVIDER_ID`：provider key，默认 `myprovider`
- `OPENCODE_PROVIDER_NPM`：provider npm 包，默认 `@ai-sdk/openai-compatible`
- `OPENCODE_PROVIDER_NAME`：provider 显示名称，默认等于 `OPENCODE_PROVIDER_ID`
- `OPENCODE_PROVIDER_BASE_URL`：provider API 地址
- `OPENCODE_PROVIDER_API_KEY`：provider API Key，直接写入 `options.apiKey`
- `OPENCODE_PROVIDER_AUTHORIZATION`：可选，写入 `headers.Authorization`；默认不写入 `headers`
- `OPENCODE_MODEL_ID`：model key，默认 `my-model-name`；支持用逗号配置多个模型，例如 `deepseek-v4-flash,qwen3-coder`
- `OPENCODE_MODEL_NAME`：model 显示名称，默认等于 `OPENCODE_MODEL_ID`；配置多个模型时也可用逗号按顺序指定显示名称
- `OPENCODE_MODEL_CONTEXT`：可选，上下文限制；默认不写入 `limit`
- `OPENCODE_MODEL_OUTPUT`：可选，输出限制；默认不写入 `limit`
- `MCP_URL`：Music Tag MCP 地址，默认 `http://music-tag:8002/mcp/`
- `MCP_ACCESS_TOKEN`：可选，Music Tag 系统 access token；传入后写入 `mcp.music-tag.headers.Authorization`，为空时不写入 `headers`；未以 `Bearer ` 开头时会自动补上

### 示例1

```bash
docker run --rm -p 9002:9002 \
  -e OPENCODE_PORT=9002 \
  -e OPENCODE_HOSTNAME=0.0.0.0 \
  -e OPENCODE_CORS=http://localhost:5173,https://app.example.com \
  -e OPENCODE_SERVER_PASSWORD=your-password \
  ai_story-agent
```

### 通过固定模板生成 `opencode.json`

```bash
docker run --rm -p 9002:9002 \
  -e OPENCODE_PROVIDER_ID=myprovider \
  -e OPENCODE_PROVIDER_BASE_URL=https://api.myprovider.com/v1 \
  -e OPENCODE_PROVIDER_API_KEY=your-api-key \
  -e OPENCODE_MODEL_ID=my-model-name,backup-model-name \
  ai_story-agent
```

### 容器特性

- 容器以单进程方式直接运行 `opencode serve`
- 构建阶段按 `linux/amd64` / `linux/arm64` 直接安装对应的 Alpine/musl 原生包，并复制二进制到运行镜像
- 使用 Alpine 多阶段构建，运行镜像不再包含 Node.js、npm 和 curl，以进一步减少体积
- 使用非 root 用户 `opencode` 运行容器
- 在 `compose.yaml` 中内联配置基于 `GET /global/health` 的健康检查，要求返回 `{ healthy: true, version: string }`


## Docker Compose

项目内额外提供了 `compose.yaml`，方便直接用 Compose 启动。

### 启动

```bash
docker compose up -d --build
```

### 停止

```bash
docker compose down
```

### 配置方式

`compose.yaml` 会读取当前 shell 或 `.env` 中的这些变量：

- `OPENCODE_PORT`
- `OPENCODE_HOSTNAME`
- `OPENCODE_CORS`
- `OPENCODE_MDNS`
- `OPENCODE_MDNS_DOMAIN`
- `OPENCODE_SERVER_USERNAME`
- `OPENCODE_SERVER_PASSWORD`
- `OPENCODE_CONFIG_FILE`
- `OPENCODE_CONFIG_TEMPLATE`
- `OPENCODE_PROVIDER_ID`
- `OPENCODE_PROVIDER_NPM`
- `OPENCODE_PROVIDER_NAME`
- `OPENCODE_PROVIDER_BASE_URL`
- `OPENCODE_PROVIDER_API_KEY`
- `OPENCODE_PROVIDER_AUTHORIZATION`
- `OPENCODE_MODEL_ID`
- `OPENCODE_MODEL_NAME`
- `OPENCODE_MODEL_CONTEXT`
- `OPENCODE_MODEL_OUTPUT`

例如：

```bash
export OPENCODE_SERVER_PASSWORD=your-password
export OPENCODE_CORS=http://localhost:5173,https://app.example.com
docker compose up -d --build
```

使用默认固定模板：

```bash
export OPENCODE_PROVIDER_ID=myprovider
export OPENCODE_PROVIDER_BASE_URL=https://api.myprovider.com/v1
export OPENCODE_PROVIDER_API_KEY=your-api-key
export OPENCODE_MODEL_ID=my-model-name,backup-model-name
docker compose up -d --build
```

docker build . -t xhongc/music_tag_agent