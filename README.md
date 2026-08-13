# DarkModeToggle

使用纯 SwiftUI 绘制的动态明暗模式切换组件，复刻 Kristine
Kolodziejski 的 Power Apps `LightDarkModeAnimated` 视觉效果。

- 支持 iOS 17+ 与 macOS 14+
- 不依赖图片、Lottie 或第三方动画库
- 接收标准 SwiftUI `Binding<Bool>`
- 支持 Reduce Motion 和 VoiceOver
- 包含几何与源素材数据回归测试

完整 iOS 演示 App 位于私有仓库
[DarkModeSwitchButton](https://github.com/HideOnBushTuT/DarkModeSwitchButton)。

## 效果与能力

组件在一个胶囊形轨道内组合两套场景：

- 明亮状态显示蓝天、四组漂浮云层和太阳。
- 黑暗状态显示深色天空、22 颗闪烁星星和月牙。
- 状态切换时，太阳/月亮横向移动，日夜场景同时交叉淡入淡出。
- 用户开启“减弱动态效果”后，取消横向位移和无限循环，仅保留短暂淡入淡出。

## 安装

这是 private GitHub Package。使用前需保证 Xcode 已登录拥有仓库权限的
GitHub 账号。

在 Xcode 中选择 **File → Add Package Dependencies…**，输入：

```text
https://github.com/HideOnBushTuT/DarkModeToggle.git
```

依赖规则选择 **Up to Next Major Version**，起始版本为 `2.0.0`。

也可以在另一个 Package 的 `Package.swift` 中声明：

```swift
dependencies: [
    .package(
        url: "https://github.com/HideOnBushTuT/DarkModeToggle.git",
        from: "2.0.0"
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

`DarkModeToggle` 只负责展示与切换绑定值。是否持久化状态、是否把状态应用到
整个 App，由调用方决定。

## 对外 API

Package 对外只暴露可复用的开关 View：

```swift
public struct DarkModeToggle: View {
    public init(isDarkMode: Binding<Bool>)
}
```

页面布局、状态持久化和 App 外观由使用方自己的 `ContentView` 或其他容器
管理，不属于 Package 的公开 API。

## 内部实现

```text
DarkModeToggle
├── ToggleTrack
│   ├── DayScene
│   │   └── 4 组 Canvas 云层
│   └── NightScene
│       └── 22 个 FourPointStar
└── CelestialThumb
    ├── SunDisc
    └── MoonDisc
```

主要文件职责：

- `DarkModeToggle.swift`：按钮语义、轨道、遮罩和场景组合。
- `DarkModeToggleMetrics.swift`：将原始设计坐标按目标宽度等比缩放。
- `DarkModeToggleArt.swift`：保存云朵圆形、星星坐标、透明度和时长数据。
- `DayScene.swift`：通过 `Canvas` 绘制并循环移动云层。
- `NightScene.swift`：放置星星并按组循环改变透明度。
- `CelestialThumb.swift`：太阳/月亮绘制、交叉淡入淡出和横向移动。
- `FourPointStar.swift`：自定义四角星 `Shape`。

组件保留原设计的 `130×80` 外部比例、`173×69` 轨道画板和
`173×84` 天体画板。天体层宽度是轨道的 `1.2×`，所有坐标统一经过
`DarkModeToggleMetrics` 缩放，因此调用方可以只改变组件宽度。

## 动画与 Reduce Motion

关键时间参数：

| 动画 | 时长 |
| --- | ---: |
| 日/夜场景交叉淡入淡出 | 0.5 秒 |
| 太阳/月亮交叉淡入淡出 | 0.5 秒 |
| 天体层横向移动 | 1.0 秒 |
| 四组云层循环 | 3.5 / 4.5 / 2.5 / 5.5 秒 |
| 四组星星闪烁 | 3 / 2 / 1 / 5 秒 |

天体层使用原始 X 位移 `-100 → -25`，再乘以当前缩放比例。云层从
Y `+5` 移动至 `-10` 并自动往返。

检测到 `accessibilityReduceMotion` 时：

- 不执行天体横向位移。
- 不启动云层和星星的无限循环。
- 场景切换缩短为 0.2 秒淡入淡出。

## 测试

独立 Package 测试不依赖 App 工程：

```bash
xcodebuildmcp swift-package test \
  --package-path . \
  --configuration Debug
```

当前 5 项测试锁定：

- 原始组件、轨道和天体画板的缩放关系。
- 明暗状态的天体位移与移动距离。
- 四组云层的数量、圆形数据、透明度和循环时长。
- 22 颗星星的数量、坐标、分组与闪烁时长。
- App 层 `ContentView.swift` 不会重新进入可复用 Package。

## 版本规则

仓库采用语义化版本：

- Patch：修复且不改变现有调用方式。
- Minor：向后兼容的新能力或公开 API。
- Major：模块名、公开初始化方法或行为的不兼容修改。

当前版本为 `2.0.0`。App 使用
`upToNextMajorVersion(from: "2.0.0")`，因此会接受 `2.x` 更新但不会
自动升级到 `3.0.0`。

版本历史：

- `2.0.0`：删除 Package 的演示 `ContentView`；状态持久化、页面背景和
  App 外观由使用方管理。
- `1.0.0`：首次发布，包含动画组件和初始演示容器。

## 来源与许可证

视觉设计和原始 Power Apps 实现来自 Kristine Kolodziejski 的
[LightDarkModeAnimated](https://github.com/kristinekolodziejski/LightDarkModeAnimated)。
原项目使用 MIT License，完整许可文本保存在
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
