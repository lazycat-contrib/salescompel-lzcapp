# syntax=docker/dockerfile:1
# SalesCompel 应用镜像：多阶段构建（web 前端 Vite 产物 + Go 后端单二进制）。
# 构建上下文 = 打包仓库根（build.sh 已按 UPSTREAM.conf 固定 commit 把上游源码放到 ./upstream）。

# ---- 阶段 1：构建 Vue 前端（上游要求 Node >= 22.12）----
# 注意：web/src/i18n.ts 通过 ../../locales/languages.json 引用仓库根的 locales/，
# 因此需把 upstream/locales/ 一并放到 /src/locales/。
FROM node:24-alpine AS webbuild
WORKDIR /src/web
COPY upstream/web/package.json upstream/web/package-lock.json ./
RUN npm ci --ignore-scripts
COPY upstream/web/ ./
COPY upstream/locales/ /src/locales/
# vite build 输出到 /src/web/dist
RUN npm run build

# ---- 阶段 2：构建 Go 服务端（上游 go.mod 要求 1.25）----
FROM golang:1.25-alpine AS gobuild
WORKDIR /src
ENV CGO_ENABLED=0 GOFLAGS=-trimpath
COPY upstream/go.mod upstream/go.sum ./
RUN go mod download
COPY upstream/cmd/ cmd/
COPY upstream/internal/ internal/
COPY upstream/api/ api/
COPY upstream/locales/ locales/
RUN go build -o /out/salescompel ./cmd/salescompel

# ---- 阶段 3：运行镜像 ----
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates tzdata \
    && rm -rf /var/lib/apt/lists/*
COPY --from=gobuild /out/salescompel /usr/local/bin/salescompel
COPY --from=webbuild /src/web/dist /opt/salescompel/web-dist
# migrate/provision 均为同一二进制子命令；locales/api 契约已 go:embed 进二进制。
WORKDIR /opt/salescompel
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/salescompel"]
CMD ["serve", "-addr", "0.0.0.0:8080", "-assets", "/opt/salescompel/web-dist"]
