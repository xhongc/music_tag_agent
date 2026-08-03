---
name: library-mcp-tools
description: Use when calling or explaining the music library MCP tools query_library and update_library, including supported models, filters, Django ORM field mappings, writable fields, safe update workflow, and few-shot examples.
---

# Library MCP Tools

用于通过 MCP 工具查询或受控修改音乐库数据。只覆盖 `query_library` 和 `update_library`。

## 工具选择

- 查数据、搜索、排序、裁剪返回字段：用 `query_library`。
- 改字段值：先用 `query_library` 精确定位，再用 `update_library` 且默认 `dry_run: true` 预览；用户明确确认后再 `dry_run: false`。
- 统计概览、听歌排行不属于本 skill，使用专用 MCP 工具。

## 通用参数

`query_library`:

```json
{
  "model": "track",
  "filters": [{"field": "name", "op": "icontains", "value": "blue"}],
  "logic": "and",
  "negate": false,
  "order_by": ["-id"],
  "limit": 20,
  "fields": ["id", "name"]
}
```

`update_library`:

```json
{
  "model": "track",
  "filters": [{"field": "id", "op": "eq", "value": 123}],
  "logic": "and",
  "negate": false,
  "updates": {"comment": "已校对"},
  "limit": 1,
  "dry_run": true
}
```

支持的过滤操作符：`eq`, `ne`, `contains`, `icontains`, `startswith`, `istartswith`, `endswith`, `iendswith`, `in`, `gt`, `gte`, `lt`, `lte`, `isnull`。

规则：

- `filters` 最多 20 个条件；每个条件格式为 `{field, op, value}`。
- 支持嵌套过滤组：`{logic: "or", negate: false, filters: [...]}`。
- `logic` 只支持 `and` / `or`。
- `in` 的 `value` 必须是数组，内部最多取前 100 个值。
- `isnull` 的 `value` 会转成布尔值。
- `order_by` 使用公开字段名，降序加 `-`，最多 5 个字段。
- `fields` 只裁剪返回字段，不影响筛选。
- `query_library` 工具入口把 `limit` 限制在 1-500；服务层查询上限也是 500。
- `update_library` 必须提供非空 `filters` 和非空 `updates`；`limit` 最小为 1、默认 1，不设置最大值，不要无筛选批量改。

## 查询模型与字段

下面是公开字段到 Django ORM 字段的映射。调用工具时使用左侧公开字段。

### track -> `applications.music.models.Track`

查询上限：500。默认排序：`-id`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `artist` | `artist__name` |
| `artist_id` | `artist_id` |
| `album` | `album__name` |
| `album_id` | `album_id` |
| `genre` | `genre__name` |
| `genre_id` | `genre_id` |
| `path` | `path` |
| `year` | `year` |
| `duration` | `duration` |
| `track_number` | `track_number` |
| `disc_number` | `disc_number` |
| `plays_count` | `plays_count` |
| `lyrics` | `lyrics` |
| `comment` | `comment` |
| `label` | `label` |
| `language` | `language` |
| `has_cover_art` | `has_cover_art` |
| `created_at` | `created_at` |
| `updated_at` | `updated_at` |

可更新字段：`name`, `artist_id`, `album_id`, `genre_id`, `year`, `duration`, `track_number`, `disc_number`, `plays_count`, `lyrics`, `comment`, `label`, `language`, `has_cover_art`。

### album -> `applications.music.models.Album`

查询上限：500。默认排序：`-id`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `artist` | `artist__name` |
| `artist_id` | `artist_id` |
| `genre` | `genre__name` |
| `genre_id` | `genre_id` |
| `song_count` | `song_count` |
| `plays_count` | `plays_count` |
| `duration` | `duration` |
| `max_year` | `max_year` |
| `comment` | `comment` |
| `description` | `description` |
| `all_artist_names` | `all_artist_names` |
| `paths` | `paths` |
| `created_at` | `created_at` |

可更新字段：`name`, `artist_id`, `genre_id`, `song_count`, `plays_count`, `duration`, `max_year`, `comment`, `description`, `all_artist_names`, `paths`。

### artist -> `applications.music.models.Artist`

查询上限：500。默认排序：`-id`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `album_count` | `album_count` |
| `song_count` | `song_count` |
| `size` | `size` |
| `description` | `description` |
| `similar_artists` | `similar_artists` |
| `external_url` | `external_url` |
| `created_at` | `created_at` |
| `has_fetch_cover` | `has_fetch_cover` |

可更新字段：`name`, `album_count`, `song_count`, `description`, `similar_artists`, `external_url`, `has_fetch_cover`。

### playlist -> `applications.music.models.Playlist`

查询上限：500。默认排序：`-id`。`track_count` 只可作为返回字段，不能用于过滤或排序。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `user` | `user__username` |
| `description` | `description` |
| `privacy_level` | `privacy_level` |
| `is_dynamic` | `is_dynamic` |
| `dynamic_count` | `dynamic_count` |
| `condition_dict` | `condition_dict` |
| `created_at` | `creation_date` |
| `updated_at` | `modification_date` |

返回字段还支持：`track_count`。

可更新字段：`name`, `description`, `privacy_level`, `is_dynamic`, `dynamic_count`, `condition_dict`。`condition_dict` 可传 JSON 对象、数组或合法 JSON 字符串。

### playlist_track -> `applications.music.models.PlaylistTrack`

查询上限：500。默认排序：`index`, `id`。返回字段中的 `track` 是嵌套歌曲对象；但 `fields` 裁剪只允许顶层字段。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `playlist_id` | `playlist_id` |
| `playlist` | `playlist__name` |
| `track_id` | `track_id` |
| `track` | `track__name` |
| `artist` | `track__artist__name` |
| `album` | `track__album__name` |
| `index` | `index` |
| `created_at` | `creation_date` |

