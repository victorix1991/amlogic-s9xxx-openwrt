# N1 旁路网关固件（victorix1991 自用版）

基于 [ophub/amlogic-s9xxx-openwrt](https://github.com/ophub/amlogic-s9xxx-openwrt) 的 fork，只给斐讯 N1（s905d）编译，当家里的旁路网关用。上游原版说明见 ophub 仓库。

## 固件内容

| 项目 | 设置 |
|---|---|
| 源码 | ImmortalWrt master |
| 机型 | s905d（斐讯 N1） |
| 内核 | 6.12.y LTS，自动用 ophub/kernel stable 最新版 |
| 默认 IP | 10.0.0.1 |
| 用户名 / 密码 | root / 空（首次登录请自己设密码） |
| 界面 | LuCI 中文，主题 bootstrap / material |

主要软件：

- 代理：HomeProxy（sing-box 内核）、kmod-tun、nftables TProxy
- 容器：podman（编译进固件）
- 内网穿透：cloudflared + LuCI 界面
- IPTV：udpxy、msd_lite（组播转单播，默认不启用）
- 其他：晶晨宝盒（luci-app-amlogic，在线升级/写入 eMMC）、磁盘管理 diskman、ttyd 网页终端、dnsmasq-full、BBR

已去掉：fullcone NAT（上游补丁失效）、在线升级 attendedsysupgrade（不适用晶晨镜像）、UPnP（旁路网关不需要，交给主路由）、PCIe 无线网卡驱动（N1 没有 PCIe）。

## 构建

- 每周五 12:00（北京时间）自动构建，由状态页 hub 派发（GitHub 自带定时不用）。也可在 Actions 里手动运行 **Build OpenWrt system image**，参数保持默认即可。
- 产物在 Releases 的 `OpenWrt_immortalwrt_master_save_年.月`，同一个月的构建都放在这个 release 里，文件名带内核版本和日期，例如 `openwrt_immortalwrt_amlogic_s905d_k6.12.x_日期.img.gz`。
- 构建结束后会把结果上报状态页。
- 仓库 60 天没有提交，GitHub 会停掉定时相关功能，需要手动提交一次。

## 刷机与升级

- 首次：把 img.gz 写进 U 盘启动，进系统后在「系统 → 晶晨宝盒 → 安装 OpenWrt」写入 eMMC。
- 升级：晶晨宝盒里「手动上传更新」或在线更新固件。升级前先备份配置。

## 修改说明

| 文件 | 改了什么 |
|---|---|
| `config/immortalwrt_master/config` | 软件包选择（见上） |
| `config/immortalwrt_master/diy-part2.sh` | 删除 fullcone 补丁，空密码 |
| `.github/workflows/build-openwrt-system-image.yml` | 默认 IP 10.0.0.1，去掉自带定时，加结果上报 |
