# ASUS ROG Strix G713PV — macOS 26 Hackintosh EFI

> 机型：ASUS ROG Strix G713PV（2023，17.3 英寸）
> 系统：macOS 26.7.3（25G342）
> OpenCore：DBG-109（2026-10-10 构建）
> SMBIOS：MacBookPro16,2
> 状态：日常可用（iMessage 除外，见「已知问题」）

这是一份在本机实测可用的 OpenCore EFI，包含配置、kext、ACPI 与说明文档。**发布版已移除所有个人身份字段**，请按「安装步骤」生成你自己的 SMBIOS 后再使用。

---

## ⚠️ 使用前必读

1. **SMBIOS 已脱敏**。`EFI/OC/config.plist → PlatformInfo → Generic` 中：
   - `SystemSerialNumber` = `000000000000`
   - `MLB` = `00000000000000000`
   - `ROM` = `112233445566`
   - `SystemUUID` = `00000000-0000-0000-0000-000000000000`

   直接使用这套值开机可以进系统，但 **App Store / iCloud / iMessage 全部不可用**，必须换成你自己的。
2. **显卡驱动不在 EFI 里**。NVIDIA RTX 4060 在 macOS 下依靠 NullMoth 的 NVRM 驱动栈（装在 `/Library/Extensions`），需要单独安装，见下文。
3. **仅适合同平台机器**（G713PV / 7845HX / RTX 4060 / MT7922）。其他 Ryzen 笔记本可以参考思路，但 kext 与 ACPI 不能直接照搬。

---

## 硬件配置

| 部件 | 型号 | macOS 下的状态 |
| --- | --- | --- |
| CPU | AMD Ryzen 9 7845HX（12C/24T，Zen 4） | ✅ 24 线程可用，`revpatch=cpuname` 显示为 Ryzen 9 7845HX |
| 独显 | NVIDIA GeForce RTX 4060 Laptop 8GB（`0x10de:0x28e0`） | ✅ Metal 4，需 NullMoth NVRM 3.1 |
| 核显 | AMD Radeon 610M（Raphael，`0x1002:0x164e`） | ⛔ 未加载驱动（BIOS 中关闭） |
| 内屏 | BOE NE173QHM-NZ2，17.3" 2560×1440 240Hz（eDP） | ✅ 240Hz 可用，HiDPI 见「可选增强」 |
| 内存 | 16 GB DDR5 | ✅ |
| 硬盘 | WD PC SN560 1TB NVMe | ✅ |
| 无线网卡 | MediaTek MT7922（`0x14c3:0xe0df`） | ✅ AirportMtkWlan 1.0.9 |
| 蓝牙 | MT7922（同一模块） | ✅ |
| 有线网卡 | Realtek RTL8111 | ✅ en0，BuiltIn = true |
| 声卡 | Realtek ALC294 + 2 × Cirrus CS35L41 智能功放 | ✅ layout-id 13 |
| 电池 | 内置锂电池 | ✅ SMCBatteryManager |
| 键盘 / 触控板 | I2C HID | ✅ VoodooI2C / VoodooPS2 |
| 摄像头 | USB2.0 HD UVC WebCam | ⚠️ 未测试 |

---

## 功能状态

| 功能 | 状态 | 说明 |
| --- | --- | --- |
| 图形加速（Metal 4） | ✅ | NullMoth NVRM 3.1 + NVAccel |
| 内屏 2560×1440@240Hz | ✅ | 原生时序 |
| HiDPI 缩放 | ⚠️ | 需要额外的 Display Override 文件，见 [`extras/display-override`](extras/display-override) |
| 内置扬声器 | ✅ | CS35L41 双功放，采样率需 48 kHz |
| 3.5mm 耳机 | ✅ | |
| HDMI / DP 音频 | ✅ | NMHDA |
| Wi-Fi | ✅ | 802.11ax |
| 蓝牙 | ✅ | |
| 有线网络 | ✅ | |
| 电池电量 / 充电 | ✅ | |
| 亮度调节 | ✅ | `nvrmacpibl=1` |
| 键盘 / 触控板 | ✅ | 触控板走 VoodooI2CHID |
| 风扇转速读取 | ✅ | SMCAsusFan |
| 风扇曲线控制 | ❌ | 未实现（SSDT 写 EC 会导致卡死，已停用） |
| NVIDIA 温度 / 功耗传感器 | ✅ | SMCNvidiaGPU 2.3 |
| Apple ID / iCloud 云盘 | ✅ | 登录正常 |
| iCloud 照片 | ⚠️ | 需先把照片图库放到系统默认路径，见「已知问题」 |
| App Store | ✅ | |
| iMessage / FaceTime | ❌ | 目前 IDS 注册失败，未解决 |
| 隔空投送（AirDrop） | ⚠️ | 系统显示支持，未实测 |
| 通用剪贴板 / Handoff | ⚠️ | 未实测 |
| 睡眠 / 唤醒 | ⚠️ | 未充分测试 |
| 桌面动态壁纸 | ❌ | WindowServer 背景层无视频合成通路（锁屏可播） |
| 雷电 / USB4 | ⚠️ | 未测试 |

