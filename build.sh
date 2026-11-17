#!/bin/bash
# 拉取上游源码（按 UPSTREAM.conf 固定 commit）到 ./upstream 作为 Docker 构建上下文。
# 上游源码不入库（.gitignore 忽略 upstream/）。CI 与本机均可用：
# - 有网络: git clone + checkout 固定 commit（校验工作区干净）
# - 无网络/受限环境: 接受预先放置好的源码目录，但必须含内容一致的 stamp 校验文件
set -euo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./UPSTREAM.conf

stamp_expected="repo=$UPSTREAM_REPO
commit=$UPSTREAM_COMMIT"

mkdir -p upstream
if [ -f upstream/.upstream-stamp ] && [ "$(cat upstream/.upstream-stamp)" = "$stamp_expected" ]; then
    echo "upstream source present, stamp matches $UPSTREAM_COMMIT"
    exit 0
fi

if [ ! -d upstream/.git ]; then
    git clone --quiet "$UPSTREAM_REPO" upstream
fi
current="$(git -C upstream rev-parse HEAD)"
if [ "$current" != "$UPSTREAM_COMMIT" ]; then
    echo "fetching pinned upstream commit $UPSTREAM_COMMIT"
    git -C upstream fetch --quiet origin "$UPSTREAM_COMMIT"
    git -C upstream checkout --quiet --detach "$UPSTREAM_COMMIT"
fi
# 干净工作区校验（防止残留本地改动混进镜像）
test -z "$(git -C upstream status --porcelain)"
printf '%s\n' "$stamp_expected" > upstream/.upstream-stamp
echo "upstream pinned at $UPSTREAM_COMMIT ($(git -C upstream log -1 --format=%cs))"
