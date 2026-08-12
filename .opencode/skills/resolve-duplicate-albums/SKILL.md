---
name: resolve-duplicate-albums
description: 当用户想扫描整个音乐库中疑似重复、拆分或误分散的专辑，并通过 MCP 工具把歌曲归并到正确专辑时使用。流程必须先调用 find_similar_album_groups，再用 query_library 精查候选，最后通过 update_library dry_run 预览并在用户确认后执行修改；不确定时必须让用户确认。
---

# 处理重复/拆分专辑

## 目标

引导用户从全库扫描疑似重复专辑，到确认目标专辑，再把错误归属的歌曲移动到正确 `album_id`。音乐库展示卡片的唯一性规则是“规范化专辑名称 + 规范化专辑艺术家”；歌曲艺术家和参与艺术家不参与专辑卡片唯一性判断。这是高风险元数据修改流程，默认只读，所有写入必须先 dry-run 并获得用户明确确认。

## 可用 MCP 工具

- `find_similar_album_groups`：全库扫描疑似同一专辑被拆分成多个 `Album` 的候选组。
- `query_library`：精查专辑、歌曲、艺术家、封面附件等数据。
- `update_library`：修改字段。归并专辑时通常只修改 `track.album_id`，不要直接改专辑名或删除专辑。

## 总流程

1. 先调用 `find_similar_album_groups`，不要要求用户提供专辑 ID。
2. 向用户展示候选组摘要：专辑 ID、名称、艺术家、分数、置信度、目录、关键证据。
3. 对需要处理的候选组调用 `query_library` 精查专辑和歌曲列表。
4. 判断候选是否真的是同一张专辑；不确定时让用户选择。
5. 确定保留的目标专辑 `target_album_id` 和要移动的源专辑 `source_album_id`。
6. 调用 `update_library`，`model: "track"`，筛选 `album_id = source_album_id`，更新 `album_id = target_album_id`，必须先 `dry_run: true`。
7. 把 dry-run 预览摘要给用户确认。用户明确同意后，才用相同参数调用 `dry_run: false`。
8. 修改后用 `query_library` 复查目标专辑和源专辑下的歌曲数量。

## 扫描参数

默认先用：

```json
{
  "min_score": 0.65,
  "limit": 20,
  "include_tracks": false,
  "only_high_confidence": false,
  "refresh_cover_hashes": true
}
```

如果用户说“只看高可信”，设置 `only_high_confidence: true`。如果用户要逐组处理，先取 `limit: 10` 或 `20`，不要一次展示过多。

需要看歌曲明细时，再对具体候选组用 `query_library` 查：

```json
{
  "model": "track",
  "filters": [{"field": "album_id", "op": "in", "value": [123, 456]}],
  "order_by": ["album_id", "disc_number", "track_number", "id"],
  "fields": ["id", "name", "artist", "album_id", "album", "path", "disc_number", "track_number"],
  "limit": 500
}
```

## 判断规则

候选必须先满足：

- 两条记录的规范化 `album.name` 相同或高度相似。
- 两条记录的规范化 `album.artist` 相同。
- `track.artist` 或 `album.all_artist_names` 可以不同，它们只用于解释参与艺术家，不作为专辑卡片唯一键。

高可信通常还满足至少一项：

- `same_album_artist: true`、`cover_exact_match: true` 且 `album_name_similarity >= 0.75`
- `same_album_artist: true`、`same_directory: true` 且 `album_name_similarity >= 0.75`
- `same_album_artist: true`、`album_name_similarity >= 0.92` 且 `track_overlap >= 0.6`

中低可信必须让用户确认，尤其是：

- 只有专辑名相似，没有封面、目录或歌曲重叠证据。
- 专辑艺术家不同。除非用户明确说明要修正专辑艺术家，否则不要把它们自动归并。
- 名称像豪华版、现场版、重制版、精选集、单曲、EP、Disc 1/Disc 2。
- 歌曲列表明显不同，可能是不同版本，不要归并。

歌曲艺术家和参与艺术家只能作为辅助证据，不能因为不同就排除，也不能因为相同就自动修改专辑艺术家。`Album.artist` 是专辑卡片唯一键的一部分，必须单独比较。

## 选择目标专辑

可以建议目标专辑，但最终修改前要让用户确认。建议优先级：

1. 歌曲数量更多、曲目信息更完整的专辑。
2. 有封面、有年份、有流派、有较完整 `all_artist_names` 的专辑。
3. 目录更像正式专辑目录的专辑。
4. 用户指定的专辑。

如果两个专辑都不明显更好，询问用户保留哪个 `album_id`。

## 修改协议

归并歌曲时只改歌曲所属专辑：

```json
{
  "model": "track",
  "filters": [{"field": "album_id", "op": "eq", "value": 456}],
  "updates": {"album_id": 123},
  "limit": 500,
  "dry_run": true
}
```

用户确认后，使用完全相同的筛选和更新，把 `dry_run` 改成 `false`。

不要自动执行：

- 删除空专辑。
- 修改专辑名称。
- 修改艺术家。
- 批量跨多个候选组写入。
- 对低可信候选组写入。

如果用户要求清理空专辑，先说明当前 MCP 没有删除工具；只能用查询和可写字段处理，不要伪造删除。

## 用户确认话术

修改前给出短确认：

```text
我准备把 album_id=456 下的 12 首歌移动到 album_id=123。dry-run 显示会修改 12 条 track.album_id，不会删除专辑。请确认是否执行。
```

只有用户明确表达“确认、执行、可以、继续、按这个改”等同意后，才能调用 `dry_run: false`。

## 输出结果

完成后简要说明：

- 处理了哪个候选组。
- 实际更新了多少首歌。
- 目标专辑当前歌曲数。
- 源专辑是否已无歌曲。
- 剩余不确定候选组需要用户继续确认。

如果工具返回错误，停止写入并把错误原文摘要给用户。
