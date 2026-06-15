import Cocoa
import SwiftUI
import Darwin

// MARK: - Design Tokens

let C_BG     = Color(red:0.961,green:0.965,blue:0.980)
let C_WHITE  = Color.white
let C_TEXT   = Color(red:0.102,green:0.102,blue:0.180)
let C_ACCENT = Color(red:0.871,green:0.161,blue:0.063)
let C_MUTED  = Color(red:0.600,green:0.600,blue:0.667)
let C_TAGBG  = Color(red:0.918,green:0.918,blue:0.937)
let C_GREEN  = Color(red:0.204,green:0.780,blue:0.349)
let C_AMBER  = Color(red:0.980,green:0.620,blue:0.020)
let C_GLASS_EDGE = Color.white.opacity(0.46)
let C_GLASS_HAIRLINE = Color.white.opacity(0.18)
let C_GLASS_SHADOW = Color.black.opacity(0.16)

func fmtMem(_ b: Int64) -> String {
    let gb = Double(b) / (1024*1024*1024)
    return gb >= 1 ? String(format:"%.2fGB",gb) : String(format:"%.0fMB",Double(b)/(1024*1024))
}

func barColor(_ pct: Double) -> Color {
    if pct < 60 { return C_GREEN }
    if pct < 90 { return C_AMBER }
    return C_ACCENT
}

// MARK: - Liquid Glass Surface

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
    }
}

struct LiquidGlassPanel: View {
    let radius: CGFloat
    var body: some View {
        RoundedRectangle(cornerRadius:radius,style:.continuous)
            .fill(Color.clear)
            .background {
                VisualEffectBackground(material:.hudWindow,blendingMode:.behindWindow)
                    .clipShape(RoundedRectangle(cornerRadius:radius,style:.continuous))
                    .opacity(0.86)
            }
            .overlay(alignment:.top) {
                RoundedRectangle(cornerRadius:radius,style:.continuous)
                    .stroke(Color.white.opacity(0.36),lineWidth:0.8)
                    .blur(radius:0.2)
                    .mask(
                        LinearGradient(colors:[.black,.clear],
                                       startPoint:.top,endPoint:.bottom)
                    )
            }
            .overlay(alignment:.bottom) {
                RoundedRectangle(cornerRadius:radius,style:.continuous)
                    .stroke(Color.black.opacity(0.08),lineWidth:1)
                    .blur(radius:0.6)
                    .mask(
                        LinearGradient(colors:[.clear,.black],
                                       startPoint:.top,endPoint:.bottom)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius:radius,style:.continuous)
                    .stroke(C_GLASS_EDGE,lineWidth:0.65)
            }
            .overlay(alignment:.top) {
                Capsule()
                    .fill(Color.white.opacity(0.24))
                    .frame(height:1)
                    .padding(.horizontal,30)
                    .padding(.top,2)
            }
            .shadow(color:C_GLASS_SHADOW,radius:18,x:0,y:14)
    }
}

struct LiquidGlassBand: View {
    let radius: CGFloat
    init(radius: CGFloat = 0) { self.radius = radius }

    var body: some View {
        RoundedRectangle(cornerRadius:radius,style:.continuous)
            .fill(Color.white.opacity(0.035))
            .overlay(alignment:.top) {
                Rectangle().fill(Color.white.opacity(0.16)).frame(height:0.6)
            }
            .overlay(alignment:.bottom) {
                Rectangle().fill(Color.black.opacity(0.035)).frame(height:0.6)
            }
    }
}

struct LiquidGlassRowHover: View {
    var body: some View {
        RoundedRectangle(cornerRadius:10,style:.continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius:10,style:.continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius:10,style:.continuous)
                    .stroke(Color.white.opacity(0.42),lineWidth:0.8)
            )
            .glassEffect(.regular, in: .rect(cornerRadius: 10))
            .padding(.horizontal,6)
            .padding(.vertical,2)
    }
}

struct PanelRootView: View {
    var body: some View {
        VStack(spacing:0) {
            ContentView()
        }
        .background(.clear)
    }
}

// MARK: - 系统关键进程

let kSysNames: Set<String> = [
    "loginwindow","WindowServer","kernel_task","launchd",
    "UserEventAgent","warmd","diskarbitrationd","notifyd",
    "powerd","configd","opendirectoryd","cfprefsd","syslogd",
    "coreauthd","bluetoothd","BTLEServer","corespotlightd",
    "hidd","coreduetd","apsd","locationd","tccd","trustd"
]

// MARK: - 进程说明字典（鼠标悬停时显示）

