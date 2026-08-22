# DarkModeToggle

使用纯 SwiftUI 绘制的动态明暗模式切换组件，复刻 Kristine
Kolodziejski 的 Power Apps `LightDarkModeAnimated` 视觉效果。

- 支持 iOS 17+ 与 macOS 14+
- 不依赖图片、Lottie 或第三方动画库
- 接收标准 SwiftUI `Binding<Bool>`
- 提供原始柔和样式和新增高饱和拟物样式，两者使用不同初始化方法
- 支持点击与水平拖动，松手时按预测终点吸附
- 支持 Reduce Motion 和 VoiceOver
- 包含交互数学、几何与源素材数据回归测试

完整 iOS 演示 App 位于私有仓库
[DarkModeSwitchButton](https://github.com/HideOnBushTuT/DarkModeSwitchButton)。

## 效果与能力

组件在一个胶囊形轨道内组合两套场景：

- 原始样式在明亮状态显示柔和蓝天、四组漂浮云层和桃橙色太阳，在黑暗状态
  显示深色天空、22 颗细小闪烁星星和月牙。
- 新增高饱和样式使用亮黄色太阳、三层移动光环和厚云层；黑暗状态使用带三个
  陨石坑的满月和 6 颗缩放闪烁的大四角星。
- 水平拖动时，天体、天空、边框、云层和星星共享一个 `0...1` 进度并跟随手指。
- 松手时使用预测终点选择明暗状态，并用可中断弹簧吸附到端点。
- 用户开启“减弱动态效果”后，仍保留手指直接操控，但取消弹性吸附和无限循环。

## 安装

这是 private GitHub Package。使用前需保证 Xcode 已登录拥有仓库权限的
GitHub 账号。

在 Xcode 中选择 **File → Add Package Dependencies…**，输入：

```text
https://github.com/HideOnBushTuT/DarkModeToggle.git
```

依赖规则选择 **Up to Next Major Version**，起始版本为 `3.0.1`。

也可以在另一个 Package 的 `Package.swift` 中声明：

```swift
dependencies: [
    .package(
        url: "https://github.com/HideOnBushTuT/DarkModeToggle.git",
        from: "3.0.1"
    )
],
targets: [
    .target(
        name: "YourFeature",
        dependencies: [
            .product(
                name: "DarkModeSwitchDemoFeature",
                package: "DarkModeToggle"
            )
        ]
    )
]
```

仓库名是 `DarkModeToggle`，当前 Swift Product 与导入模块名仍为
`DarkModeSwitchDemoFeature`。

## 使用

```swift
import DarkModeSwitchDemoFeature
import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        DarkModeToggle(isDarkMode: $isDarkMode)
            .frame(width: 260)
            .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
```

原始初始化方法保持不变：

```swift
DarkModeToggle(isDarkMode: $isDarkMode)
```

需要使用新增高饱和样式时，改用独立初始化方法；无需传入样式枚举或配置参数：

```swift
DarkModeToggle(vividIsDarkMode: $isDarkMode)
```

`DarkModeToggle` 只负责展示与切换绑定值。是否持久化状态、是否把状态应用到
整个 App，由调用方决定。

## 对外 API

Package 对外只暴露可复用的开关 View：

```swift
public struct DarkModeToggle: View {
    public init(isDarkMode: Binding<Bool>)
    public init(vividIsDarkMode: Binding<Bool>)
}
```

`init(isDarkMode:)` 永远使用原始样式，`init(vividIsDarkMode:)` 永远使用新增
高饱和样式。两个入口共享同一套状态、拖动、吸附和无障碍行为，后续增加新视觉
不会改变现有调用方的效果。

页面布局、状态持久化和 App 外观由使用方自己的 `ContentView` 或其他容器
管理，不属于 Package 的公开 API。

## 内部实现

```text
DarkModeToggle
├── DarkModeToggleInteraction
│   └── 进度、方向、钳制与预测终点
├── DarkModeToggleVisuals
│   ├── 可中断的当前呈现进度
│   ├── ToggleTrack → 原始轨道
│   └── VividToggleTrack → 高饱和轨道、光环和场景
├── ToggleTrack（原始样式）
│   ├── DayScene → 4 组 Canvas 云层
│   └── NightScene → 22 个 FourPointStar
├── VividToggleTrack（新增样式）
│   ├── VividDayScene → 2 组 Canvas 厚云层
│   └── VividNightScene → 6 个 FourPointStar
└── CelestialThumb
    ├── SunDisc + MoonDisc
    └── VividSunDisc + VividMoonDisc
```

主要文件职责：

- `DarkModeToggle.swift`：按钮语义、拖动生命周期、呈现进度、轨道和场景组合。
- `DarkModeToggleInteraction.swift`：可独立测试的方向、进度与吸附计算。
- `DarkModeToggleMetrics.swift`：将原始设计坐标按目标宽度等比缩放。
- `DarkModeToggleArt.swift`：保存云朵圆形、星星坐标、透明度和时长数据。
- `DayScene.swift`：通过 `Canvas` 绘制并循环移动云层。
- `NightScene.swift`：放置星星并按组循环改变透明度。
- `CelestialThumb.swift`：太阳/月亮绘制、交叉淡入淡出和横向移动。
- `VividToggleTrack.swift`：新增样式的配色、移动光环、厚云层和大星星组合。
- `VividToggleArt.swift`：新增样式独立的云层与星星素材数据。
- `FourPointStar.swift`：自定义四角星 `Shape`。

组件保留原设计的 `130×80` 外部比例、`173×69` 轨道画板和
`173×84` 天体画板。天体层宽度是轨道的 `1.2×`，所有坐标统一经过
`DarkModeToggleMetrics` 缩放，因此调用方可以只改变组件宽度。

## 拖动、动画与 Reduce Motion

拖动开始前保留 10 pt 移动阈值，避免点击抖动被误判。识别为横向拖动后，组件用
实际天体行程归一化位移：

```text
progress = clamp(startProgress + translationX / translationTravel, 0 ... 1)
```

慢速松手会落到最近端点；快速滑动则使用 SwiftUI 的预测位移判断目标，所以手指
不必先越过中点。动画中途也可以重新抓取，新的拖动会从当前屏幕呈现进度继续。

关键参数：

| 行为 | 参数 |
| --- | --- |
| 拖动识别阈值 | 10 pt |
| 松手/点击吸附 | Spring response `0.35` / damping `0.82` |
| Reduce Motion 自动收尾 | Ease-out `0.2s`，无弹性 |
| 四组云层循环 | 3.5 / 4.5 / 2.5 / 5.5 秒 |
| 四组星星闪烁 | 3 / 2 / 1 / 5 秒 |
| 高饱和样式两组云层循环 | 4.8 / 6.2 秒 |
| 高饱和样式六颗星星闪烁 | 3.5 / 4.1 / 4.9 / 5.3 / 3 / 2.2 秒 |

天体层使用原始 X 位移 `-100 → -25`，再乘以当前缩放比例。云层从
Y `+5` 移动至 `-10` 并自动往返。

检测到 `accessibilityReduceMotion` 时：

- 手指控制期间仍然连续跟随，这是由用户直接驱动的反馈。
- 点击切换时天体位置直接到达端点，场景只做 0.2 秒淡化。
- 拖动松手后使用 0.2 秒非弹性收尾。
- 不启动云层和星星的无限循环。

## 测试

独立 Package 测试不依赖 App 工程：

```bash
xcodebuildmcp swift-package test \
  --package-path . \
  --configuration Debug
```

当前 11 项测试锁定：

- 原始组件、轨道和天体画板的缩放关系。
- 明暗状态、中间进度的天体位移与移动距离。
- 明暗端点、双向拖动归一化和 `0...1` 边界钳制。
- 横纵轴判定与预测终点的中点规则。
- 四组云层的数量、圆形数据、透明度和循环时长。
- 22 颗星星的数量、坐标、分组与闪烁时长。
- 两个公开初始化方法都能独立构建，并保持原入口兼容。
- 新增样式的 2 组云层、6 颗星星及各自闪烁时长。
- App 层 `ContentView.swift` 不会重新进入可复用 Package。

## 版本规则

仓库采用语义化版本：

- Patch：修复且不改变现有调用方式。
- Minor：向后兼容的新能力或公开 API。
- Major：模块名、公开初始化方法或行为的不兼容修改。

当前版本为 `3.0.1`。App 使用
`upToNextMajorVersion(from: "3.0.1")`，因此会接受 `3.x` 更新。已有
`2.x` 使用方不会自动获得新的拖动行为，需要明确升级。

版本历史：

- `3.0.1`：恢复系统标准 Button 点击/VoiceOver 激活通道，仅在拖动序列中抑制
  重复 action，修复自动化与真实点击偶发丢失。
- `3.0.0`：增加连续水平拖动、预测终点吸附，并让天体和日夜场景共享同一个
  呈现进度；公开的 `Binding<Bool>` 初始化方法保持不变。
- `2.0.0`：删除 Package 的演示 `ContentView`；状态持久化、页面背景和
  App 外观由使用方管理。
- `1.0.0`：首次发布，包含动画组件和初始演示容器。

## 来源与许可证

视觉设计和原始 Power Apps 实现来自 Kristine Kolodziejski 的
[LightDarkModeAnimated](https://github.com/kristinekolodziejski/LightDarkModeAnimated)。
新增高饱和样式参考 Xiumuzaidiao 的
[Day-night-toggle-button](https://github.com/Xiumuzaidiao/Day-night-toggle-button)。
两个项目的完整许可文本均保存在
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
