# Hierarchy JSON：已补内容与后续候选

现状：`Resources/DoSwiftHierarchyDefine.json` 有 26 个 UIView 子类、2 个 CALayer 子类、
31 张枚举表，合计 281 个属性。本文记录本轮补齐了什么、还剩哪些候选，以及明确不做的部分。
所有 key 都经过运行时 KVC 实测（`HierarchyPropertyGroupTests.testEveryJSONEntryIsKVCReadable`
会把每个条目完整读一遍，读不通就直接失败）。

## 1. 评估口径

| 维度 | 说明 |
|---|---|
| 命中率 | 真实业务页面上经常出现、出问题时常被怀疑的对象 |
| 能读到 | 引擎走 KVC，取不到的 key 整行跳过；高版本属性在低版本自动消失，不会崩 |
| 能写回 | 需同时满足 `userEditable`、可解析 `ValueKind`、真实 setter，缺一即只读 |
| 不重复 | 已在父类条目里声明的 key 不再写进子类，否则同一属性会出现两行 |

## 2. 本轮已补（P0）

### UIScrollView —— 几何三项

| key | 类型 | 读写 |
|---|---|---|
| `contentOffset` / `contentSize` / `contentInset` | CGPoint / CGSize / UIEdgeInsets | 读/写 |
| `adjustedContentInset` | UIEdgeInsets | 只读 |
| `zoomScale` / `scrollIndicatorInsets` / `decelerationRate` | double / insets / double | 读/写 |
| `scrollsToTop` / `bouncesZoom` | bool | 读/写 |
| `isTracking` / `isDragging` / `isDecelerating` / `isZooming` | bool | 只读 |
| `refreshControl` | 对象 | 只读 |

几何三项是排查「内容截断 / 列表没铺满 / 莫名留白」的第一现场；状态位用来看手势和惯性动画是否还在跑。

### 其余类

| 类 | 新增 key |
|---|---|
| UIWindow | `windowLevel`（读/写）、`windowScene`、`canResizeToFitContent` |
| UITableView | `estimatedRowHeight` / `estimatedSectionHeaderHeight` / `estimatedSectionFooterHeight`、`sectionIndexColor` / `sectionIndexBackgroundColor`、`isEditing`、`backgroundView` / `tableHeaderView` / `tableFooterView`、`separatorEffect` |
| UICollectionView | `allowsSelection`、`allowsMultipleSelection`、`allowsSelectionDuringEditing`、`allowsMultipleSelectionDuringEditing`、`isPrefetchingEnabled`、`dragInteractionEnabled` |
| UITableViewCell | `isSelected` / `isHighlighted` / `isEditing`、`accessoryView` / `editingAccessoryView` / `backgroundView` / `selectedBackgroundView`、`contentConfiguration`（iOS 14+） |
| UILabel | `adjustsFontSizeToFitWidth`、`allowsDefaultTighteningForTruncation`、`preferredMaxLayoutWidth` |
| UIImageView | `isAnimating`、`animationDuration`、`animationRepeatCount`、`preferredSymbolConfiguration`（iOS 13+） |
| UITextField | `leftView` / `rightView` / `inputView` / `inputAccessoryView` |
| UITextView | `textContainerInset`、`dataDetectorTypes`（只读） |
| UIDatePicker | `preferredDatePickerStyle`（枚举，13.4+）、`roundsToMinuteInterval`（15+）、`locale` / `calendar` / `timeZone` |
| UIPickerView | `numberOfComponents`、`showsSelectionIndicator` |
| UISegmentedControl | `selectedSegmentTintColor`（13+） |
| UISearchBar | `scopeButtonTitles`、`selectedScopeButtonIndex` |
| UINavigationBar | `backIndicatorImage` / `shadowImage`、`titleTextAttributes` / `largeTitleTextAttributes`、`standardAppearance`、`topItem` |
| UITabBar | `unselectedItemTintColor`、`items` / `selectedItem`、`standardAppearance` |
| UISwitch | `preferredStyle`（枚举，14+，只读） |
| UIControl | `isTracking` / `isTouchInside`（只读）、`showsMenuAsPrimaryAction` / `isContextMenuInteractionEnabled`（14+） |
| UIButton | `configuration`（15+）、`menu`（14+） |