let kProcDesc: [String: String] = [
    // macOS 核心系统
    "kernel_task":         "macOS 内核，管理 CPU 调度、内存和设备驱动，不可终止",
    "launchd":             "系统和用户进程的总管家，所有进程都由它启动，不可终止",
    "WindowServer":        "负责所有窗口绘制和屏幕合成，杀死会立即注销当前用户",
    "loginwindow":         "管理用户登录会话，不可终止",
    "Finder":              "macOS 文件管理器，桌面和访达界面",
    "Dock":                "底部程序坞，管理应用图标和快速启动",
    "SystemUIServer":      "菜单栏右侧状态图标的宿主进程（Wi-Fi、音量、时钟等）",
    "ControlCenter":       "控制中心，管理亮度/音量/Wi-Fi 等快捷设置",
    "Spotlight":           "系统搜索服务，建立文件索引",
    "mds":                 "Spotlight 元数据服务器，负责索引维护",
    "mds_stores":          "Spotlight 索引数据库读写进程",
    "mdworker":            "Spotlight 文件内容抓取工作进程，占用 CPU 时通常在建索引",
    "corespotlightd":      "Core Spotlight 守护进程，管理应用内搜索索引",
    "cfprefsd":            "系统偏好设置读写守护进程，保存各应用的配置文件",
    "configd":             "网络配置守护进程，管理 IP/DNS/VPN 等网络状态",
    "notifyd":             "系统通知分发中心，负责进程间消息广播",
    "diskarbitrationd":    "磁盘插拔和挂载仲裁守护进程",
    "powerd":              "电源管理守护进程，控制睡眠/唤醒/省电策略",
    "hidd":                "Human Interface Device 守护进程，处理键盘/鼠标/触控板输入",
    "bluetoothd":          "蓝牙核心守护进程，管理蓝牙连接和配对",
    "BTLEServer":          "蓝牙低功耗（BLE）服务器，处理 BLE 外设通信",
    "locationd":           "位置服务守护进程，管理 GPS/Wi-Fi 定位和权限",
    "tccd":                "隐私权限守护进程（TCC），控制摄像头/麦克风/联系人等访问授权",
    "trustd":              "证书信任和代码签名验证守护进程",
    "coreauthd":           "Core Authentication 守护进程，处理 Touch ID 等生物认证",
    "opendirectoryd":      "用户账户和目录服务守护进程",
    "syslogd":             "系统日志守护进程",
    "warmd":               "预热守护进程，提前加载常用应用到内存以加速启动",
    "UserEventAgent":      "用户事件代理，协调 App Store 通知/隔离等用户级事件",
    "apsd":                "Apple Push Notification 守护进程，负责推送通知",
    "coreduetd":           "Core Duet 守护进程，收集用户行为数据为 Siri 和 Spotlight 建模",
    // 网络/安全
    "nsurlsessiond":       "URLSession 网络任务守护进程，代理 App 的后台下载/上传",
    "nsurlstoraged":       "URL 缓存存储守护进程",
    "netbiosd":            "NetBIOS 名称服务，用于 Windows 网络共享",
    "racoon":              "IKE/IPSec VPN 密钥交换守护进程",
    "mDNSResponder":       "Bonjour 服务，负责局域网设备发现（如 AirDrop、AirPrint）",
    "airportd":            "Wi-Fi 守护进程，管理无线网络连接",
    "sharingd":            "文件共享/隔空投送/通用剪贴板等共享服务守护进程",
    // 图形/音频
    "coreaudiod":          "Core Audio 守护进程，管理系统音频设备和路由",
    "audiomxd":            "音频混音守护进程",
    "WindowManagerAgent":  "窗口管理代理，协助 WindowServer 处理窗口动画",
    "corebrightnessd":     "屏幕亮度管理守护进程（包括 True Tone 自适应）",
    // iCloud/同步
    "cloudd":              "iCloud 核心守护进程，同步 iCloud Drive 数据",
    "bird":                "iCloud Drive 文件同步进程（以鸟命名因为它'在云端'）",
    "cloudphotod":         "iCloud 照片同步守护进程",
    "com.apple.CloudDocs.MobileDocumentsFileProvider": "iCloud Drive 文件提供者扩展",
    // 诊断/更新
    "softwareupdated":     "软件更新守护进程，检查和下载系统更新",
    "installd":            "软件包安装守护进程",
    "diagnosticd":         "系统诊断数据收集守护进程",
    "ReportCrash":         "崩溃报告生成进程，应用崩溃时自动触发",
    "SubmitDiagInfo":      "向 Apple 提交诊断信息的进程",
    "osanalyticshelper":   "操作系统使用分析上报助手",
    // 输入法/辅助功能
    "TextInputMenuAgent":  "菜单栏输入法切换图标进程",
    "universalaccessd":    "辅助功能守护进程，管理旁白/放大器等无障碍服务",
    "SiriNCService":       "Siri 通知中心服务",
    // 开发工具
    "Xcode":               "Apple 集成开发环境，用于 iOS/macOS 应用开发",
    "swiftc":              "Swift 编译器，编译 .swift 源文件",
    "clang":               "C/C++/ObjC 编译器（LLVM）",
    "lldb":                "LLVM 调试器",
    "xcodebuild":          "Xcode 命令行构建工具",
    "node":                "Node.js JavaScript 运行时",
    "python3":             "Python 3 解释器",
    "ruby":                "Ruby 解释器",
    "git":                 "Git 版本控制工具",
    "npm":                 "Node.js 包管理器",
    // 常用应用
    "Safari":              "Apple 默认浏览器",
    "SafariNetworkingProcess": "Safari 网络请求独立进程（沙盒隔离）",
    "com.apple.WebKit.WebContent": "Safari/WebView 网页渲染进程（每个标签页一个）",
    "com.apple.WebKit.Networking": "Safari/WebView 网络请求进程",
    "Google Chrome":       "Google Chrome 浏览器",
    "Google Chrome Helper":"Chrome 渲染进程（每个标签页/扩展独立进程）",
    "Firefox":             "Mozilla Firefox 浏览器",
    "Mail":                "Apple 自带邮件客户端",
    "Messages":            "iMessage 和短信客户端",
    "FaceTime":            "视频通话应用",
    "Calendar":            "日历应用",
    "Contacts":            "通讯录应用",
    "Photos":              "照片管理应用",
    "Music":               "Apple Music 播放器",
    "Podcasts":            "播客应用",
    "TV":                  "Apple TV 视频播放器",
    "Notes":               "备忘录应用",
    "Reminders":           "提醒事项应用",
    "Maps":                "地图应用",
    "Terminal":            "终端命令行工具",
    "iTerm2":              "第三方增强终端",
    "Activity Monitor":    "活动监视器，显示 CPU/内存/磁盘/网络使用情况",
    "Automator":           "自动化工作流工具",
    "Script Editor":       "AppleScript 脚本编辑器",
    "Preview":             "预览，查看图片/PDF 文件",
    "QuickLookUIService":  "快速查看（空格预览）服务进程",
    "qlmanage":            "命令行快速查看管理工具",
    "Slack":               "团队即时通讯应用",
    "Discord":             "游戏/社群语音文字通讯应用",
    "WeChat":              "微信客户端",
    "zoom.us":             "Zoom 视频会议客户端",
    "Telegram":            "Telegram 即时通讯客户端",
    "Figma":               "UI/UX 设计协作工具",
    "Sketch":              "矢量设计工具，常用于 UI 设计",
    "Adobe Photoshop":     "Adobe 图像编辑器",
    "Adobe Illustrator":   "Adobe 矢量图形编辑器",
    "Final Cut Pro":       "Apple 专业视频剪辑软件",
    "Logic Pro":           "Apple 专业音乐制作软件",
    "Microsoft Word":      "Word 文字处理软件",
    "Microsoft Excel":     "Excel 电子表格软件",
    "Microsoft PowerPoint":"PowerPoint 演示文稿软件",
    "Notion":              "多功能笔记和项目管理工具",
    "1Password":           "密码管理器",
    "Bartender":           "菜单栏图标整理工具",
    "Alfred":              "启动器和效率工具",
    "Raycast":             "快速启动器和效率工具",
    "CleanMyMac":          "系统清理和优化工具",
    "Docker":              "容器化开发平台",
    "com.docker.backend":  "Docker Desktop 后台服务",
    "Postgres":            "PostgreSQL 数据库",
    "redis-server":        "Redis 内存数据库服务器",
    "nginx":               "Nginx Web 服务器/反向代理",
    "httpd":               "Apache HTTP Web 服务器",
    "sshd":                "SSH 远程登录守护进程",
    // 本应用
    "ProcMonitor":         "当前应用：进程监控工具",
]

