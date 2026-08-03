---
name: play-music
description: 当用户要求播放、继续播放、加入队列或播放歌单中的本地歌曲时使用。先通过音乐库 MCP 查询并确认歌曲，再输出严格的 music_playback JSON 指令给前端播放器；不要输出本地路径、外部音频 URL 或未经查询确认的歌曲 ID。
---

# 播放音乐

## 目标

把“播放 xxx”“播放某位歌手的某首歌”“把这些歌加入播放队列”等请求转换为前端可执行的 JSON。前端会读取助手消息中的 JSON，并通过现有 Subsonic API 校验歌曲、补齐播放地址后调用播放器。

## 工作流

1. 从用户请求提取歌曲名、艺术家、专辑、歌单或播放动作。
2. 需要找歌时调用 `query_library`，`model` 使用 `track`；优先同时按 `name` 和 `artist` 过滤。只把查询结果中的 `id` 作为候选 ID。
3. 若有多个明显匹配，优先选择标题、艺术家、专辑都匹配的结果。无法可靠区分时不要擅自播放，返回普通文字请求用户补充信息。
4. 找到歌曲后输出一个 `music_playback` JSON 指令。不要输出 Markdown 解释、思考过程或额外 JSON。

## 输出协议

播放单曲或多首歌曲：

```json
{
  "type": "music_playback",
  "version": 1,
  "action": "play",
  "queue_mode": "replace",
  "autoplay": true,
  "tracks": [
    {"id": 123, "title": "歌曲名", "artist": "艺术家", "album": "专辑"}
  ],
  "message": "正在播放《歌曲名》"
}
```

字段约束：

- `type` 固定为 `music_playback`，`version` 固定为 `1`。
- `action` 当前只能是 `play`、`pause`、`stop`、`next`、`previous`。
- `play` 必须包含非空 `tracks` 数组；每项必须包含已查询得到的数值或数字字符串 `id`。
- `queue_mode` 只能是 `replace`、`append`、`next`。单曲播放默认使用 `replace`；“加入队列”使用 `append`；“下一首播放”使用 `next`。
- `autoplay` 仅用于 `play`，默认 `true`。暂停、停止、切歌动作不需要 `tracks`。
- `title`、`artist`、`album` 只能复制查询结果，用于界面提示，不能代替 `id`，也不能用于让前端猜歌。
- `message` 是可选的简短中文提示，不要放入 Markdown 或代码围栏。
- 不要填写 `url`、`path`、文件系统路径、认证参数或外部资源地址；播放地址由前端按歌曲 ID 从当前登录会话生成。

## 无结果和歧义

- 查询没有结果：用普通中文说明“没有找到歌曲”，不要生成 `music_playback`。
- 查询到多个同名歌曲且艺术家无法确定：用普通中文列出最多 5 个候选，让用户指定艺术家或专辑。
- 不要为了满足格式而播放相似歌曲、随机歌曲或模型记忆中的歌曲。

## 示例

用户：播放周杰伦的稻香

```json
{"type":"music_playback","version":1,"action":"play","queue_mode":"replace","autoplay":true,"tracks":[{"id":123,"title":"稻香","artist":"周杰伦","album":"魔杰座"}],"message":"正在播放《稻香》"}
```

用户：把这首歌加入队列

```json
{"type":"music_playback","version":1,"action":"play","queue_mode":"append","autoplay":false,"tracks":[{"id":123,"title":"稻香","artist":"周杰伦","album":"魔杰座"}],"message":"已加入播放队列"}
```