---

## 驱动清单（EFI/OC/Kexts）

| Kext | 版本 | 作用 | 上游 |
| --- | --- | --- | --- |
| Lilu | 1.7.3 | 内核补丁基础框架 | acidanthera |
| VirtualSMC | 1.3.9 | SMC 模拟 | acidanthera |
| SMCBatteryManager | 1.3.9 | 电池状态 | acidanthera (VirtualSMC 插件) |
| SMCLightSensor | 1.3.9 | 环境光传感器 | acidanthera (VirtualSMC 插件) |
| AMDRyzenCPUPowerManagement | 0.7.2 | Ryzen CPU 电源管理 | trulyspinach |
| SMCAMDProcessor | 1 | Ryzen 频率/温度传感器 | trulyspinach |
| ForgedInvariant | 1.5.0 | AMD CPU 特性修补 | ChefKiss |
| AMFIPass | 1.4.1 | AMFI 放行，允许未签名 kext | dhinakg |
| AppleALC | 1.9.9 | 声卡 AppleHDA 补丁 | acidanthera |
| SimpleHDA | 1.0.0 | HDA 辅助补丁 | laobamac |
| NMHDA | 1.0.0 | NVIDIA HDMI/DP 音频 | NullMoth |
| CirrusAudioFixup | 1.2.1 | CS35L41 功放支持（`1043:1D1F`） | hoaug-tran |
| AppleMCEReporterDisabler | 1.2 | 关闭 MCE Reporter，避免 AMD panic | xlnc |
| RealtekRTL8111 | 2.4.2 | 有线网卡 | Mieze |
| MtkWirelessWifi | 1.0.9 | MT7922 Wi-Fi（AirportMtkWlan） | dinovn |
| MtkWirelessBT | 1.0.9 | MT7922 蓝牙 | dinovn |
| BlueToolFixup | 2.7.2 | 蓝牙协议修补 | acidanthera (BrcmPatchRAM) |
| RestrictEvents | 1.1.7 | CPU 名称/内存/PCI 修补（`revpatch`） | acidanthera |
| USBToolBox + UTBMap | 1.2.0 / 1.1 | USB 端口映射 | dhinakg / USBToolBox |
| VoodooI2C + VoodooI2CServices / VoodooGPIO / VoodooInput / VoodooI2CHID | 2.9.1 / 1 | I2C 触控板与 HID | alexandred（本机用含 `VoodooI2CTransferToAddress` 的 main 分支构建） |
| VoodooPS2Controller | 2.3.8 | 内置键盘（PS2 通道） | acidanthera |
| SMCAsusFan | 1.0.0 | ASUS 风扇 SMC 键（F0Ac/F1Ac） | 社区 |
| AsusWmi | 0.2.2 | ASUS WMI 接口，供 ROG Control 使用 | itlmt7925（GeekAudio 分支） |
| SMCNvidiaGPU | 2.3 | NVIDIA GPU 传感器（温度/功耗/频率） | zzzyy678 |
| AsusFanControl | 1.4.2 | ❌ **已禁用**（本机不工作且屏蔽 SMC 风扇键） | hieplpvip |

### 不在 EFI 内的驱动

NVIDIA 显卡驱动栈由 NullMoth 的 1401 安装器写入 `/Library/Extensions`：

```
NVRM.kext 3.1 / NVAccel.kext 3.1 / NVRMFB.kext 3.1 / NVRMAGDC.kext 3.1 / NMXAudio.kext / NMHDA.kext
```

它们不随 EFI 分发，请从 NullMoth / 1401 项目获取对应版本（**3.1**），版本不匹配会黑屏。

---

## ACPI（EFI/OC/ACPI）