func procDescription(_ name: String) -> String {
    if let d = kProcDesc[name] { return d }
    // 模糊匹配：前缀/包含
    for (k, v) in kProcDesc {
        if name.hasPrefix(k) || k.hasPrefix(name) { return v }
    }
    return "进程：\(name)（暂无说明，悬停时显示 PID）"
}

// MARK: - Model

struct PInfo: Identifiable {
    let id = UUID(); let pid:Int; let ppid:Int; let name:String
    let rss:Int64; let cpu:Double; let user:String
    let path: String   // 可执行文件完整路径（用于系统进程判定）
    let cwd:  String   // 工作目录（开发进程展示项目名用）
    let appIcon:NSImage?; let appName:String?
    var displayName: String { appName ?? name }
    var subName: String {
        // 开发进程显示"项目目录 · PID"，其余只显示 PID
        if !cwd.isEmpty {
            let dir = (cwd as NSString).lastPathComponent
            return "\(dir)  ·  PID \(pid)"
        }
        return "PID \(pid)"
    }
    var isSystem: Bool {
        // 1. 非当前用户运行的进程
        if user=="root" || user.hasPrefix("_") || user=="daemon" { return true }
        // 2. 路径在系统框架/守护程序目录 → 系统进程
        //    注意：/bin/ 和 /usr/bin/ 是用户工具（zsh/bash/python等），不算系统进程
        if !path.isEmpty {
            if path.hasPrefix("/System/Library/")
                || path.hasPrefix("/usr/libexec/")
                || path.hasPrefix("/usr/sbin/")
                || path.hasPrefix("/private/var/") { return true }
        }
        // 3. 兜底：已知系统进程名
        return kSysNames.contains(name)
    }
}

// MARK: - 进程组

struct PGroup: Identifiable {
    let id = UUID(); var parent:PInfo; var children:[PInfo]
    var hasChildren: Bool { !children.isEmpty }
    var totalRss: Int64  { parent.rss + children.reduce(0){$0+$1.rss} }
    var totalCpu: Double { parent.cpu + children.reduce(0){$0+$1.cpu} }
}

// MARK: - proc_pidinfo 绑定（实时 CPU 采样）

// proc_pidinfo / proc_pidpath 在 libSystem 中，通过 @_silgen_name 直接绑定
@_silgen_name("proc_pidinfo")
private func _proc_pidinfo(_ pid: Int32, _ flavor: Int32, _ arg: UInt64,
                            _ buf: UnsafeMutableRawPointer!, _ bufsize: Int32) -> Int32

@_silgen_name("proc_pidpath")
private func _proc_pidpath(_ pid: Int32, _ buf: UnsafeMutableRawPointer!, _ size: UInt32) -> Int32
private let PROC_PIDPATH_MAXSIZE: Int = 4096

private let PROC_PIDTASKINFO_FL: Int32 = 4   // <sys/proc_info.h>

