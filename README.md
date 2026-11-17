# salescompel-lzcapp

SalesCompel（开源 Salesforce 替代，净室复刻）的懒猫微服 LPK 打包。

**上游**: https://github.com/occupysaas/salescompel （Apache-2.0）
**打包仓库**: 本仓库只存 LPK 配置与构建脚本，**不存储上游源码** —— GitHub Action 构建时按
`UPSTREAM.conf` 固定 commit 拉取上游源码，多阶段 Dockerfile（Node 24 + Go 1.25）构建应用镜像并内嵌进 LPK。

## 结构

| 文件 | 说明 |
| --- | --- |
| `UPSTREAM.conf` | 上游仓库与固定 commit（升级 = 改这里的 commit + bump `package.yml.version`） |
| `build.sh` | 构建前拉取上游源码到 `./upstream`（构建上下文） |
| `docker/Dockerfile` | 多阶段构建：web 前端 Vite 产物 + Go 服务端单二进制 |
| `lzc-build.yml` | LPK 构建配置（buildscript + embed 镜像） |
| `lzc-manifest.yml` | 应用清单：salescompel（embed 镜像）+ postgres 17 |
| `lzc-deploy-params.yml` | 安装参数：管理员账号（登录页自动填充免密） |
| `.github/lazycat-action.yml` | Action 配置：`version_source: git`，只发布喵喵商店 |

## 部署拓扑

- **salescompel**: 上游 `salescompel serve`（8080，内置 Vue UI + Salesforce 兼容 API）。
  首次启动自动执行：角色引导 SQL → `migrate up` → 建租户/管理员 → serve。
- **postgres**: `postgres:17-alpine`（数据持久化在应用数据目录；角色按上游安全模型分离）。

## 升级上游

1. 改 `UPSTREAM.conf` 里的 `UPSTREAM_COMMIT`
2. `package.yml` 的 `version` 递增（如 `0.1.1`）
3. 提交推送，Action 自动构建发布；或 `gh workflow run lazycat.yml`

## License

- 上游代码: Apache-2.0（https://github.com/occupysaas/salescompel）
- 打包配置: Apache-2.0
