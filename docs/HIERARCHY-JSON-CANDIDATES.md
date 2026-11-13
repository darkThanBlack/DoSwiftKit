# Hierarchy JSON 扩展候选（UIView / CALayer 子类）

现状：`Resources/DoSwiftHierarchyDefine.json` 里有 26 个 UIView 子类、2 个 CALayer 子类、
29 张枚举表，合计 210 个属性。本文逐条对照 SDK 头文件与运行时 KVC 可用性（模拟器实测
getter / setter 是否响应），只列「调试时真的会去看」的缺口。**只是候选清单，未改 JSON。**

## 1. 评估口径

| 维度 | 说明 |
|---|---|
| 命中率 | 真实业务页面上经常出现、出问题时常被怀疑的对象 |
| 能读到 | 引擎走 KVC，`responds(to:)` 没有 getter 的 key 整行跳过，所以高版本属性在低版本自动消失，不会崩 |
| 能写回 | 需同时满足 `userEditable`、可解析的 `ValueKind`、真实 setter，缺一即只读 |
| 不重复 | UIView / CALayer 代码层已有的（frame / alpha / backgroundColor / hidden / border 等）不重列 |

## 2. P0：现有类缺的属性

### 2.1 UIScrollView —— 缺的恰恰是最该有的三项

当前条目只有开关类属性，几何三项全缺。`contentOffset` / `contentSize` 是排查「内容被截断、
列表没铺满、上下莫名留白」时第一个要看的值。

| key | 类型 | 读写 | 价值 |
|---|---|---|---|
| `contentOffset` | CGPoint | 读/写 | 当前滚动位置，改它可验证回弹 / 定位逻辑 |
| `contentSize` | CGSize | 读/写 | 内容尺寸，和 frame 对比能立刻看出少算的部分 |
| `contentInset` | UIEdgeInsets | 读/写 | 业务手填的 inset |
| `adjustedContentInset` | UIEdgeInsets | 只读 | 系统叠加安全区后的真实 inset（iOS 11+） |
| `zoomScale` | double | 读/写 | |
| `scrollIndicatorInsets` | UIEdgeInsets | 读/写 | |
| `decelerationRate` | double | 读/写 | `.normal` 0.998 / `.fast` 0.99 |
| `scrollsToTop` | bool | 读/写 | 多列表时「点状态栏不回顶」的元凶 |
| `bouncesZoom` | bool | 读/写 | |
| `isDragging` / `isDecelerating` / `isZooming` | bool | 只读 | 判断手势/惯性动画是否仍在进行 |
| `refreshControl` | 对象 | 只读 | 显示类名，确认是否装了 refresh |

### 2.2 UIWindow

| key | 类型 | 读写 | 价值 |
|---|---|---|---|
| `windowLevel` | double | 读/写 | 浮窗被系统键盘、Alert 盖住时的第一现场 |
| `windowScene` | 对象 | 只读 | 多 scene 场景下确认挂在哪 |
| `canResizeToFitContent` | bool | 只读 | macCatalyst |

### 2.3 UITableView

| key | 类型 | 读写 | 价值 |
|---|---|---|---|
| `estimatedRowHeight` | double | 读/写 | 与真实高度不一致是滚动抖动 / 跳变的常见原因 |
| `estimatedSectionHeaderHeight` | double | 读/写 | 同上 |
| `estimatedSectionFooterHeight` | double | 读/写 | 同上 |
| `sectionIndexColor` | 颜色 | 读/写 | |
| `sectionIndexBackgroundColor` | 颜色 | 读/写 | |
| `isEditing` | bool | 读/写 | |
| `isTracking` | bool | 只读 | 手指是否还按着 |
| `backgroundView` / `tableHeaderView` / `tableFooterView` | 对象 | 只读 | 显示类名与 frame |
| `separatorEffect` | 对象 | 只读 | |

### 2.4 UICollectionView