/// 与 C 的 proc_taskinfo 结构体内存布局对齐（96 字节）
private struct ProcTaskInfo {
    var pti_virtual_size:      UInt64 = 0
    var pti_resident_size:     UInt64 = 0
    var pti_total_user:        UInt64 = 0   // 用户态 CPU 时间（纳秒）
    var pti_total_system:      UInt64 = 0   // 内核态 CPU 时间（纳秒）
    var pti_threads_user:      UInt64 = 0
    var pti_threads_system:    UInt64 = 0
    var pti_policy:            Int32  = 0
    var pti_faults:            Int32  = 0
    var pti_pageins:           Int32  = 0
    var pti_cow_faults:        Int32  = 0
    var pti_messages_sent:     Int32  = 0
    var pti_messages_received: Int32  = 0
    var pti_syscalls_mach:     Int32  = 0
    var pti_syscalls_unix:     Int32  = 0
    var pti_csw:               Int32  = 0
    var pti_threadnum:         Int32  = 0
    var pti_numrunning:        Int32  = 0
    var pti_priority:          Int32  = 0
}

private struct CpuSnapshot { let totalNs: UInt64; let wallNs: UInt64 }

// MARK: - Monitor

class Monitor: ObservableObject {
    @Published var procs    : [PInfo] = []
    @Published var memUsed  : Double  = 0
    @Published var memTotal : Double  = 16
    @Published var memPct   : Double  = 0
    @Published var revision : Int     = 0

    private var timer: Timer?
    // 上次刷新的 CPU 快照（用于计算 delta）
    private var cpuBaseline: [Int: CpuSnapshot] = [:]
    private var tbNumer: UInt32 = 1
    private var tbDenom: UInt32 = 1
    // 工作目录缓存：只对新出现的开发进程调用 lsof，已知的直接复用
    private var cwdCache: [Int: String] = [:]

    // 需要显示工作目录的进程名
    private static let kDevNames: Set<String> = [
        "node","npm","python3","python","ruby","bun",
        "webpack","vite","esbuild","tsc","ts-node",
        "cargo","go","gradle","mvn","make"
    ]

    init() {
        var tb = mach_timebase_info_data_t()
        mach_timebase_info(&tb)
        tbNumer = tb.numer; tbDenom = tb.denom
        refresh()
        // 10s 刷新：proc_pidinfo 是内核调用，开销极低
        timer = Timer.scheduledTimer(withTimeInterval:10,repeats:true){[weak self] _ in self?.refresh()}
    }

    /// mach_absolute_time → 纳秒
    private func wallNsNow() -> UInt64 {
        mach_absolute_time() * UInt64(tbNumer) / UInt64(tbDenom)
    }

    func refresh() {
        let snapshot:[Int:(name:String,icon:NSImage)] = {
            var d:[Int:(String,NSImage)] = [:]
            for app in NSWorkspace.shared.runningApplications {
                let pid = Int(app.processIdentifier)
                guard pid>0, let icon=app.icon else { continue }
                d[pid] = (app.localizedName ?? app.bundleIdentifier ?? "", icon)
            }
            return d
        }()
        DispatchQueue.global(qos:.userInitiated).async {
            let raw = self.fetchRaw()   // 实例方法，访问 cpuBaseline
            let enriched = raw.map { r -> PInfo in
                let info = snapshot[r.pid]
                return PInfo(pid:r.pid,ppid:r.ppid,name:r.name,rss:r.rss,cpu:r.cpu,user:r.user,
                             path:r.path,cwd:r.cwd,appIcon:info?.icon,appName:info?.name)
            }
            let (u,t,pct) = Self.fetchMem()
            DispatchQueue.main.async {
                self.procs=enriched; self.memUsed=u; self.memTotal=t
                self.memPct=pct; self.revision+=1
            }
        }
    }

