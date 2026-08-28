# Omarchy Proton Mail 通知插件

[English](README.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Italiano](README.it.md) | **中文**

一个 [Omarchy](https://omarchy.org) shell 插件，在状态栏中（右上角、系统托盘旁）显示你的 **Proton Mail 未读邮件数**，点击时下拉展示**最近的邮件列表**，并在有新邮件到达时弹出桌面通知。

无需浏览器扩展，也无需 Proton Mail Bridge —— 支持**免费和付费 Proton 账户**，以及任何基于 Chromium 的浏览器（Brave、Chrome、Chromium、Edge）。

小部件支持 **English、Español、Français、Deutsch、Italiano 和中文**（默认为 English），并且一切都可以配置 —— 轮询间隔、下拉列表大小、标题昵称、通知、语言 —— 均可通过 `omarchy bar set` 即时生效。

## 截图

![最近邮件下拉列表](screenshots/dropdown.jpg)

![状态栏中的小部件提示](screenshots/widget-tooltip.jpg)

## 工作原理

```
Proton Mail webapp (dedicated browser profile, --app window)
title: "(3) Inbox | … | Proton Mail"
        │
        ├─ hyprctl clients -j ──► omarchy-protonmail-unread ──► badge 󰇮 N + notification
        │   (window titles)          (every intervalSec)
        │
        └─ --remote-debugging-pipe ──► omarchy-protonmail-broker ──► 最近 N 封邮件下拉 +
            (CDP 通过继承的 fd 3/4，               (唯一的 CDP 客户端，        外部链接在默认浏览器
             完全没有 TCP 调试端口)                  unix socket API + 扫描)   中打开
```

- **未读数量**：Proton Mail 会把它以 `(N)` 的形式放进页面标题，而
  Hyprland 通过 `hyprctl clients -j` 暴露窗口标题。无论是 webapp 窗口
  *还是*任何显示 Proton Mail 的普通浏览器标签页都可以工作。
- **最近邮件**：webapp 通过 `omarchy-protonmail-broker` 以
  `--remote-debugging-pipe` 启动，浏览器通过从 broker 继承的文件描述符
  进行 CDP 通信 —— 没有任何 TCP 调试端口（固定或随机都没有）可供其他
  进程连接。broker 通过 unix socket（SO_PEERCRED 认证）向
  `omarchy-protonmail-recent` 提供截断后的收件箱行 —— 只使用 Python
  标准库，无需安装其他任何东西。
- **外部链接**：broker 还会扫描标签页列表，把主机不在 Proton 精确
  允许列表中的标签页在默认浏览器（你的主配置，带有 cookie 和登录
  会话）中打开，并在 webapp 中将其关闭。

## 安装

```bash
git clone https://github.com/686f6c61/Omarchy-Proton-Mail.git
cd Omarchy-Proton-Mail
./install.sh
```

安装程序会：

1. 下载 Proton 图标，并创建一个 **"Proton Mail" webapp** 启动器
   （`omarchy webapp install`），使用独立配置 + CDP 端口。
2. 将 `omarchy-protonmail-unread` 和 `omarchy-protonmail-recent` 安装到
   `~/.local/share/omarchy-protonmail/`。
3. 将 shell 插件安装到 `~/.config/omarchy/plugins/686f6c61.proton-mail/`。
4. 在状态栏的**右侧区域**启用小部件（先备份
   `~/.config/omarchy/shell.json`），然后重启 shell。
5. 询问你的**语言**和可选的**昵称**（交互式）。非交互式替代方式：
   `./install.sh --language es --nickname "My mail"`

然后从应用启动器（SUPER + SPACE）启动 **Proton Mail** 并登录。
独立配置意味着你只需登录一次，且与主浏览器互不影响。

## 使用方法

- **左键点击小部件**：下拉显示最近 N 封邮件（发件人、主题、时间；
  未读邮件加粗显示）。点击某封邮件即可跳转到 Proton Mail 窗口 —— 会聚焦
  已有的窗口，绝不重复打开。
- 下拉列表顶部显示 Proton Mail 标志，底部有一个**暂停通知**开关，
  可实时切换 `notify` 设置。
- 在邮件中点击的链接会在你的**默认浏览器**（主配置）中打开，而不是
  webapp 的独立配置。
- 当 `recentCount: "0"` 时，下拉列表被禁用，左键点击仅聚焦
  Proton Mail 窗口（纯通知模式）。
- **右键/中键点击**：立即刷新。
- 点击通知也会打开/聚焦 Proton Mail。

小部件状态（启用期间始终可见）：

| 状态                 | 含义                           |
|----------------------|--------------------------------|
| 󰇯 暗淡               | Proton Mail 窗口未打开         |
| 󰇯 正常               | 已打开，无未读邮件             |
| 󰇮 N（强调色）        | N 封未读 —— 已发出通知         |
| 󰇮 99+（强调色）      | 超过 99 封未读                 |

## 设置

最快的方式是使用 `omarchy bar set` 命令（即时生效，无需重启）：

```bash
omarchy bar set 686f6c61.proton-mail recentCount 7
omarchy bar set 686f6c61.proton-mail nickname "My mail"
omarchy bar set 686f6c61.proton-mail language es
omarchy bar set 686f6c61.proton-mail intervalSec 10
omarchy bar set 686f6c61.proton-mail notify false
```

你也可以直接在 `~/.config/omarchy/shell.json` 中内联编辑小部件条目：

```json
{ "id": "686f6c61.proton-mail", "intervalSec": 5, "recentCount": "5", "notify": true, "nickname": "", "language": "en" }
```

- `intervalSec`（2–60，默认 5）：未读数量的轮询间隔。
- `recentCount`（0–20，默认 5）：下拉列表中显示的邮件数。`0`
  会禁用下拉列表（仅通知）。
- `notify`（默认 true）：未读数量增加时发送桌面通知。
- `nickname`（默认为空）：当没有未读邮件时下拉列表标题的自定义文本。
  留空则显示默认的 "All caught up"。
- `language`（`en`/`es`/`fr`/`de`/`it`/`zh`，默认 `en`）：小部件、
  下拉列表和通知的语言（English、Español、Français、Deutsch、
  Italiano、中文）。

## 故障排除

- **安装后小部件未出现**：运行 `omarchy restart shell`（QML 加载器会
  缓存针对插件 URL 的失败记录；重启 shell 可以清除它们）。
- **开发时小部件不响应 QML 修改**：同样的原因 —— inotify 热重载可能
  一直在为该插件 URL 提供缓存的字节码。编辑插件文件后运行
  `omarchy restart shell`。
- **下拉列表显示登录行**：请在 "Proton Mail" webapp 窗口内登录（独立
  配置拥有自己的会话）。
- **已登录但下拉列表为空**：提取逻辑可能需要针对你的 Proton 版本进行
  调整 —— 运行
  `~/.local/share/omarchy-protonmail/omarchy-protonmail-recent --dump`
  并附上输出提交 issue。
- 未读角标依赖于 Proton Mail 的 `(N)` 页面标题格式；匹配逻辑位于
  `bin/omarchy-protonmail-unread`。

## 卸载

```bash
omarchy webapp remove "Proton Mail"
rm -rf ~/.config/omarchy/plugins/686f6c61.proton-mail ~/.local/share/omarchy-protonmail
# then remove the { "id": "686f6c61.proton-mail" } entry from ~/.config/omarchy/shell.json
# (or restore the shell.json.bak.<timestamp> backup created by install.sh)
omarchy restart shell
```

## 许可证

[MIT](LICENSE) © 686f6c61 <github@00b.tech>