新增枚举表：`UIDatePickerStyle`、`UISwitchStyle`。

## 3. 剩余候选（未做）

| 类 | key | 备注 |
|---|---|---|
| UICollectionViewCell | `isSelected` / `isHighlighted` / `isEditing` | 与 UITableViewCell 对齐；`reuseIdentifier` 会由 `UICollectionReusableView` 条目沿继承链带出 |
| UIVisualEffectView | `effect` / `contentView` | 显示 `UIBlurEffect` 及风格 |
| UITableViewHeaderFooterView | `reuseIdentifier` / `textLabel` / `detailTextLabel` | 后两个已弃用但仍有值 |

## 4. 明确不做

| 项 | 原因 |
|---|---|
| UIRefreshControl | 只有 `isRefreshing` 等少量只读值，收益低 |
| CALayer 子类（CATextLayer / CAReplicatorLayer / CATiledLayer / CAEmitterLayer） | 暂不需要；将来要加时直接进 `layers` 树 |
| UITextView / UISearchBar 的输入特性（`autocapitalizationType`、`keyboardType`、`returnKeyType` 等） | 运行时靠转发实现、类上没有真实方法，KVC 读会抛 `NSUnknownKeyException` 直接崩宿主。见第 5 节 |
| WKWebView / SFSafariViewController | 会引入 WebKit / SafariServices 依赖 |
| SwiftUI 宿主视图 | 类名以下划线开头（`_UIHostingView`），被私有类过滤挡掉 |
| UINavigationItem / UIBarButtonItem / UITabBarItem | 不是 UIView |
| UICollectionViewLayout 细节（itemSize / sectionInset / minimumLineSpacing） | 既不是 UIView 也不是 CALayer，要加第三棵树，收益不匹配 |
| UIWebView / UIAlertView / UIActionSheet | 已废弃 |
| 私有类（`_UITableViewCellSeparatorView` 等） | 属性名不稳定 |
| 动画编辑 | Layer 段已只读展示 `animationKeys()`，改动会污染业务状态 |

## 5. 已知 KVC 边界

- 引擎读值走 `value(forKey:)`，而 `responds(to:)` 对「转发实现」的 selector 也返回 true。
  `UITextView` / `UISearchBar` 的 `UITextInputTraits` 系列就属于这种：消息能发通，KVC 却认为
  没有访问器，于是抛 `NSUnknownKeyException`。这类 key 一律不进 JSON。
- `UITextField` 的同一批 traits 属性可以正常 KVC 读取，所以 `keyboardType` 等只挂在 `UITextField`
  条目上。
- 新增 key 前先跑一遍 `testEveryJSONEntryIsKVCReadable`，它会遍历所有条目做完整读取。

## 6. 落地格式

- **现有类**：key 追加进 `views[类名].properties`；要枚举名的再加 `overrides.enumType` 与 `enums` 表。
- **新类**：新增 `views` 条目即可，引擎按 `NSObject → 子类` 逐级匹配，父类条目自动出现在面板里。
- **iOS 版本**：14+ / 15+ 的属性可以直接写，旧系统上取不到整行不显示。
- **只读**：`userEditable: false` 用于「值类型能编辑、但属性只读或无 setter」，顺带省掉
  `kvcWriteKey` 打印的日志；对象类（view / effect / configuration / 字典 / 数组）探不到
  `ValueKind`，天然只读，不用声明。
- **写回**：引擎写值后调用 `HierarchyLayoutRefresh.refresh(view)`，frame / inset 类属性立即反映到布局。