    func kill(pid: Int) {
        Darwin.kill(pid_t(pid),SIGTERM)
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5){
            if Darwin.kill(pid_t(pid),0)==0 { Darwin.kill(pid_t(pid),SIGKILL) }
            self.refresh()
        }
    }

    private struct RawProc { let pid:Int;let ppid:Int;let name:String;let rss:Int64;let cpu:Double;let user:String;let path:String;let cwd:String }
    private struct PsEntry  { let pid:Int;let ppid:Int;let name:String;let user:String }

    /// ps 只用于获取 pid/ppid/user/comm，不再读 CPU（CPU 由 proc_pidinfo delta 计算）
    private static func fetchPsEntries() -> [PsEntry] {
        let t=Process(); t.executableURL=URL(fileURLWithPath:"/bin/ps")
        t.arguments=["-eo","user=,pid=,ppid=,comm="]
        let p=Pipe(); t.standardOutput=p; t.standardError=Pipe(); try? t.run()
        let d=p.fileHandleForReading.readDataToEndOfFile(); t.waitUntilExit()
        guard let raw=String(data:d,encoding:.utf8) else { return [] }
        return raw.components(separatedBy:"\n").compactMap { line -> PsEntry? in
            let cols=line.trimmingCharacters(in:.whitespaces)
                .components(separatedBy:.whitespaces).filter{!$0.isEmpty}
            guard cols.count>=4, let pid=Int(cols[1]), let ppid=Int(cols[2]) else { return nil }
            let user=cols[0]
            let rawPath=cols[3...].joined(separator:" ")
            let last=String(rawPath.split(separator:"/").last ?? Substring(rawPath))
            let name=String(last.unicodeScalars.filter{$0.value>0x1F&&$0.value<0x7F}
                .map(Character.init).prefix(40)).trimmingCharacters(in:.whitespaces)
            return PsEntry(pid:pid,ppid:ppid,name:name.isEmpty ? "proc-\(pid)":name,user:user)
        }
    }

    /// 用 lsof 批量获取一批 PID 的工作目录（只对新进程调用，成本低）
    private static func fetchCWDs(pids: [Int]) -> [Int: String] {
        guard !pids.isEmpty else { return [:] }
        let pidArg = pids.map{String($0)}.joined(separator:",")
        let t=Process(); t.executableURL=URL(fileURLWithPath:"/usr/sbin/lsof")
        t.arguments=["-p",pidArg,"-a","-d","cwd","-Fn"]
        let p=Pipe(); t.standardOutput=p; t.standardError=Pipe(); try? t.run()
        let d=p.fileHandleForReading.readDataToEndOfFile(); t.waitUntilExit()
        guard let raw=String(data:d,encoding:.utf8) else { return [:] }
        var result:[Int:String]=[:]; var cur=0
        for line in raw.components(separatedBy:"\n") {
            if line.hasPrefix("p"), let pid=Int(line.dropFirst()) { cur=pid }
            else if line.hasPrefix("n"), cur>0 { result[cur]=String(line.dropFirst()); cur=0 }
        }
        return result
    }

    /// 采样 proc_pidinfo，计算 CPU% = Δcpu_ns / Δwall_ns × 100
    private func fetchRaw() -> [RawProc] {
        let entries = Self.fetchPsEntries()
        let now = wallNsNow()
        var newBaseline: [Int: CpuSnapshot] = [:]
        var result: [RawProc] = []

        for e in entries {
            var info = ProcTaskInfo()
            let ret = _proc_pidinfo(Int32(e.pid), PROC_PIDTASKINFO_FL, 0,
                                    &info, Int32(MemoryLayout<ProcTaskInfo>.size))
            guard ret > 0 else { continue }

            let totalNs = info.pti_total_user + info.pti_total_system
            let rss     = Int64(info.pti_resident_size)

            // 首次刷新无 baseline → cpu=0；之后用 delta 算实时占比
            var cpu: Double = 0
            if let prev = cpuBaseline[e.pid], now > prev.wallNs {
                let cpuDelta  = totalNs >= prev.totalNs ? totalNs - prev.totalNs : 0
                let wallDelta = now - prev.wallNs
                cpu = Double(cpuDelta) / Double(wallDelta) * 100.0
            }

            // 获取可执行文件完整路径（用于系统进程判定）
            var pathBuf = [CChar](repeating:0, count:PROC_PIDPATH_MAXSIZE)
            let pathRet = _proc_pidpath(Int32(e.pid), &pathBuf, UInt32(PROC_PIDPATH_MAXSIZE))
            let exePath = pathRet > 0 ? String(cString:pathBuf) : ""

            newBaseline[e.pid] = CpuSnapshot(totalNs:totalNs, wallNs:now)
            result.append(RawProc(pid:e.pid,ppid:e.ppid,name:e.name,rss:rss,cpu:cpu,user:e.user,path:exePath,cwd:""))
        }

        cpuBaseline = newBaseline

        // 对开发进程批量获取工作目录（只对缓存里没有的新 PID 调用 lsof）
        let devProcs = result.filter { Self.kDevNames.contains($0.name) }
        let newPids  = devProcs.map(\.pid).filter { cwdCache[$0] == nil }
        if !newPids.isEmpty {
            let fresh = Self.fetchCWDs(pids: newPids)
            for (pid, cwd) in fresh { cwdCache[pid] = cwd }
        }
        // 清理已退出进程的缓存
        let livePids = Set(result.map(\.pid))
        cwdCache = cwdCache.filter { livePids.contains($0.key) }

        return result.map { r in
            RawProc(pid:r.pid,ppid:r.ppid,name:r.name,rss:r.rss,cpu:r.cpu,
                    user:r.user,path:r.path,cwd:cwdCache[r.pid] ?? "")
        }
    }

    static func fetchMem() -> (Double,Double,Double) {
        var total:Int64=0; var sz=MemoryLayout<Int64>.size
        sysctlbyname("hw.memsize",&total,&sz,nil,0)
        let ps=Int64(vm_page_size); var vs=vm_statistics64()
        var cnt=mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size/MemoryLayout<integer_t>.size)
        withUnsafeMutablePointer(to:&vs){$0.withMemoryRebound(to:integer_t.self,capacity:Int(cnt)){
            _ = host_statistics64(mach_host_self(),HOST_VM_INFO64,$0,&cnt)}}
        // 与活动监视器一致：App内存(active) + Wired + 压缩内存
        // inactive 页是缓存、可随时回收，不算"已用"
        let used = (Int64(vs.active_count) + Int64(vs.wire_count)
                    + Int64(vs.compressor_page_count)) * ps
        let gb = 1024.0*1024*1024
        return (Double(used)/gb, Double(total)/gb, Double(used)/Double(total)*100)
    }
}

// MARK: - Process Row

struct PRow: View {
    let p            : PInfo
    let displayRss   : Int64
    let displayCpu   : Double
    let totalMemBytes: Int64
    let showMem      : Bool
    let childCount   : Int     // 0 = 无子进程，>0 = 父进程
    let isExpanded   : Bool
    let isChild      : Bool
    let onToggle     : () -> Void
    let onKill       : () -> Void

    @State private var hov     = false
    @State private var killHov = false

