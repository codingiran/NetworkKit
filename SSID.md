# macOS 上获取 WiFi SSID 研究

## CoreWLAN 直接获取 SSID

```swift
import CoreWLAN

let ssid = CWWiFiClient.shared().interface()?.ssid()
print(ssid)
```

这是苹果官方推荐的获取 SSID 的方法

但是问题来了，从 macOS 13+ 开始，`CWWiFiClient` 获取 ssid 的方法需要定位授权，否则会返回 nil。下面是苹果相关 API 的注释文档:

```swift
    * @note
    * SSID information is not available unless Location Services is enabled and the user has authorized the calling app to use location services.
    *
    * @seealso
    * CLLocationManager
```

## 使用 ifconfig getsummary 获取 SSID

```bash
ipconfig getsummary en0 | grep '  SSID : ' | awk -F ': ' '{print $2}'
```

这是一种“曲线救国的方式”，利用终端命令获取 SSID。

但是问题又来了，从 macOS 15.6+ 开始，使用这条命令获取到的 SSID 为 `<redacted>`，这是因为苹果发现了这个“漏洞”，并进行了修复。

## 使用 system_profiler 获取 SSID

```bash
system_profiler SPAirPortDataType -detailLevel basic | awk '/Current Network/ {getline;$1=$1;print $0 | "tr -d ':'";exit}'
```

目前苹果尚未封堵这个“漏洞”，使用上述命令依旧可以获取到 SSID。但这个命名有个致命的缺陷：非常的慢！
利用 timer 命令计算耗时:

```bash
time system_profiler SPAirPortDataType -detailLevel basic | awk '/Current Network/ {getline;$1=$1;print $0 | "tr -d ':'";exit}'
```

输出:

```bash
Zenlayer-Turbo-Test
system_profiler SPAirPortDataType -detailLevel basic  0.07s user 0.16s system 14% cpu 1.637 total
awk '/Current Network/ {getline;$1=$1;print $0 | "tr -d ':'";exit}'  0.00s user 0.00s system 0% cpu 1.636 total
```

可以看出每次获取 SSID 需要 1.6s 左右（M1 Max Macbook），这对于需要实时获取 SSID 的应用来说，显然是不够的。

Update:
从 macOS 15.7+ 开始，苹果再次封堵了这个“漏洞”，使用`system_profiler`命令获取到的 SSID 为 `<redacted>`。
