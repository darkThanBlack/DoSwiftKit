# 图层 segment 内容计划（Layer）

原「几何」段只覆盖 position / anchorPoint / transform，名称和内容都偏窄，现改为 **Layer（图层）**，
以 `view.layer` 为锚点，按「常用 → 诊断」排序。本文记录最终形态与已实现的取舍。

图例：`读/写` 可编辑；`只读` 仅展示。编辑器沿用现有输入控件，不新增 cell。

---

## 1. Segment 结构（已实现）

| 顺序 | Section | 定位 |
|---|---|---|
| 1 | Drawing（绘制） | 圆角、边框、阴影——命中率最高的 layer 属性 |
| 2 | Transform（变换） | 位置 / 锚点 / z 轴 + 2D / 3D 变换 |
| 3 | Animations（动画） | 当前 layer 挂着的 CAAnimation keys，只读 |
| 4 | Diagnostics（诊断） | 4 个渲染参数，很少改，出问题时才看 |

与 Properties 段重叠的一律不放：`alpha` / `backgroundColor` / `isOpaque` / `clipsToBounds`
（= `masksToBounds`）都在 Properties 段编辑。

---

## 2. Drawing

| 行 | 类型 | 读写 | 说明 |
|---|---|---|---|
| `layer.class` | text | 只读 | 暴露 `layerClass` 被子类替换的情况（`AVPlayerLayer` / 业务自定义） |
| `cornerRadius` | double | 读/写 | |
| `cornerCurve` | enum | 读/写 | `circular` / `continuous`（iOS 13） |
| `borderWidth` | double | 读/写 | |
| `borderColor` | color | 读/写 | `CGColor` 转 `UIColor`；为 nil 时不显示该行 |
| `shadowColor` | color | 读/写 | 同上 |
| `shadowOpacity` | double | 读/写 | Float |
| `shadowOffset` | size | 读/写 | 2 格 |
| `shadowRadius` | double | 读/写 | |
| `shadowPath` | text | 只读 | 显示 boundingBox，未设置时 `nil` |

写入后走 `layer.setNeedsDisplay()`，不触发 layout。

---

## 3. Transform

| 行 | 类型 | 读写 | 说明 |
|---|---|---|---|
| `position` | point | 读/写 | 父 layer 坐标系 |
| `anchorPoint` | point | 读/写 | 旋转 / 缩放中心 |
| `zPosition` | double | 读/写 | |
| `transform` | 6 格：a / b / c / d / tx / ty | 读/写 | 写 `view.transform`；行摘要沿用 `a 1  b 0 …` 形式 |
| `transform3D` | 4×4 文本 | 只读 | 16 个可编辑框误操作成本高 |

- `view.transform` 与 `layer.transform` 是同一份矩阵，只保留一处可写；
- 编辑器数值使用 6 位小数格式，避免每次提交都把旋转分量按 2 位小数取整。

---

## 4. Animations

单行只读：`animationKeys` 的返回值直接拼成字符串，空时为 `none`。

```swift
view.layer.animationKeys()  // ["opacity", "position"]
```

限制（已确认）：

- 动画播完（`isRemovedOnCompletion`）就从 keys 里消失，只能看到存活中的动画；
- `UIView.animate` 装的动画可见，但 transform 动画是 additive，`from` 是增量；
- `.repeat` 的 repeatCount 是 `FLT_MAX`，后续若展开详情需要显示成 ∞。

---

## 5. Diagnostics

| 行 | 类型 | 说明 |
|---|---|---|
| `contentsScale` | double | 只读 |
| `contentsGravity` | text | 只读，显示原始值 |
| `shouldRasterize` | bool | 只读 |
| `rasterizationScale` | double | 只读 |

这四项回答的是「为什么糊了 / 为什么变形了」：手写 sublayer 的 `contentsScale` 默认 1.0，
`shouldRasterize` 开了但 `rasterizationScale` 没跟上，都会让渲染发虚。

**不挂徽标**：scale 与屏幕 scale 不一致并不必然是问题（自定义 contents、多 scene、
有意的离屏光栅化都会如此），简单比对会制造假阳性，所以这里只给值。

---

## 6. 明确不做

| 项 | 原因 |
|---|---|
| `masksToBounds` / `opacity` / `backgroundColor` / `isOpaque` | 与 UIView 属性同源，Properties 段已有 |
| `contentsRect` / `contentsCenter` / `contentsFormat` | 极低频 |
| `maskedCorners` | OptionSet，现有编辑器表达不了 |
| `minificationFilter` / `magnificationFilter` / filters | 纹理与合成细节，调试价值低 |
| `isDoubleSided` / `isGeometryFlipped` / `allowsEdgeAntialiasing` | 3D 与模拟器场景 |
| 动画编辑 / 移除 | 只读快照，避免改变业务状态 |

---

## 7. 子类属性（已实现）

`view.layer` 被 `layerClass` 换成子类时，Layer 段在 Drawing 之后插入该子类的 JSON 条目：

- `DoSwiftHierarchyDefine.json` 根下 `views` / `layers` 两棵树，schema 相同；
- 首批条目：`CAShapeLayer`（颜色、线宽、dash、只读 path/fillRule）、`CAGradientLayer`
  （只读 colors/locations，可写 start/endPoint，只读 type）；
- String raw 枚举直接显示原始值、不入 `enums`，且标为只读。

不做的部分：sublayers 列表、`CAEmitterLayer` / `CATextLayer`（文本统一走 `UILabel`）。