    var hasChildren: Bool { childCount > 0 }
    var rssPct: CGFloat { totalMemBytes>0 ? CGFloat(Double(displayRss)/Double(totalMemBytes)) : 0 }
    var cpuPct: CGFloat { CGFloat(min(displayCpu/100.0,1.0)) }
    var memBarColor: Color { barColor(Double(rssPct)*100) }
    var cpuBarColor: Color { barColor(displayCpu) }

    var body: some View {
        HStack(spacing:0) {

            // ── 图标（子进程缩进 28pt）────────────────────
            Group {
                if let icon = p.appIcon {
                    Image(nsImage:icon).resizable().interpolation(.high)
                        .frame(width:26,height:26).cornerRadius(7)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius:7).fill(C_TAGBG)
                        Image(systemName:"gearshape.fill")
                            .font(.system(size:12)).foregroundColor(C_MUTED)
                    }.frame(width:26,height:26)
                }
            }
            .padding(.leading, isChild ? 28 : 12)
            .opacity(isChild ? 0.7 : 1.0)

            // ── 名称区域（点击展开/收起）──────────────────
            VStack(alignment:.leading,spacing:1) {
                HStack(spacing:5) {
                    Text(p.displayName)
                        .font(.system(size:isChild ? 12 : 13,
                                      weight:isChild ? .regular : .medium))
                        .foregroundColor(isChild ? C_TEXT.opacity(0.7) : C_TEXT)
                        .lineLimit(1)

                    // 展开按钮 + 子进程数（紧跟在名称右边）
                    if hasChildren {
                        HStack(spacing:2) {
                            Text("\(childCount)")
                                .font(.system(size:9,weight:.semibold))
                                .foregroundColor(C_MUTED)
                            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                                .font(.system(size:8,weight:.semibold))
                                .foregroundColor(C_MUTED)
                        }
                        .padding(.horizontal,4).padding(.vertical,1)
                        .background(C_TAGBG)
                        .cornerRadius(6)
                    }
                }
                Text(p.subName)
                    .font(.system(size:10))
                    .foregroundColor(C_MUTED.opacity(0.55))
            }
            .padding(.leading,7)
            .frame(width:164,alignment:.leading)
            .contentShape(Rectangle())
            .help(procDescription(p.name))
            .onTapGesture { if hasChildren { onToggle() } }

            Spacer()

            // ── 进度条 ────────────────────────────────────
            if showMem {
                HStack(spacing:4) {
                    GeometryReader { g in
                        ZStack(alignment:.leading) {
                            Capsule().fill(C_TAGBG).frame(height:3)
                            Capsule().fill(memBarColor)
                                .frame(width:g.size.width*rssPct,height:3)
                        }
                    }.frame(width:58,height:3)
                    Text(fmtMem(displayRss))
                        .font(.system(size:11,weight:.medium).monospacedDigit())
                        .foregroundColor(isChild ? C_MUTED : C_TEXT)
                        .frame(width:50,alignment:.trailing)
                }.frame(width:112)
            } else {
                HStack(spacing:4) {
                    GeometryReader { g in
                        ZStack(alignment:.leading) {
                            Capsule().fill(C_TAGBG).frame(height:3)
                            Capsule().fill(cpuBarColor)
                                .frame(width:g.size.width*cpuPct,height:3)
                        }
                    }.frame(width:58,height:3)
                    Text(String(format:"%.1f%%",displayCpu))
                        .font(.system(size:11).monospacedDigit())
                        .foregroundColor(isChild ? C_MUTED : C_TEXT)
                        .frame(width:44,alignment:.trailing)
                }.frame(width:106)
            }

            // ── 终止按钮（系统进程：橙色警告；用户进程：红色）────
            Button(action:{
                if p.isSystem {
                    let desc = procDescription(p.name)
                    let alert = NSAlert()
                    alert.messageText = "终止系统进程「\(p.displayName)」？"
                    alert.informativeText = "\(desc)\n\n强制终止系统进程可能导致系统不稳定、其他应用崩溃，甚至需要重启电脑。"
                    alert.alertStyle = .critical
                    alert.addButton(withTitle: "取消")
                    let killBtn = alert.addButton(withTitle: "强制终止")
                    killBtn.hasDestructiveAction = true
                    if alert.runModal() == .alertSecondButtonReturn { onKill() }
                } else {
                    onKill()
                }
            }) {
                Image(systemName:"xmark.circle.fill")
                    .font(.system(size:13))
                    .foregroundColor(
                        killHov
                            ? (p.isSystem ? C_AMBER : C_ACCENT)
                            : C_MUTED.opacity(0.28)
                    )
            }
            .buttonStyle(.plain)
            .onHover{h in killHov=h}
            .help(p.isSystem ? "警告：终止系统进程可能导致系统不稳定" : "终止进程")
            .frame(width:34)
            .padding(.trailing,6)
        }
        .frame(height: isChild ? 32 : 39)
        .background {
            if hov { LiquidGlassRowHover() }
        }
        .contentShape(Rectangle())
        .onHover{h in hov=h}
    }
}

// MARK: - Sort Button