| key | 类型 | 读写 | 价值 |
|---|---|---|---|
| `allowsSelection` | bool | 读/写 | |
| `allowsMultipleSelection` | bool | 读/写 | 多选失效的高频原因 |
| `allowsSelectionDuringEditing` | bool | 读/写 | |
| `allowsMultipleSelectionDuringEditing` | bool | 读/写 | |
| `isPrefetchingEnabled` | bool | 读/写 | iOS 10+，预取导致的时序问题 |
| `dragInteractionEnabled` | bool | 读/写 | iOS 11+ |

### 2.5 UITableViewCell

| key | 类型 | 读写 | 价值 |
|---|---|---|---|
| `isSelected` / `isHighlighted` / `isEditing` | bool | 读/写 | 自定义 cell 状态错乱时直接翻状态 |
| `accessoryView` / `editingAccessoryView` | 对象 | 只读 | |
| `backgroundView` / `selectedBackgroundView` | 对象 | 只读 | 选中态颜色不符时看这里 |
| `contentConfiguration` | 对象 | 只读 | iOS 14+，默认内容配置 |

### 2.6 其余小补（按类分组）

| 类 | key | 类型 | 读写 |
|---|---|---|---|
| UILabel | `adjustsFontSizeToFitWidth` | bool | 读/写 |
| UILabel | `allowsDefaultTighteningForTruncation` | bool | 读/写 |
| UILabel | `preferredMaxLayoutWidth` | double | 读/写 |
| UIImageView | `animationDuration` / `animationRepeatCount` | double / int | 读/写 |
| UIImageView | `isAnimating` | bool | 只读 |
| UIImageView | `animationImages` | 数组 | 只读（只显示张数） |
| UIImageView | `preferredSymbolConfiguration` | 对象 | 只读（iOS 13+） |
| UITextField | `leftView` / `rightView` / `inputView` / `inputAccessoryView` | 对象 | 只读（显示类名） |
| UITextView | `isScrollEnabled` | bool | 读/写 |
| UITextView | `textContainerInset` | UIEdgeInsets | 读/写 |
| UITextView | `dataDetectorTypes` | OptionSet | 只读（显示位掩码） |
| UISegmentedControl | `selectedSegmentTintColor` | 颜色 | 读/写（iOS 13+） |
| UIDatePicker | `preferredDatePickerStyle` | 枚举 | 读/写（iOS 13.4+） |
| UIDatePicker | `roundsToMinuteInterval` | bool | 读/写（iOS 15+） |
| UIDatePicker | `locale` / `calendar` / `timeZone` | 对象 | 只读 |
| UIPickerView | `numberOfComponents` | int | 只读 |
| UIPickerView | `showsSelectionIndicator` | bool | 只读（已弃用但仍有值） |
| UISearchBar | `scopeButtonTitles` | 数组 | 只读 |
| UISearchBar | `selectedScopeButtonIndex` | int | 读/写 |
| UINavigationBar | `titleTextAttributes` / `largeTitleTextAttributes` | 字典 | 只读 |
| UINavigationBar | `backIndicatorImage` / `shadowImage` | 对象 | 只读 |
| UINavigationBar | `standardAppearance` | 对象 | 只读 |
| UINavigationBar | `topItem` | 对象 | 只读 |
| UITabBar | `unselectedItemTintColor` | 颜色 | 读/写 |
| UITabBar | `selectedItem` / `items` | 对象 | 只读 |
| UISwitch | `preferredStyle` | 枚举 | 只读（iOS 14+） |
| UIControl | `isTracking` / `isTouchInside` | bool | 只读 |
| UIControl | `showsMenuAsPrimaryAction` / `isContextMenuInteractionEnabled` | bool | 读/写（iOS 14+） |
| UIButton | `configuration` | 对象 | 只读（iOS 15+） |
| UIButton | `menu` | 对象 | 只读（iOS 14+） |

## 3. P1：建议新增的 UIView 子类