| 文件 | 作用 |
| --- | --- |
| SSDT-EC.aml | 补 EC 设备 |
| SSDT-PLUG-ALT.aml | CPU 电源管理（plugin-type） |
| SSDT-USBX.aml | USB 供电属性 |
| SSDT-XOSI.aml | `_OSI` 伪装为 Windows |
| SSDT-ADP0.aml | 电源适配器 |
| SSDT-ALIBFix.aml | 音频相关修复 |
| SSDT-USB-Reset.aml | ❌ 未启用 |
| SSDT-FANCFG.aml | ❌ 未启用（写 EC 会在交棒后卡死） |
| SSDT-Disable_Network_GPP3.aml | ❌ 未启用 |

---

## OpenCore 主要设置

| 项目 | 值 |
| --- | --- |
| OpenCore | DBG-109（2026-10-10） |
| Drivers | HfsPlus, OpenRuntime, OpenCanopy, ResetNvramEntry |
| Picker | External + `Acidanthera\GoldenGate`，超时 600 秒 |
| SecureBootModel | Disabled |
| Kernel Quirks | `CustomSMBIOSGuid`, `DisableIoMapper`, `DisableLinkeditJettison`, `PowerTimeoutKernelPanic`, `ProvideCurrentCpuInfo`, `SetApfsTrimTimeout=-1` |
| Booter Quirks | `AvoidRuntimeDefrag`, `DevirtualiseMmio`, `DisableVariableWrite`, `EnableSafeModeSlide`, `FixupAppleEfiImages`, `ProtectUefiServices`, `ProvideCustomSlide`, `RebuildAppleMemoryMap`, `SetupVirtualMap`, `SyncRuntimePermissions`, `AllowRelocationBlock` |
| UEFI Quirks | `EnableVectorAcceleration`, `ReleaseUsbOwnership`, `RequestBootVarRouting`, `ResizeGpuBars=-1` |

### boot-args

```
-v debug=0x100 keepsyms=1
-vi2c-force-polling
revpatch=sbvmm,cpuname,pci
amfi_get_out_of_my_way=0x1 amfi=0x80
ipc_control_port_options=0
gfxrst=4 nvrmacpibl=1
pci_log=0x201 pci_log_mode=0x6 -FIDebug revblock=pci
nvfb=1 nvaccel=1 nvfbheads=4 -nvkmsnosmooth -smbtrandaddr
alcid=13 -cirrusdbg
nvfbhidpi=1 nvfbdsr=1
```

| 参数 | 作用 |
| --- | --- |
| `-v debug=0x100 keepsyms=1` | 详细启动日志（可在稳定后去掉 `-v`） |
| `-vi2c-force-polling` | VoodooI2C 强制轮询（避免中断丢失） |
| `revpatch=sbvmm,cpuname,pci` | RestrictEvents：内存、CPU 名称、PCI 修补 |
| `amfi_get_out_of_my_way=0x1 amfi=0x80` | 关闭 AMFI 校验，加载未签名 kext |
| `gfxrst=4` | NullMoth：GPU 复位策略 |
| `nvrmacpibl=1` | NullMoth：ACPI 背光 |
| `nvfb=1 nvaccel=1 nvfbheads=4` | 启用 framebuffer / 加速器 / 4 个显示头 |
| `-nvkmsnosmooth` | 关闭 NVKMS 的 vblank 接管 |
| `alcid=13` | AppleALC layout 13 |
| `nvfbhidpi=1 nvfbdsr=1` | 允许缩放桌面背板（HiDPI 前提） |

---

## BIOS 设置

按 1401 项目的验证配置，本机 BIOS 关键项：

- **Above 4G Decoding = Enabled**
- **Resizable BAR / Re-Size BAR Support = Enabled**
- **CSM / Legacy Boot = Disabled**
- **Secure Boot = Disabled**
- **Fast Boot = Disabled**
- **SATA = AHCI**
- **核显（Radeon 610M）= Disabled**（macOS 下不驱动，避免 PCI 枚举卡住）
- 指纹、读卡器等无关设备可保持默认

> BIOS 版本不同，选项名称略有差异。改完先只改一项、重启验证，出问题好回退。

---

## 安装步骤

### 1. 备份

先用 1401 或 `diskutil` 备份你现有的 EFI（内置 ESP 与 U 盘各一份）。

### 2. 生成你自己的 SMBIOS

用 [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS)：

```
机型选择：MacBookPro16,2
生成：Serial + MLB
```

然后写入 `EFI/OC/config.plist → PlatformInfo → Generic`：

- `SystemSerialNumber` = 生成的 Serial
- `MLB` = 生成的 Board Serial
- `SystemProductName` = `MacBookPro16,2`

### 3. 设置 ROM