struct SortBtn: View {
    let label:String; let active:Bool; let action:()->Void
    @State private var hov=false
    var body: some View {
        Button(action:action) {
            Text(label).font(.system(size:11,weight:.medium))
                .padding(.horizontal,10).padding(.vertical,3)
                .background {
                    Capsule()
                        .fill(active ? C_TEXT.opacity(0.76) : Color.white.opacity(hov ? 0.14 : 0.06))
                        .overlay {
                            Capsule()
                                .stroke(active ? Color.white.opacity(0.24) : C_GLASS_HAIRLINE,lineWidth:0.8)
                        }
                        .glassEffect(.regular, in: .capsule)
                }
                .foregroundColor(active ? .white : C_MUTED)
                .shadow(color:active ? Color.black.opacity(0.20) : Color.clear,
                        radius:active ? 7 : 0,x:0,y:3)
        }.buttonStyle(.plain).onHover{h in hov=h}
    }
}

struct ModeMetricStrip: View {
    let showMem: Bool
    let memUsed: Double
    let memTotal: Double
    let memPct: Double
    let cpuPct: Double

    var valuePct: Double { showMem ? memPct : cpuPct }
    var clampedPct: Double { min(max(valuePct,0),100) }
    var valueText: String {
        if showMem {
            return String(format:"%.1f / %.0f GB",memUsed,memTotal)
        }
        return String(format:"%.1f%%",cpuPct)
    }

    var body: some View {
        HStack(spacing:7) {
            GeometryReader { g in
                ZStack(alignment:.leading) {
                    Capsule().fill(Color.white.opacity(0.26))
                    Capsule().fill(barColor(clampedPct))
                        .frame(width:g.size.width*CGFloat(clampedPct/100.0))
                }
            }
            .frame(width:104,height:4)

            Text(valueText)
                .font(.system(size:10,weight:.semibold).monospacedDigit())
                .foregroundColor(C_TEXT.opacity(0.72))
                .frame(width:showMem ? 78 : 44,alignment:.leading)
        }
        .frame(height:12)
        .help(showMem
              ? "已用内存 \(String(format:"%.1f",memUsed))/\(String(format:"%.0f",memTotal)) GB · \(Int(clampedPct.rounded()))%"
              : "当前 CPU 合计 \(String(format:"%.1f",cpuPct))%")
    }
}

// MARK: - Content View

struct ContentView: View {
    @StateObject var monitor = Monitor()
    @State private var showMem      = true
    @State private var showSystem   = false
    @State private var expandedPids : Set<Int> = []
    @State private var cachedGroups : [PGroup] = []

    var totalMemBytes: Int64 { Int64(monitor.memTotal*1024*1024*1024) }
    var visibleCpuPct: Double { cachedGroups.reduce(0){$0+$1.totalCpu} }

    func buildGroups() -> [PGroup] {
        let list = monitor.procs.filter { showSystem ? $0.isSystem : !$0.isSystem }
        let pidSet = Set(list.map(\.pid))
        let pidMap = Dictionary(uniqueKeysWithValues:list.map{($0.pid,$0)})
        var childrenOf:[Int:[PInfo]] = [:]; var topPids:[Int] = []
        for p in list {
            if p.ppid != p.pid && pidSet.contains(p.ppid) {
                childrenOf[p.ppid,default:[]].append(p)
            } else { topPids.append(p.pid) }
        }
        var result:[PGroup] = topPids.compactMap { pid in
            guard let parent=pidMap[pid] else { return nil }
            let kids=(childrenOf[pid] ?? []).sorted{ showMem ? $0.rss>$1.rss : $0.cpu>$1.cpu }
            return PGroup(parent:parent,children:kids)
        }
        result.sort{ showMem ? $0.totalRss>$1.totalRss : $0.totalCpu>$1.totalCpu }
        return result
    }