| 类 | key | 类型 | 读写 | 价值 |
|---|---|---|---|---|
| **UICollectionViewCell** | `isSelected` / `isHighlighted` / `isEditing` | bool | 读/写 | 与 UITableViewCell 对齐；`reuseIdentifier` 由 `UICollectionReusableView` 条目沿继承链自动带出 |
| | `contentView` | 对象 | 只读 | |
| **UIVisualEffectView** | `effect` | 对象 | 只读 | 显示 `UIBlurEffect` / `style`，毛玻璃不对时先看这里 |
| | `contentView` | 对象 | 只读 | |
| **UIRefreshControl** | `isRefreshing` | bool | 只读 | 「下拉圈一直转」的经典排查点 |
| | `attributedTitle` | 富文本 | 只读 | |
| | `tintColor` | 颜色 | 读/写 | |
| **UITableViewHeaderFooterView** | `reuseIdentifier` | 字符串 | 只读 | 与 cell 的复用标识对照 |
| | `textLabel` / `detailTextLabel` | 对象 | 只读 | 已弃用但仍有值（显示文本） |

## 4. P2：CALayer 子类

| 类 | key | 类型 | 读写 |
|---|---|---|---|
| **CATextLayer** | `string` | 字符串 | 读/写 |
| | `fontSize` | double | 读/写 |
| | `foregroundColor` | 颜色 | 读/写 |
| | `isWrapped` | bool | 读/写 |
| | `alignmentMode` / `truncationMode` | String raw 枚举 | 只读 |
| **CAReplicatorLayer** | `instanceCount` / `instanceDelay` | int / double | 读/写 |
| | `preservesDepth` | bool | 读/写 |
| | `instanceColor` | 颜色 | 读/写 |
| | `instanceTransform` | CATransform3D | 只读 |
| **CATiledLayer** | `tileSize` | CGSize | 读/写 |
| | `levelsOfDetail` / `levelsOfDetailBias` | int | 读/写 |
| **CAEmitterLayer** | `birthRate` / `lifetime` / `velocity` / `scale` / `spin` | double | 读/写 |
| | `seed` | int | 读/写 |
| | `emitterPosition` / `emitterSize` | CGPoint / CGSize | 读/写 |
| | `emitterShape` / `emitterMode` / `renderMode` | String raw 枚举 | 只读 |

## 5. 明确不补

| 项 | 原因 |
|---|---|
| WKWebView / SFSafariViewController | 会引入 WebKit / SafariServices 依赖，且值多是只读 |
| SwiftUI 宿主视图 | 类名以 `_` 开头（`_UIHostingView` 等），被私有类过滤挡掉 |
| UINavigationItem / UIBarButtonItem / UITabBarItem | 不是 UIView |
| UICollectionViewLayout 细节（itemSize / sectionInset / minimumLineSpacing） | 既不是 UIView 也不是 CALayer，要加第三棵树；收益与改动量不匹配 |
| UIWebView / UIAlertView / UIActionSheet | 已废弃 |
| 私有类（`_UITableViewCellSeparatorView` 等） | 同上，且属性名不稳定 |
| 动画编辑 | Layer 段已只读展示 `animationKeys()`，改动会污染业务状态 |

## 6. 落地方式

- **现有类**：把 key 追加进 `views[类名].properties`；要显示枚举名的再加 `overrides.enumType` 与 `enums` 表。
- **新类**：新增一个 `views` 条目即可。引擎按 `NSObject → 子类` 逐级匹配，父类条目（如 `UIControl`、
  `UIScrollView`、`UICollectionReusableView`）会自动出现在新类的面板里，不需要重复声明。
- **iOS 13 部署**：iOS 14 / 15 才有的属性可以直接写。旧系统上 `respondsToGetter` 取不到，整行不显示。
- **只读判断**：`userEditable: false` 只用于「值类型本来能编辑、但属性确实没有 setter」。像 view /
  effect / configuration / 字典 / 数组这类对象，探不到 `ValueKind`，天然只读，不用声明。
- **写回**：引擎写值后会调用 `HierarchyLayoutRefresh.refresh(view)`，frame / inset 这类属性立即反映到布局。

示例（UIScrollView 补三项）：

```json
"UIScrollView": {
  "properties": [
    "contentOffset",
    "contentSize",
    "contentInset",
    "adjustedContentInset",
    "indicatorStyle",
    "..."
  ]
}
```

`adjustedContentInset` 没有 setter：按现有约定仍显式写 `userEditable: false`（如 `isKeyWindow`、
`isAnimating`），省掉引擎在 `kvcWriteKey` 里打印的那行日志；漏写也不会误写成功。