返回字段只支持：`id`, `playlist_id`, `playlist`, `track_id`, `track`, `index`, `created_at`。

可更新字段：`playlist_id`, `track_id`, `index`。

### folder -> `applications.music.models.Folder`

仅支持查询，不支持 `update_library`。查询上限：500。默认排序：`-updated_at`, `-id`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `path` | `path` |
| `parent_path` | `parent_path` |
| `file_type` | `file_type` |
| `state` | `state` |
| `created_at` | `created_at` |
| `updated_at` | `updated_at` |

### genre -> `applications.music.models.Genre`

查询上限：500。默认排序：`name`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `name` | `name` |
| `attachment_cover_id` | `attachment_cover_id` |

可更新字段：`name`, `attachment_cover_id`。

### attachment -> `applications.music.models.Attachment`

查询上限：500。默认排序：`-id`。

| 公开字段 | Django ORM 字段 |
|---|---|
| `id` | `id` |
| `url` | `url` |
| `file` | `file` |
| `size` | `size` |
| `mimetype` | `mimetype` |
| `width` | `width` |
| `height` | `height` |
| `memo` | `memo` |
| `created_at` | `creation_date` |
| `last_fetch_date` | `last_fetch_date` |

可更新字段：`url`, `size`, `mimetype`, `width`, `height`, `memo`。

## Few-Shot

### 1. 搜索歌曲并只返回必要字段

用户：查一下歌名包含 love 的歌曲，按播放量倒序，给我 10 条。

调用：

```json
{
  "name": "query_library",
  "arguments": {
    "model": "track",
    "filters": [{"field": "name", "op": "icontains", "value": "love"}],
    "order_by": ["-plays_count"],
    "limit": 10,
    "fields": ["id", "name", "artist", "album", "plays_count"]
  }
}
```

### 2. 查找某艺术家的专辑

用户：列出 周杰伦 的专辑，按年份新到旧。

调用：

```json
{
  "name": "query_library",
  "arguments": {
    "model": "album",
    "filters": [{"field": "artist", "op": "icontains", "value": "周杰伦"}],
    "order_by": ["-max_year", "name"],
    "limit": 50,
    "fields": ["id", "name", "artist", "max_year", "song_count"]
  }
}
```

### 3. 用嵌套 OR 查缺失元数据歌曲

用户：找出歌手或专辑未知、并且还没有歌词的歌曲。

调用：

```json
{
  "name": "query_library",
  "arguments": {
    "model": "track",
    "filters": [
      {
        "logic": "or",
        "filters": [
          {"field": "artist", "op": "eq", "value": "未知艺术家"},
          {"field": "album", "op": "eq", "value": "未知专辑"}
        ]
      },
      {
        "logic": "or",
        "filters": [
          {"field": "lyrics", "op": "isnull", "value": true},
          {"field": "lyrics", "op": "eq", "value": ""}
        ]
      }
    ],
    "logic": "and",
    "limit": 20,
    "fields": ["id", "name", "artist", "album", "lyrics"]
  }
}
```

### 4. 修改歌曲备注，先 dry run

用户：把 id=123 的歌曲备注改成 已校对。

第一次调用：

```json
{
  "name": "update_library",
  "arguments": {
    "model": "track",
    "filters": [{"field": "id", "op": "eq", "value": 123}],
    "updates": {"comment": "已校对"},
    "limit": 1,
    "dry_run": true
  }
}
```

用户确认后第二次调用：

```json
{
  "name": "update_library",
  "arguments": {
    "model": "track",
    "filters": [{"field": "id", "op": "eq", "value": 123}],
    "updates": {"comment": "已校对"},
    "limit": 1,
    "dry_run": false
  }
}
```

### 5. 更新动态歌单条件

用户：把歌单 8 改成动态歌单，条件是播放次数大于 10，最多 100 首。

先 dry run：

```json
{
  "name": "update_library",
  "arguments": {
    "model": "playlist",
    "filters": [{"field": "id", "op": "eq", "value": 8}],
    "updates": {
      "is_dynamic": true,
      "dynamic_count": 100,
      "condition_dict": {
        "filters": [{"field": "plays_count", "op": "gt", "value": 10}],
        "order_by": ["-plays_count"]
      }
    },
    "limit": 1,
    "dry_run": true
  }
}
```

### 6. 调整歌单歌曲顺序

用户：把歌单 8 里歌曲 123 的序号改为 0。

先定位：

```json
{
  "name": "query_library",
  "arguments": {
    "model": "playlist_track",
    "filters": [
      {"field": "playlist_id", "op": "eq", "value": 8},
      {"field": "track_id", "op": "eq", "value": 123}
    ],
    "limit": 5,
    "fields": ["id", "playlist_id", "track_id", "index"]
  }
}
```

再 dry run 修改：

```json
{
  "name": "update_library",
  "arguments": {
    "model": "playlist_track",
    "filters": [
      {"field": "playlist_id", "op": "eq", "value": 8},
      {"field": "track_id", "op": "eq", "value": 123}
    ],
    "updates": {"index": 0},
    "limit": 1,
    "dry_run": true
  }
}
```

## 常见坑

- `folder` 不能更新。
- `track_count` 不能过滤或排序，因为它不是 `playlist` 的查询字段，只是 presenter 返回值。
- `playlist_track.fields` 不能写 `artist` / `album`，虽然它们可用于过滤和排序。
- `created_at` / `updated_at` 在部分模型上映射到真实字段 `creation_date` / `modification_date`。
- 更新外键时使用 `artist_id`, `album_id`, `genre_id`, `playlist_id`, `track_id`, `attachment_cover_id`，不要传对象。
- 批量更新前报告 `total_matched` 和 `limit`，确认只会修改预期范围。