    var body: some View {
        VStack(spacing:0) {

            // ── 顶部工具栏 ────────────────────────────────
            HStack(alignment:.center,spacing:8) {
                Text("进程监控")
                    .font(.system(size:13,weight:.medium))
                    .foregroundColor(C_TEXT)
                    .frame(width:72,alignment:.leading)

                Spacer()

                VStack(spacing:5) {
                    HStack(spacing:8) {
                        SortBtn(label:"内存",active:showMem) {
                            showMem=true; cachedGroups=buildGroups()
                        }
                        SortBtn(label:"CPU",active:!showMem) {
                            showMem=false; cachedGroups=buildGroups()
                        }
                    }
                    ModeMetricStrip(showMem:showMem,
                                    memUsed:monitor.memUsed,
                                    memTotal:monitor.memTotal,
                                    memPct:monitor.memPct,
                                    cpuPct:visibleCpuPct)
                }

                Spacer()

                Button(action:{NSApplication.shared.terminate(nil)}) {
                    Text("退出").font(.system(size:11)).foregroundColor(C_MUTED)
                }.buttonStyle(.plain)
                .frame(width:34,alignment:.trailing)
            }
            .padding(.horizontal,12).padding(.top,8).padding(.bottom,7)

            // ── 列表表头 ──────────────────────────────────
            HStack(spacing:0) {
                Text("进程 / App").font(.system(size:10)).foregroundColor(C_MUTED)
                    .padding(.leading,42)
                Spacer()
                Text(showMem ? "内存" : "CPU")
                    .font(.system(size:10)).foregroundColor(C_MUTED)
                    .frame(width:showMem ? 112 : 106, alignment:.trailing)
                Text("").frame(width:34).padding(.trailing,6)
            }
            .frame(height:26)
            .background {
                LiquidGlassBand()
                    .opacity(0.55)
            }

            Divider().opacity(0.08)

            // ── 进程列表 ──────────────────────────────────
            ScrollView(.vertical, showsIndicators:false) {
                LazyVStack(spacing:0) {
                    if cachedGroups.isEmpty {
                        Text("正在加载…")
                            .font(.system(size:12)).foregroundColor(C_MUTED)
                            .padding(.top,50)
                    } else {
                        let displayed = Array(cachedGroups.prefix(30))
                        ForEach(Array(displayed.enumerated()), id:\.1.id) { gi, group in
                            VStack(spacing:0) {
                                PRow(p:group.parent,
                                     displayRss:group.totalRss, displayCpu:group.totalCpu,
                                     totalMemBytes:totalMemBytes, showMem:showMem,
                                     childCount:group.children.count,
                                     isExpanded:expandedPids.contains(group.parent.pid),
                                     isChild:false,
                                     onToggle:{
                                         if expandedPids.contains(group.parent.pid) {
                                             expandedPids.remove(group.parent.pid)
                                         } else {
                                             expandedPids.insert(group.parent.pid)
                                         }
                                     },
                                     onKill:{ monitor.kill(pid:group.parent.pid) })

                                if expandedPids.contains(group.parent.pid) {
                                    ForEach(group.children,id:\.id) { child in
                                        VStack(spacing:0) {
                                            Divider().opacity(0.1).padding(.leading,40)
                                            PRow(p:child,
                                                 displayRss:child.rss, displayCpu:child.cpu,
                                                 totalMemBytes:totalMemBytes, showMem:showMem,
                                                 childCount:0, isExpanded:false, isChild:true,
                                                 onToggle:{},
                                                 onKill:{ monitor.kill(pid:child.pid) })
                                        }
                                    }
                                }

                                if gi < displayed.count-1 {
                                    Divider().opacity(0.06).padding(.leading,40)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom,6)
            }
            .background(.clear)

            // ── 底部导航 ──────────────────────────────────
            Divider().opacity(0.15)
            HStack {
                let modeWord = showMem ? "内存" : "CPU"
                if showSystem {
                    HStack(spacing:4) {
                        Image(systemName:"lock.fill").font(.system(size:10)).foregroundColor(C_MUTED)
                        Text("系统\(modeWord)").font(.system(size:11)).foregroundColor(C_MUTED)
                    }
                    Spacer()
                    Button(action:{ showSystem=false; cachedGroups=buildGroups() }) {
                        HStack(spacing:3) {
                            Image(systemName:"chevron.left").font(.system(size:10,weight:.medium))
                            Text("用户\(modeWord)").font(.system(size:11,weight:.medium))
                        }.foregroundColor(C_ACCENT)
                    }.buttonStyle(.plain)
                } else {
                    HStack(spacing:4) {
                        Image(systemName:"person.fill").font(.system(size:10)).foregroundColor(C_MUTED)
                        Text("用户\(modeWord)").font(.system(size:11)).foregroundColor(C_MUTED)
                    }
                    Spacer()
                    Button(action:{ showSystem=true; cachedGroups=buildGroups() }) {
                        HStack(spacing:3) {
                            Text("系统\(modeWord)").font(.system(size:11,weight:.medium))
                            Image(systemName:"chevron.right").font(.system(size:10,weight:.medium))
                        }.foregroundColor(C_MUTED)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal,12).padding(.vertical,7)
            .background {
                LiquidGlassBand(radius:14)
                    .opacity(0.42)
            }
        }
        .frame(width:382,height:466)
        .background {
            LiquidGlassPanel(radius:14)
        }
        .clipShape(RoundedRectangle(cornerRadius:14,style:.continuous))
        .overlay(alignment:.topLeading) {
            RoundedRectangle(cornerRadius:14,style:.continuous)
                .stroke(C_GLASS_EDGE,lineWidth:0.8)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .onChange(of:monitor.revision) { cachedGroups=buildGroups() }
        .onAppear { cachedGroups=buildGroups() }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var panel     : NSPanel?
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
        if let btn = statusItem.button {
            let img = NSImage(systemSymbolName:"cpu",accessibilityDescription:"进程监控")
            img?.isTemplate = true
            btn.image=img; btn.action=#selector(toggle); btn.target=self
        }
    }

    @objc func toggle(_ sender: NSStatusBarButton) {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel(relativeTo:sender)
        }
    }

    func makePanel() -> NSPanel {
        let size = NSSize(width:382,height:466)
        let hc = NSHostingController(rootView:PanelRootView())
        hc.view.wantsLayer = true
        hc.view.layer?.backgroundColor = .clear

        let panel = NSPanel(contentRect:NSRect(origin:.zero,size:size),
                            styleMask:[.borderless,.nonactivatingPanel],
                            backing:.buffered,
                            defer:false)
        panel.contentViewController = hc
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces,.transient,.fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        return panel
    }

    func showPanel(relativeTo sender: NSStatusBarButton) {
        let p = panel ?? makePanel()
        panel = p

        if let win = sender.window {
            let buttonFrame = win.convertToScreen(sender.frame)
            let x = buttonFrame.midX - p.frame.width / 2
            let y = buttonFrame.minY - p.frame.height + 2
            p.setFrameOrigin(NSPoint(x:x,y:y))
        }

        p.orderFrontRegardless()
        installDismissMonitor()
    }

    func hidePanel() {
        panel?.orderOut(nil)
        removeDismissMonitor()
    }

    func installDismissMonitor() {
        removeDismissMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching:[.leftMouseDown,.rightMouseDown]) {
            [weak self] _ in self?.hidePanel()
        }
    }

    func removeDismissMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}

// MARK: - Entry

let app = NSApplication.shared
let del = AppDelegate()
app.delegate = del
app.run()
