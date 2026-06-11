# FanchmWrt Online Build Action

在线编译 [FanchmWrt](https://github.com/Winter21c/fanchmwrt-for-ht2) 固件的 GitHub Action，目标设备为 **Hlink HT2 (Rockchip RK3528)**。

## 功能特性

- 从我的仓库 `Winter21c/fanchmwrt-for-ht2` 拉取源码在线编译
- 可选固件分区大小：512 MB / 1024 MB / 2048 MB / 4096 MB / 8192 MB
- 可自由选择是否开启 WiFi（Broadcom/Cypress 43455 SDIO）
- 可自定义 LAN 口 IP 地址
- 编译产物保留 30 天

## 使用方法

### 1. Fork 本仓库到你自己的 GitHub 账号

点击右上角 **Fork** 按钮。

### 2. 触发编译

1. 进入你 fork 的仓库
2. 点击 **Actions** 标签
3. 左侧选择 **Build FanchmWrt for Hlink HT2**
4. 点击 **Run workflow** 下拉按钮
5. 填写参数：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 固件分区大小 (MB) | rootfs 分区大小，越大装的软件越多 | 1024 |
| 是否开启 WiFi | 勾选开启无线功能 | ✓ 开启 |
| LAN 口 IP 地址 | 路由器管理地址 | 192.168.1.1 |
| 是否保留调试符号 | 不勾选固件更小 | ✗ 关闭 |

6. 点击 **Run workflow** 开始编译

### 3. 下载固件

编译完成后（约 2-4 小时），在 Action run 页面的 **Artifacts** 区域下载固件。固件文件为 `.img.gz` 格式。

## 目录结构

```
fanchmwrt-build-action/
├── .github/
│   └── workflows/
│       └── build-fanchmwrt.yml    # GitHub Action 工作流定义
├── scripts/
│   └── customize-config.sh       # 配置自定义脚本
└── README.md
```

## 编译流程

1. 安装编译依赖（build-essential, python3, device-tree-compiler 等）
2. 克隆 `Winter21c/fanchmwrt-for-ht2` 仓库
3. 更新并安装软件包 feeds
4. 生成基础配置（Hlink HT2 设备 + Linux 6.6 内核）
5. 应用用户自定义配置（固件大小、WiFi、IP 地址）
6. 下载所有源码包
7. 编译固件
8. 上传产物

## 注意事项

- 编译时间约 2-4 小时，请耐心等待
- GitHub Actions 免费额度有限，建议按需编译
- WiFi 依赖 `kmod-brcmfmac` + `cypress-firmware-43455-sdio` + `wpad-basic-mbedtls`
- LAN IP 修改会同时写入内核启动参数和首次启动配置