`ROM` 必须是**本机 en0 的 MAC 地址**（6 字节）。查本机：

```bash
ifconfig en0 | awk '/ether/{print $2}'   # 例：a0:b1:c2:d3:e4:f5
```

在 config.plist 里把 `ROM` 改成对应 6 字节（十六进制），例如 `a0b1c2d3e4f5`。

### 4. 生成 SystemUUID

```bash
uuidgen
```

填入 `PlatformInfo → Generic → SystemUUID`。

### 5. 写入 EFI

把整个 `EFI/` 目录放到 ESP 的根目录（`/Volumes/EFI/EFI/OC` 等），保留 `Boot/BOOTx64.efi`。

### 6. 安装显卡驱动

用 NullMoth / 1401 安装器安装 **NVRM 3.1** 驱动栈到 `/Library/Extensions`，否则会停在黑屏或只有鼠标。

### 7. 重启

首次启动建议保留 `-v`，确认无报错后再去掉。

---

## 可选增强

### HiDPI 缩放

`extras/display-override/DisplayProductID-b69` 是本机面板（BOE NE173QHM-NZ2）的 Display Override，包含 1920×1080、1600×900、1440×810 等缩放档位。

安装：

```bash
sudo mkdir -p /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5
sudo cp DisplayProductID-b69 /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-9e5/
sudo chown root:wheel /Library/Displays/.../DisplayProductID-b69
sudo chmod 644 /Library/Displays/.../DisplayProductID-b69
```

重启后在「显示器」或 BetterDisplay 中切换。注意：非整数缩放的档位（如 1.5:1）会有轻微锯齿，这是面板 2560 宽 + 硬件缩放的固有限制。

### 屏幕常亮

若遇到锁屏时显示器反复「熄 1 秒又亮」的循环（由 HID 设备唤醒引起），可用 caffeinate 阻止熄屏：

```bash
# ~/Library/LaunchAgents/com.tao.keepdisplayawake.plist 中运行 /usr/bin/caffeinate -d -i
```

---

## 已知问题

1. **iMessage / FaceTime 无法登录**
   Apple ID 本身可正常登录，但 IDS 注册在证书请求阶段失败（`FTMessageDeliveryNoResultCodeError`），账号随即被禁用（`Decomposing registration`）。ROM 已修正为 en0 MAC，仍未解决，可能与序列号/MLB 组合或 Apple 的注册风控有关。

2. **iCloud 照片无法开启**
   macOS 的系统照片图库默认路径是 `~/Pictures/Photos Library.photoslibrary`。如果图库建在其他位置（例如家目录），iCloud 照片开关会读不到 CPL 设置。解决办法：把图库移到默认路径，或在 `~/Pictures` 下做符号链接。

3. **桌面动态壁纸不播放**
   WindowServer 的背景层在这套 NVIDIA 驱动上没有视频合成通路；锁屏可以播放，桌面不行。换编码/改覆盖都无效。

4. **风扇曲线控制未实现**
   `SSDT-FANCFG` 尝试在 `_INI` 写 EC 会导致交棒后卡死，已停用。目前只能读转速（SMCAsusFan）、用 ROG Control 切换性能模式（AsusWmi）。

5. **开机带 `-v` 详细模式**
   稳定后可自行删掉 `-v debug=0x100 keepsyms=1`。

6. **睡眠/唤醒未充分验证**
   合盖睡眠、唤醒后外设恢复等情况还没有系统测试。

---

## 致谢

- [OpenCore](https://github.com/acidanthera/OpenCorePkg) 及 Acidanthera 全家桶
- [NullMoth NVRM](https://github.com/nullmoth) —— NVIDIA RTX 4060 在 macOS 下的驱动
- [1401 项目](https://github.com/1401-team) —— 安装器与硬件适配
- [hoaug-tran/VoodooI2C](https://github.com/hoaug-tran/VoodooI2C) / [CirrusAudioFixup](https://github.com/hoaug-tran) —— CS35L41 支持
- [wjjkld/ROG-Strix-G17-G713PV-Hackintosh](https://github.com/wjjkld) —— 同型号参考
- [zzzyy678/SMCNvidiaGPU](https://github.com/zzzyy678/SMCNvidiaGPU)
- [GeekAudio/rog-control-macos](https://github.com/GeekAudio/rog-control-macos)

---

## 免责声明

本项目仅供学习与个人研究。使用本 EFI 造成的任何数据丢失、硬件损坏或账号问题，由使用者自行承担。请勿将本仓库的占位 SMBIOS 用于联网登录 iServices。
