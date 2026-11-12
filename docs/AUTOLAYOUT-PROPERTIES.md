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

| 行 | 类型 | 徽标条件 |
|---|---|---|
| `contentsScale` | double | 与屏幕 scale 不一致 |
| `contentsGravity` | text | 无 |
| `shouldRasterize` | bool | 无 |
| `rasterizationScale` | double | `shouldRasterize == true` 且与屏幕 scale 不一致 |

这四项回答的是「为什么糊了 / 为什么变形了」：手写 sublayer 的 `contentsScale` 默认 1.0，
`shouldRasterize` 开了但 `rasterizationScale` 没跟上，都会让渲染发虚。

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

## 7. 待定

- **Sublayers 列表**：直接子层（类名 + name + bounds）可作为下一节；点击进二级页展示该层属性。
- **layer 属性进 JSON**：与 `types` 同 schema 增加 `layers` 键，覆盖 `layerClass` 被子类替换的场景；
  基础 CALayer 属性继续代码写死。
